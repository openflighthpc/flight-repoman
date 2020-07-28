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
require_relative 'repolist_reader'

module Repoman
  class RepolistWriter < RepolistReader
    def add(repo)
      raise "invalid repo name: main" if repo.name == 'main'
      @repos << repo
      save
    end

    def remove(name)
      raise "invalid repo name: main" if name == 'main'
      @repos.reject! do |r|
        r.name == name
      end
      save
    end

    private
    def save
      s = ""
      s << @header
      @repos.each do |r|
        s << "[#{r.name}]\n"
        s << "name=#{r.name}\n"
        s << "baseurl=#{r.baseurl}\n"
        s << r.metadata
        s << "\n"
      end
      File.write(fname, s)
    end
  end
end
