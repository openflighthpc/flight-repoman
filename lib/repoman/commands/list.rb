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
require_relative '../table'

module Repoman
  module Commands
    class List < Command
      def mirrored?(repo)
        mirror_conf_reader.include?(repo)
      end

      def configured?(repo)
        client_conf_reader.include?(repo)
      end

      def run
        repos = [].tap do |a|
          Dir[File.join(reporoot, distro, '*')].each do |d|
            if File.directory?(d)
              a << File.basename(d)
            end
          end
        end
        if $stdout.tty?
          if repos.empty?
            puts "No repositories found in #{reporoot}"
          else
            repo_to_array = method(:repo_to_array)
            Table.emit do |t|
              headers 'Name', 'Repository Type', 'Client configuration'
              repos.each do |n|
                row *repo_to_array.call(n)
              end
            end
            puts "\nClient repository configuration: #{client_conf_file}\n\n"
          end
        else
          puts client_conf_file
          repos.each do |n|
            puts [n, mirrored?(n) ? 'Mirror' : 'Custom', configured?(n)].join("\t")
          end
        end
      end

      private
      def repo_to_array(n)
        [Paint[n, :cyan], mirrored?(n) ? Paint['Mirror', :green] : Paint['Custom', :magenta], configured?(n) ? "\u2705" : "\u274c"]
      end

      def reporoot
        @reporoot ||= options.root || Config.repo_root
      end

      def mirror_conf_reader
        @mirror_conf ||= RepolistReader.new(mirror_conf_file)
      end

      def mirror_conf_file
        @mirror_conf_file ||= File.join(reporoot, "mirror-#{distro}.conf")
      end

      def client_conf_reader
        @client_conf ||= RepolistReader.new(client_conf_file)
      end

      def client_conf_file
        @client_conf_file ||=
          options.file || File.join(
            Config.template_root, "local-#{distro}.repo"
          )
      end

      def distro
        @distro ||= args[0]
      end
    end
  end
end
