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
require_relative '../repolist_writer'
require_relative '../repo'

module Repoman
  module Commands
    class Custom < Command
      METADATA = <<EOF
description=Custom repository (%s)
enabled=1
skip_if_unavailable=1
gpgcheck=0
priority=11
EOF

      def run
        customrepo = File.join(reporoot, repo)
        writer = RepolistWriter.new(client_conf)
        if add?
          # add
          if writer.include?(name)
            raise "already exists: #{customrepo}"
          else
            FileUtils.mkdir_p(customrepo)
            generate_metadata(repo)
            writer.add(
              Repo.new(
                name,
                sprintf(METADATA, name),
                "#{baseurl}/#{distro}/#{name}"
              )
            )
          end
        else
          # remove
          if writer.include?(name)
            writer.remove(name)
          else
            raise "doesn't exist: #{name}"
          end
        end
        puts "\nUpdated client repository configuration:\n\n"
        puts "  #{w.fname}"
      end

      private
      def distro
        @distro ||= args[1]
      end

      def client_conf
        @client_conf ||=
          options.file || File.join(
            Config.repolist_root, "local-#{distro}.repo"
          )
      end

      def reporoot
        @reporoot ||= options.root || Config.repo_root
      end

      def baseurl
        @baseurl ||= options.url || Config.repo_url
      end

      def repo
        @repo ||= File.join(distro, name)
      end

      def operation
        @operation ||= if args[0] == 'create' ||
                          args[0] == 'remove'
                         args[0]
                       else
                         raise "unknown operation: #{args[0]}"
                       end
      end

      def add?
        operation == 'create'
      end

      def name
        @name ||= args[2] || 'custom'
      end

      def generate_metadata(repo)
        repo_path = "#{reporoot}/#{repo}"
        group_data = File.exists?(File.join(repo_path, 'comps.xml')) ? '-g comps.xml ' : ''
        if File.directory?(repo_path)
          puts "Generating metadata for #{repo}"
          puts " > createrepo #{group_data}#{repo_path}"
          %x(createrepo #{group_data}#{repo_path})
        else
          puts "Skipping #{repo} (no repository/mirror present)"
        end
      end
    end
  end
end
