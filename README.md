# Flight Repository Manager

Assist with the configuration of custom and mirror repositories.

## Overview

Flight Repository Manager helps manage the creation of mirrors of
upstream RPM repositories and local custom RPM repositories.

## Installation

Flight Repository Manager requires a recent version of Ruby and `bundler`.

The following will install from source using `git`:

```
git clone https://github.com/alces-flight/flight-repoman.git
cd flight-repoman
bundle install --path=vendor
```

Use the script located at `bin/repoman` to execute the tool.

### Installing with Flight Runway

Flight Runway provides a Ruby environment and command-line helpers for
running openflightHPC tools.  Flight Repository Manager integrates with Flight
Runway to provide an easy way for multiple users of an
HPC environment to use the tool.

To install Flight Runway, see the [Flight Runway installation
docs](https://github.com/openflighthpc/flight-runway#installation).

These instructions assume that `flight-runway` has been installed from
the openflightHPC yum repository and that either [system-wide
integration](https://github.com/openflighthpc/flight-runway#system-wide-integration) has been enabled or the
[`flight-starter`](https://github.com/openflighthpc/flight-starter) tool has been
installed and the environment activated with the `flight start` command.

 * Enable the OpenFlightHPC RPM repository:

    ```
    yum install https://repo.openflighthpc.org/pub/centos/7/openflighthpc-release-latest.noarch.rpm
    ```

 * Rebuild your `yum` cache:

    ```
    yum makecache
    ```

* Install the `flight-repoman` RPM:

    ```
    [root@myhost ~]# yum install flight-repoman
    ```

Flight Repository Manager is now available via the `flight` tool:

```
[root@myhost ~]# flight repoman
  NAME:

    flight repoman

  DESCRIPTION:

    Assist with the configuration of custom and mirror repositories

  COMMANDS:

    avail    Show available repository files
    create   Create a mirror of repositories held in a repository list
    custom   Manage custom repositories
    <snip>
```

## Configuration

Refer to `etc/config.yml.ex` for configuration
parameters. Configuration is optional and sensible defaults are
used.

## Operation

Display the available repolists using the `avail` command.

Use the `create` command to create new mirrors, and the `refresh`
command to periodically sync from upstream.

Use the `custom` command to manage custom repositories.

# Contributing

Fork the project. Make your feature addition or bug fix. Send a pull
request. Bonus points for topic branches.

Read [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

# Copyright and License

Eclipse Public License 2.0, see [LICENSE.txt](LICENSE.txt) for details.

Copyright (C) 2020-present Alces Flight Ltd.

This program and the accompanying materials are made available under
the terms of the Eclipse Public License 2.0 which is available at
[https://www.eclipse.org/legal/epl-2.0](https://www.eclipse.org/legal/epl-2.0),
or alternative license terms made available by Alces Flight Ltd -
please direct inquiries about licensing to
[licensing@alces-flight.com](mailto:licensing@alces-flight.com).

Flight Repository Manager is distributed in the hope that it will be
useful, but WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER
EXPRESS OR IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR
CONDITIONS OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR
A PARTICULAR PURPOSE. See the [Eclipse Public License 2.0](https://opensource.org/licenses/EPL-2.0) for more
details.
