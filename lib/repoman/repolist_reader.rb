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
require_relative 'repo'

module Repoman
  class RepolistReader
    attr_accessor :repos, :fname

    def initialize(fname, header = "")
      @fname = fname
      @repos = []
      @header = header
      load
    end

    def include?(name)
      @repos.any? do |r|
        r.name == name
      end
    end

    def each(&block)
      @repos.each(&block)
    end

    private
    def load
      name = nil
      metadata = ""
      baseurl = nil
      if File.exists?(fname)
        File.readlines(fname).each do |l|
          if l =~ /^\[(.*)\]/
            @repos << Repo.new(name, metadata, baseurl) unless name.nil?
            name = ($1 == 'main' ? nil : $1)
            metadata = ""
          elsif !name.nil?
            if l =~ /^baseurl=(.*)/
              baseurl = $1
            elsif l !~ /^$/ && l !~ /^name=/
              metadata << l
            end
          end
        end
        @repos << Repo.new(name, metadata, baseurl) unless name.nil?
      end
    end
  end
end
