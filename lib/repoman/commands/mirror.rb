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

module Repoman
  module Commands
    class Mirror < Command
      def run
        setup_repo
        # Loop through each repository defined in file
        File.read(repoconf).scan(/(?<=name=).*/).each do |repo|
          sync_repo(repo)
          generate_metadata(repo)
        end
        if custom?
          generate_metadata('custom')
        end
        local_conf
      end

      def distro
        @distro ||= args[0]
      end

      def reporoot
        @reporoot ||= args[1]
      end

      def repoconf
        @repoconf ||= File.join(reporoot, 'mirror.conf')
      end

      def config_url
        @config_url ||= args[2]
      end

      def repos
        @repos ||= args[3..-1]
      end

      def handler
        @handler ||= RepoHandler.new(distro)
      end

      def configuring?
        options.no_conf.nil?
      end

      def mirroring?
        options.no_mirror.nil?
      end

      def generating_metadata?
        options.no_meta.nil?
      end

      def custom?
        !!options.custom
      end

      def setup_repo
        if configuring?
          # Create reporoot if it doesn't exist
          FileUtils.mkdir_p(reporoot)

          # Create repository directory
          if custom?
            customrepo = reporoot + '/custom'
            FileUtils.mkdir_p(customrepo)
          end

          # Create top of mirror.conf file with general config
          File.write(repoconf, '
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

')
          # Add all additional repo data to file
          repos.each do |r|
            sourcefile = handler.find(r)
            File.write(
              repoconf,
              File.read(sourcefile),
              File.size(repoconf),
              mode: 'a'
            )
          end
        else
          if ! File.exists?(repoconf)
            raise "Existing repository config (#{repoconf}) does not exist"
          end
        end
      end

      def sync_repo(repo)
        if mirroring?
          puts "Syncing #{repo}"
          repo_path = "#{reporoot}/#{repo.split(/-/).join('/')}/"
          puts "reposync -nm --config #{repoconf} -r #{repo} -p #{repo_path} --norepopath"
          %x(reposync -nm --config #{repoconf} -r #{repo} -p #{repo_path} --norepopath)
          if repo.include?('base')
            puts "Downloading pxeboot files"
            source_url = %x(yum --config #{repoconf} repoinfo #{repo}).scan(/(?<=baseurl : ).*/)[0]
            puts "wget -q -N #{source_url}/images/pxeboot/{initrd.img,vmlinuz} -P #{repo_path}/images/pxeboot/"
            puts "wget -q -N #{source_url}/LiveOS/squashfs.img -P #{repo_path}/LiveOS/"
            %x(wget -q -N #{source_url}/images/pxeboot/{initrd.img,vmlinuz} -P #{repo_path}/images/pxeboot/)
            %x(wget -q -N #{source_url}/LiveOS/squashfs.img -P #{repo_path}/LiveOS/)
          end
        end
      end

      def generate_metadata(repo)
        if generating_metadata?
          repo_path = "#{reporoot}/#{repo.split(/-/).join('/')}/"
          group_data = File.exists?(repo_path + '/comps.xml') ? '-g comps.xml ' : ''
          puts "Generating metadata for #{repo}"
          puts "createrepo #{group_data}#{repo_path}"
          %x(createrepo #{group_data} #{repo_path})
        end
      end

      def local_conf
        repolocal = "#{Config.template_root}/templates/#{handler.distro_path}/local.repo"
        repoarray = File.read(repoconf).split(/\n\n/)[1..-1]
        FileUtils.mkdir_p(File.dirname(repolocal))
        File.write(repolocal, '')
        repoarray.each do |config|
          repopath = config.scan(/(?<=name=).*/)[0].split(/-/).join('/')
          if repopath != 'custom'
            File.write(
              repolocal,
              config.gsub(/baseurl=.*/, "baseurl=#{config_url}/#{repopath}"),
              File.size(repolocal),
              mode: 'a'
            )
            File.write(
              repolocal,
              "\n\n",
              File.size(repolocal),
              mode: 'a'
            )
          end
        end
        if custom?
          File.write(
            repolocal, "
[custom]
name=custom
baseurl=#{config_url}/custom
description=Custom repository
enabled=1
ski_if_unavailable=1
gpgcheck=0
priority=11

",
            File.size(repolocal),
            mode: 'a'
          )
        end
        STDERR.puts "The local repository config (for clients to use) has been saved to #{repolocal}"
      end
    end
  end
end
