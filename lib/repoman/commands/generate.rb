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
    class Generate < Command
      def run
        sourcefiles = []
        content = "".tap do |s|
          repos.each do |r|
            f = handler.find(r)
            sourcefiles << f
            s << File.read(f)
            s << "\n"
          end
        end
        FileUtils.mkdir_p(File.dirname(outfile))
        File.write(outfile, content)
        puts "Repository configuration created: #{outfile}\n\nIncorporated:"
        sourcefiles.each do |f|
          puts "  #{f}"
        end
      end

      def distro
        @distro ||= args[1]
      end

      def outfile
        @outfile ||= args[0]
      end

      def repos
        @repos ||= args[2..-1]
      end

      def handler
        @handler ||= RepoHandler.new(distro)
      end
    end
  end
end
