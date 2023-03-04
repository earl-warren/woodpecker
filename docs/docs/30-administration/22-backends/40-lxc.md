# LXC backend

:::danger
The LXC backend will execute the pipelines on containers that could be used to get access to the host by a malicious actor.
:::

It is recommended to use this backend only for private setup where the code and
pipeline can be trusted. You shouldn't use it for a public facing CI where
anyone can submit code or add new repositories.

In order to use this backend, you need to download (or build) the
[binary](https://github.com/woodpecker-ci/woodpecker/releases/latest) of the
agent, configure it and run it on the host machine.

## Configuration

### `WOODPECKER_BACKEND_LXC_NETWORK_READY_HOST`
> Default: wikipedia.org

When a LXC container is created, it needs to wait until it gets network connectivity
before running commands. It does so by running `getent hosts $WOODPECKER_BACKEND_LXC_NETWORK_READY_HOST`.

### Server

Enable connection to the server from the outside of the docker environment by
exposing the port 9000:

```yaml
# docker-compose.yml for the server
version: '3'

services:
  woodpecker-server:
  [...]
    ports:
      - 9000:9000
      [...]
    environment:
      - [...]
```

### Agent

When using the `lxc` backend, the
[plugin-git](https://github.com/woodpecker-ci/plugin-git) binary must be in
your `$PATH` for the default clone step to work. If not, you can still write a
manual clone step.

In addition you will need to install LXC on the host. For instance on Debian GNU/Linux:

```
apt-get install lxc git git-lfs debootstrap lxc-templates
```

#### Systemd

An example `/etc/systemd/system/woodpecker-agent-lxc.service` file:

```ini
[Unit]
Description=LXC Woodpecker agent instance

Requires=docker.service
After=docker.service

[Service]
Type=simple
Environment=WOODPECKER_SERVER=replace_with_your_server_address:9000
Environment=WOODPECKER_AGENT_SECRET=replace_with_your_server_secret
Environment=WOODPECKER_BACKEND=lxc
ExecStart=/bin/woodpecker-agent
Restart=always
RestartSec=10
ExecReload=/bin/kill -HUP $MAINPID
Restart=always
User=root
Group=root

[Install]
WantedBy=multi-user.target
```

#### From the command line

You can use the `.env` file to store environmental variables for configuration.
At the minimum you need the following information:

```ini
# .env for the agent
WOODPECKER_AGENT_SECRET=replace_with_your_server_secret
WOODPECKER_SERVER=replace_with_your_server_address:9000
WOODPECKER_BACKEND=lxc
```
Start the agent from the directory with the `.env` file:

`woodpecker-agent`

## Further configuration

### Specify the template and release to be used for a pipeline step

The `image` entry is used to specify the template and release, that is
used to run the container.


```yaml
# .woodpecker.yml

pipeline:
  build:
    image: debian:bullseye
    commands:
      [...]
```

:::note
`/usr/share/lxc/templates/lxc-download -l` shows the list of available templates and releases.
:::

### Selecting the LXC agent using platform

The LXC agent cannot run pipelines that require the Docker agent.
The `platform` of the LXC agent can be set to `lxc` as follows:

```ini
# .env for the agent

WOODPECKER_FILTER_LABELS=platform=lxc
```

Then, use this `platform` with value `lxc` in the pipeline definition, to
only run on this agent:

```yaml
# .woodpecker.yml

platform: lxc

pipeline:
  [...]
```

All other pipelines can select the Docker agent by specifying the default platform:

```yaml
# .woodpecker.yml

platform: linux/amd64

pipeline:
  [...]
```

### Using labels to filter tasks

You can use the [agent configuration
options](../15-agent-config.md#woodpecker_filter_labels) and the
[pipeline syntax](../../20-usage/20-pipeline-syntax.md#labels) to only run certain
pipelines on certain agents. Example:

Define a `label` `type` with value `lxc` for a particular agent:

```ini
# .env for the agent

WOODPECKER_FILTER_LABELS=type=lxc
```

Then, use this `label` `type` with value `lxc` in the pipeline definition, to
only run on this agent:

```yaml
# .woodpecker.yml

labels:
  type: lxc

pipeline:
  [...]
```