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

module Repoman
  module Commands
    class Remove < Command
      def run
        w = RepolistWriter.new(client_conf)
        repos.each do |repo|
          next if !w.include?(repo)
          w.remove(repo)
        end
        puts "\nUpdated client repository configuration:\n\n"
        puts "  #{w.fname}"
      end

      private
      def distro
        @distro ||= args[0]
      end

      def client_conf
        @client_conf ||=
          options.file || File.join(
            Config.template_root, "local-#{distro}.repo"
          )
      end

      def repos
        @repos ||= args[1..-1]
      end
    end
  end
end
