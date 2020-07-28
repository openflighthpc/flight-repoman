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

module Repoman
  module Commands
    class Avail < Command
      def run
        Config.search_paths.each do |path|
          repofiles = Dir[path + "/templates/#{distro}/*"].reject do |fn|
            File.directory?(fn)
          end.map do |item|
            item.sub(/^.*\/templates\//, '')
          end.sort
          puts "Available for #{Paint[distro_name, :bright, :green]} in: #{path}\n\n"
          if repofiles.empty?
            puts "  (None)"
          else
            repofiles.each do |f|
              puts "  #{f.split('/').join(': ')}"
            end
          end
          puts ""
        end
      end

      def distro
        @distro ||= begin
                      if args[0]
                        if Config.distros.include?(args[0])
                          args[0]
                        else
                          raise "Unknown distro: #{args[0]}"
                        end
                      else
                        '*'
                      end
                    end
      end

      def distro_name
        @distro_name ||= (args[0] || 'all distros')
      end
    end
  end
end
