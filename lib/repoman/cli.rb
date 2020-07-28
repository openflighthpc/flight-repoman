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
      cli_syntax(c, 'FILE DISTRO REPOLIST...')
      c.summary = 'Create a repository config file from available templates'
      c.action Commands, :generate
      c.description = <<EOF
Specify the output FILE to contain the generated repository config.

Input repository files are searched from the DISTRO subdirectory of
all template directories. Possible distros are:

  #{Config.distros.join("\n  ")}

Use the `show` command to list available repository fils.
EOF
    end

    command :custom do |c|
      cli_syntax(c, 'OPERATION DISTRO [NAME]')
      c.summary = "Manage custom repositories"
      c.action Commands, :custom
      c.option '--root DIR', String, "Specify an alternative repo root (default: #{Config.repo_root})"
      c.option '--url URL', String, "Specify an alternative local repo URL base (default: #{Config.repo_url})"
      c.option '--file FILE', String, "Specify an alternative client repository configuration file"
      c.description = <<EOF
Perform an OPERATION on a custom repository, either 'create' or 'remove'.

NAME defaults to 'custom'.

On creation, create a repository skeleton if it doesn't exist and add
the custom repository to the client repository configuration.

On removal, remove the custom repository from the client repository
configuration.
EOF
    end

    command :create do |c|
      cli_syntax(c, 'DISTRO REPOLIST...')
      c.summary = 'Create a mirror of repositories held in a repository list'
      c.action Commands, :create
      c.option '--root DIR', String, "Specify an alternative repo root (default: #{Config.repo_root})"
      c.option '--url URL', String, "Specify an alternative local repo URL base (default: #{Config.repo_url})"
      c.option '--file FILE', String, "Specify an alternative client repository configuration file" 
      c.option '--no-sync', 'Do not update/mirror repository packages'
      c.option '--no-meta', 'Do not create repository metadata'
      c.option '--no-config', 'Do not add to the client repository configuration'
      c.description = <<EOF
Create a mirror of repositories held in one or more specified
REPOLISTs for DISTRO.

Specify the --no-config to perform mirroring, but skip addition of the
repository to the client repository configuration.

Skip the creation of metadata by specifying the --no-meta option.
EOF
    end

    command :remove do |c|
      cli_syntax(c, 'DISTRO REPO...')
      c.summary = 'Remove one or more repository mirrors from the client repository configuration'
      c.action Commands, :remove
      c.option '--file FILE', String, "Specify an alternative client repository configuration file"
      c.description = <<EOF
Remove one or more repository definitions from the client repository configuration.

Note: this operation will not remove any existing mirrored files.
EOF
    end

    command :refresh do |c|
      cli_syntax(c, 'DISTRO REPO...')
      c.summary = 'Refresh one or more repository mirrors'
      c.action Commands, :refresh
      c.option '--root DIR', String, "Specify an alternative repo root (default: #{Config.repo_root})"
      c.option '--no-sync', 'Do not update/mirror repository packages'
      c.option '--no-meta', 'Do not update repository metadata'
      c.description = <<EOF
Refresh one or more specified upstream REPO mirrors for DISTRO.

Perform a package sync but skip the update of metadata by specifying
the --no-meta option.

Perform an update of repository metadata but skip the package sync by
specifying the --no-sync option.
EOF
    end

    command :avail do |c|
      cli_syntax(c, '[DISTRO]')
      c.summary = 'Show available repository files'
      c.action Commands, :avail
      c.description = <<EOF
Show available repository definitions.

Optionally filter by DISTRO.
EOF
    end

    command :list do |c|
      cli_syntax(c, 'DISTRO')
      c.summary = 'List mirrored and custom repositories'
      c.action Commands, :list
      c.option '--root DIR', String, "Specify an alternative repo root (default: #{Config.repo_root})"
      c.option '--file FILE', String, "Specify an alternative client repository configuration file"
      c.description = <<EOF
List repositories that are present for DISTRO.

The list includes all present mirrored and custom repositories and
indicates which repositories are currently present in the client
repository configuration.
EOF
    end
  end
end
