```
888888ba           .d88888b                                           8b
88    `8b          88.    "'                                          `8b
88     88 dP    dP `Y88888b. 88d888b. .d8888b. dP  dP  dP 88d888b.     `8b
88     88 88    88       `8b 88'  `88 88'  `88 88  88  88 88'  `88     .8P
88     88 88.  .88 d8'   .8P 88.  .88 88.  .88 88.88b.88' 88    88    .8P
dP     dP `88888P'  Y88888P  88Y888P' `88888P8 8888P Y8P  dP    dP    8P
                             88
                             dP
```

[![Copr build status](https://copr.fedorainfracloud.org/coprs/tulilirockz/nuspawn/package/nuspawn/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/tulilirockz/nuspawn/package/nuspawn/)
[![License: 3-BSD](https://img.shields.io/github/license/tulilirockz/nuspawn?style=plastic&style=social)](https://github.com/tulilirockz/nuspawn/blob/main/LICENSE)

A [Nushell](https://nushell.sh) wrapper over systemd-nspawn and machinectl initially inspired by the the [nspawn](https://github.com/nspawn/nspawn/tree/master) nspawnhub wrapper script meant to make usage easier and more integrated with [nspawn.org](https://nspawn.org/) (nspawnhub) other registries, and make robust and flexible development environments

## Usage

![Video usage example](./assets/demo.gif)

### Initializing your first machine

```bash
nuspawn remote list # Table of all the available distros on nspawnhub

nuspawn pull --name $NAME $IMAGE $TAG # Pull your machine from 
nuspawn oci pull $NAME:$TAG # You can also pull OCI images from DockerHub or anywhere else to get a machine

nuspawn setup $NAME # (optional) Sets up networking, users and other things in the machine manually if necessary (you should have networking by default)

nuspawn enter $NAME
```

### Status of the machines

You can check machine data through these troubleshooting commands 
```bash
nuspawn status # Which machines are actually running at any point
nuspawn log # Fancy table of the systemd journal in the machine
nuspawn top # top-like TUI with machine processes
nuspawn ps # Lists all processes in the machine + control groups (requires systemd in the machine + --boot flag)
```

### Configuring machines

You can configure your machines through the `config` subcommands, by `edit`ing, `apply`ing, or `remove`ing nspawn configurations

```bash
nuspawn config list # To check every configuration already applied to images
nuspawn config apply ./example/config/distrobox-like.ini debox # Creates a configuration for the machine after install
nuspawn config edit debox # Will open nano (by default) for editing the machine's configuration file
nuspawn config show debox # Shows every property specified in your configuration in a fancy table
nuspawn config remove debox # Removes any configuration set for `systemd-nspawn@debox.service`
```

### Inspecting images

You can fetch images locally without adding them to the systemd-nspawn machine directory by using `nuspawn fetch`

```bash
nuspawn pull --fetch-to=./debian.tar --type tar debian sid .

# From here you can either extract a tarball, or use mount.ddi to check the image contents
tar xvf ./debian.tar -C ./debian
```

### Deleting machines

```bash
$ nuspawn remove debox
Do you wish to delete the selected image "debox"? [y/N]:
```

You can also Prune, which will delete every image from your system, including configurations if specified.

```bash
$ nuspawn remove --prune-all
Do you wish to delete all your local images? [y/N]:
```

### Composing machines

You can also declare your machines in YAML manifests to have them automatically configured by running `nuspawn compose create $MANIFEST_PATH`
They work with all options from the pull command, meaning you can also use oci images as a base

```yaml
# Version is required due to future breaking changes
version: '0.9'

# Notice that you can declare multiple machines here!
machines: 
  - name: debox # Required
    oci: false # If you want to use a docker image instead -> $IMAGE:$TAG, type will not be considered
    image: debian
    tag: sid
    systemd: true # If the distro does not have systemd, we cannot use machinectl to communicate with it, needing to use systemd-nspawn directily
    no_setup: true # If the automatic setup scripts do not work for some reason you can disable them
    type: raw # Ignored if OCI=true ("tar" type enforced)
    config: null # Configuration file copied from /$FILE
    nspawnhub_url: null # You can also specify a custom URL for a specific image
    env: # Environment variables for init_commands
      - DEBIAN_FRONTEND=noninteractive
    init_commands: # Will run when creating the machine, not when logging in through machinectl login 
      - rm -f /etc/apt/apt.conf.d/docker-gzip-indexes /etc/apt/apt.conf.d/docker-no-languages
      - apt update -y && apt upgrade -y
      - apt install -y sudo systemd-userdbd dbus # These packages are required so that mounting users to the machine works when using the --boot mode
    inline_config: | # Will be copied to /etc/systemd/nspawn/$MACHINE.nspawn before anything runs, more info in `systemd.nspawn(5)`
      [Network]
      VirtualEthernet=no
    properties: # Systemd service properties, see `systemd.exec(5)`
      - MemoryMax=2G # You can set a bunch of max properties to the machine, including stuff like RW access to devices
      - DeviceAllow=/dev/fuse rwm # Allows you to use FUSE within the machine (rclone, docker, etc)
```

More examples in the `example/` directory.

## Installing

Most of the packaging is still yet to be done, tracking issue at #3

### Fedora/OpenSUSE/RHEL (RPM)

Available in [my COPR @ `tulilirockz/nuspawn`](https://copr.fedorainfracloud.org/tulilirockz/nuspawn)!

### Debian/Ubuntu (DEB)

TODO!

### Arch Linux (PKGBUILD)

TODO!

### Alpine Linux / Chimera / PostmarketOS (APK)

TODO! (maybe), since like... they dont exactly have systemd in them, right?

### NixOS/Nix (Nix)

#### Nix Profile

```bash
nix profile install github:tulilirockz/nuspawn#
```

#### Flake

```nix
{
  inputs = {
    # ...
    nuspawn = {
      url = "github:tulilirockz/nuspawn";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # ...
  }
  outputs = {
    # ...
    # Install the NuSpawn binary in your NixOS configuration by using inputs.nuspawn.packages.${pkgs.system}.nuspawn in environment.systemPackages
    # ...
  }
}
```

### Standalone Installation

You should be able to install this project by using the `install.nu` script on your system. If you want to live dangerously, you can run:

```bash
curl -fsSL "https://raw.githubusercontent.com/tulilirockz/nuspawn/main/install.nu" | nu
# or
curl -fsSL "https://raw.githubusercontent.com/tulilirockz/nuspawn/main/install.sh" | sh
```

It is NOT recommended to do that, though!

## Known Issues

### Networking

If you are trying to run your machine and cant seem to get networking working, make sure that your configuration doesnt have the VirtualEthernet option enabled, like this:

```ini
[Network]
VirtualEthernet=no
```

### Others

Any other weird behaviour you encounter may have been explained in the manpages. (TODO)
The machines really have some weird requirements (e.g.: having systemd-userdbd in order to bound users to get to the machine user database) around systemd to make things work.
