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
require_relative 'config'

module Repoman
  class RepoHandler
    attr_reader :distro

    def initialize(distro)
      @distro = distro
    end

    def distro_path
      @distro_path ||= distro.split(/(\d+)/).join('/')
    end

    def find(file)
      Config.search_paths.each do |path|
        f = "#{path}/templates/#{distro_path}/#{file}"
        return f if File.exist?(f)
      end
      paths = Config.search_paths.map do |p|
        "#{p}/templates/#{distro_path}"
      end.join(', ')
      raise "#{file} does not exist in search paths: #{paths}"
    end
  end
end