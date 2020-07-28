#==============================================================================
# Copyright (C) 2020-present Alces Flight Ltd.
#
# This file is part of Flight Repository Manager.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Flight Repository Manager is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Flight Repository Manager. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Flight Repository Manager, please visit:
# https://github.com/openflighthpc/flight-repoman
#==============================================================================
require_relative '../command'
require_relative '../repo_handler'
require_relative '../repolist_reader'
require_relative '../repolist_writer'

module Repoman
  module Commands
    class Create < Command
      MIRROR_CONF_HEADER = <<EOF
[main]
cachedir=/var/cache/yum/$basearch/$releasever
keepcache=0
debuglevel=2
logfile=/var/log/yum.log
exactarch=1
obsoletes=1
gpgcheck=1
plugins=1
installonly_limit=5
reposdir=/dev/null

EOF

      def run
        FileUtils.mkdir_p(reporoot)

        update_mirror_conf if syncing?

        repos.map(&:name).each do |repo|
          sync_repo(repo) if syncing?
          generate_metadata(repo) if generating_metadata?
        end

        update_client_conf if configuring?
      end

      def distro
        @distro ||= args[0]
      end

      def reporoot
        @reporoot ||= options.root || Config.repo_root
      end

      def mirrorconf
        @mirrorconf ||= File.join(reporoot, "mirror-#{distro}.conf")
      end

      def client_conf
        @client_conf ||=
          options.file || File.join(
            Config.repolist_root, "local-#{distro}.repo"
          )
      end

      def baseurl
        @baseurl ||= options.url || Config.repo_url
      end

      def repolists
        @repolists ||= args[1..-1]
      end

      def repos
        @repos ||= [].tap do |a|
          repolists.each do |r|
            sourcefile = handler.find(r)
            r = RepolistReader.new(sourcefile)
            a.concat(r.repos)
          end
        end
      end

      def handler
        @handler ||= RepoHandler.new(distro)
      end

      def configuring?
        options.no_config.nil?
      end

      def syncing?
        options.no_sync.nil?
      end

      def generating_metadata?
        options.no_meta.nil?
      end

      def update_mirror_conf
        w = RepolistWriter.new(mirrorconf, MIRROR_CONF_HEADER)
        repos.each do |r|
          if w.include?(r.name)
            raise "mirror already defined: #{r.name}"
          end
          w.add(r)
        end
      end

      def sync_repo(repo)
        puts "Syncing #{repo}"
        repo_path = "#{reporoot}/#{distro}/#{repo}"
        puts " > reposync -nm --config #{mirrorconf} -r #{repo} -p #{repo_path} --norepopath"
        %x(reposync -nm --config #{mirrorconf} -r #{repo} -p #{repo_path} --norepopath)
        if repo.include?('base')
          puts "Downloading pxeboot files"
          source_url = %x(yum --config #{mirrorconf} repoinfo #{repo}).scan(/(?<=baseurl : ).*/)[0]
          puts " > wget -q -N #{source_url}/images/pxeboot/{initrd.img,vmlinuz} -P #{repo_path}/images/pxeboot/"
          %x(wget -q -N #{source_url}/images/pxeboot/{initrd.img,vmlinuz} -P #{repo_path}/images/pxeboot/)
          puts " > wget -q -N #{source_url}/LiveOS/squashfs.img -P #{repo_path}/LiveOS/"
          %x(wget -q -N #{source_url}/LiveOS/squashfs.img -P #{repo_path}/LiveOS/)
        end
      end

      def generate_metadata(repo)
        repo_path = "#{reporoot}/#{distro}/#{repo}"
        if !syncing? && !File.directory?(repo_path)
          raise "unable to generate metadata for unsynced repo: #{repo_path}"
        end
        group_data = File.exists?(File.join(repo_path, 'comps.xml')) ? '-g comps.xml ' : ''
        puts "Generating metadata for #{repo}"
        puts " > createrepo #{group_data}#{repo_path}"
        %x(createrepo #{group_data} #{repo_path})
      end

      def update_client_conf
        w = RepolistWriter.new(client_conf)
        repos.each do |repo|
          next if w.include?(repo.name)
          repo.baseurl = "#{baseurl}/#{distro}/#{repo.name}"
          w.add(repo)
        end
        puts "\nUpdated client repository configuration:\n\n"
        puts "  #{w.fname}"
      end
    end
  end
end
