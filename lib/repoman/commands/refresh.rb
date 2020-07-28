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
require_relative '../config'
require_relative '../repolist_reader'

module Repoman
  module Commands
    class Refresh < Command
      def run
        if !syncing? && !generating_metadata?
          raise "no operation to perform; not syncing or generating metadata"
        end
        assert_repos_exist
        repos.each do |repo|
          sync_repo(repo) if syncing?
          generate_metadata(repo) if generating_metadata?
        end
      end

      private
      def reporoot
        @reporoot ||= options.root || Config.repo_root
      end

      def mirrorconf
        @mirrorconf ||= File.join(reporoot, "mirror-#{distro}.conf")
      end

      def assert_repos_exist
        w = RepolistReader.new(mirrorconf)
        repos.each do |repo|
          if !File.directory?("#{reporoot}/#{distro}/#{repo}")
            raise "repo directory not found: #{reporoot}/#{distro}/#{repo}"
          end
          if !w.include?(repo) && syncing?
            raise "repo configuration not present in mirror configuration: #{w.fname}"
          end
        end
      end

      def sync_repo(repo)
        puts "Syncing #{repo} for #{distro}"
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
        group_data = File.exists?(File.join(repo_path, 'comps.xml')) ? '-g comps.xml ' : ''
        puts "Generating metadata for #{repo}"
        puts " > createrepo #{group_data}#{repo_path}"
        %x(createrepo #{group_data} #{repo_path})
      end

      def distro
        @distro ||= args[0]
      end

      def repos
        @repos ||= args[1..-1]
      end

      def syncing?
        options.no_sync.nil?
      end

      def generating_metadata?
        options.no_meta.nil?
      end
    end
  end
end
