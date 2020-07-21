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
require_relative 'commands'
require_relative 'version'

require 'tty/reader'
require 'commander'
require_relative 'patches/highline-ruby_27_compat'

module Repoman
  module CLI
    PROGRAM_NAME = ENV.fetch('FLIGHT_PROGRAM_NAME','repoman')

    extend Commander::Delegates
    program :application, "Flight Repository Manager"
    program :name, PROGRAM_NAME
    program :version, "v#{Repoman::VERSION}"
    program :description, 'Assist with the configuration of custom and mirror repositories'
    program :help_paging, false
    default_command :help
    silent_trace!

    error_handler do |runner, e|
      case e
      when TTY::Reader::InputInterrupt
        $stderr.puts "\n#{Paint['WARNING', :underline, :yellow]}: Cancelled by user"
        exit(130)
      else
        Commander::Runner::DEFAULT_ERROR_HANDLER.call(runner, e)
      end
    end

    if ENV['TERM'] !~ /^xterm/ && ENV['TERM'] !~ /rxvt/
      Paint.mode = 0
    end

    class << self
      def cli_syntax(command, args_str = nil)
        command.syntax = [
          PROGRAM_NAME,
          command.name,
          args_str
        ].compact.join(' ')
      end
    end

    command :generate do |c|
      cli_syntax(c, 'FILE DISTRO REPO...')
      c.summary = 'Set up client repo config files'
      c.action Commands, :generate
      c.description = <<EOF
Set up client repo config files.
EOF
    end

    command :mirror do |c|
      cli_syntax(c, 'DISTRO REPOROOT CONFIGURL [REPO...]')
      c.summary = 'Clone upstream repo'
      c.action Commands, :mirror
      c.option '--custom', 'Setup a custom repository'
      c.option '--no-mirror', 'Do not update repository packages'
      c.option '--no-meta', 'Do not update repository metadata'
      c.option '--no-conf', 'Do not set up repository but update existing repos in reporoot'
      c.description = <<EOF
Clone upstream repo.
EOF
    end

    command :show do |c|
      cli_syntax(c)
      c.summary = 'Show available repo config files'
      c.action Commands, :show
      c.description = <<EOF
Show available repo config files.
EOF
    end
  end
end
