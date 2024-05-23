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
---

[![Copr build status](https://copr.fedorainfracloud.org/coprs/tulilirockz/nuspawn/package/nuspawn/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/tulilirockz/nuspawn/package/nuspawn/)

A [Nushell](https://nushell.sh) wrapper over systemd-nspawn and machinectl initially inspired by the the [nspawn](https://github.com/nspawn/nspawn/tree/master) nspawnhub wrapper script meant to make usage easier and more integrated with [nspawn.org](https://nspawn.org/) (nspawnhub)

We aim to make this as self-contained with as few dependencies as possible, using just the [nushell](https://nushell.sh) and few binaries like [machinectl](https://www.freedesktop.org/software/systemd/man/latest/machinectl.html), [gpg](https://www.gnupg.org/) and GNU tar (optionally).

## Usage

### Initializing your first container

```bash
nuspawn remote list # Table of all the available distros

# This should be the minimum necessary to pull your image, from there you can use machinectl.
nuspawn init
machinectl start debian-sid-tar
machinectl login debian-sid-tar

# Advanced usage example: Importing a nspawn configuration to the container and verifiying using the nspawnhub gpg key
nuspawn init debian sid --name "mydebbox" --config=./distrobox-like.nspawn.ini
```

### Composing machines

You can also declare your Nspawn machines in YAML manifests to have them automatically configured by running `nuspawn compose create $MANIFEST_PATH`

```yaml

# Version is required due to future breaking changes, it will not let you use old versions on newer versions, not letting you just break the application
version: '0.5'

# Notice that you can declare multiple machines here!
machines: 
  - name: debox
    image: debian
    tag: sid
    type: raw
    config: null # Configuration file copied from $PWD/$FILE
    nspawnhub_url: null # You can also specify a custom URL for a specific image
    env: # Environment variables for init_commands
      - DEBIAN_FRONTEND=noninteractive
    init_commands: # Will run when creating the container, not when logging in through machinectl login 
      - rm -f /etc/apt/apt.conf.d/docker-gzip-indexes /etc/apt/apt.conf.d/docker-no-languages
      - apt update -y && apt upgrade -y 
      - apt install -y cockpit
    inline_config: | # Will be copied to /etc/systemd/nspawn/$MACHINE.nspawn before anything runs, more info in `systemd.nspawn(5)`
      [Network]
      VirtualEthernet=no
    properties: # Systemd service properties, see `systemd.exec(5)`
      - MemoryMax=2G
```

More examples in the `example/` directory.

### Config

You can configure your machines through the `config` subcommands, by `edit`ing, `apply`ing, or `remove`ing nspawn configurations

```bash
nuspawn init debian sid --name debox # You can also specify --config=(path) to set up a configuration when initializing
nuspawn config list # To check every configuration already applied to images
nuspawn config apply ./example/config/distrobox-like.ini debox # Creates a configuration for the machine after install
nuspawn config edit debox # Will open nano (by default) for editing the machine's configuration file
nuspawn config show debox # Shows every property specified in your configuration in a fancy table
nuspawn config remove debox # Removes any configuration set for `systemd-nspawn@debox.service`
```

### Inspecting images

You can fetch images locally without adding them to the systemd-nspawn machine directory by using `nuspawn fetch`

```bash
nuspawn fetch debian sid # From here you can either extract a tarball, or use mount.ddi to check the image contents

nuspawn fetch --extract --type=tar debian sid .

nuspawn fetch --type=raw debian sid .
systemd-dissect ./debian-sid-raw.raw
```


### Deleting machines

```bash
~/opt/tulilirockz/nuspawn/src> nuspawn remove debox
Do you wish to delete all your local images? [N]:
```

You can also Prune, which will delete every image from your system, including configurations if specified.

```bash
~/opt/tulilirockz/nuspawn/src> nuspawn prune
[nuspawn] THIS COMMAND WILL CLEAR ALL IMAGES IN LOCAL STORAGE, type YES if you agree to delete everything
Do you wish to delete all your local images? [N]:
```

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
    #...
    nuspawn = {
      url = "github:tulilirockz/nuspawn";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    #...
  }
  outputs = {
    #...
    # Install the NuSpawn binary in your NixOS configuration by using inputs.nuspawn.packages.${pkgs.system}.nuspawn in environment.systemPackages
    #...
  }
}
```

### Standalone Installation

You should be able to install this project by using the `install.nu` script on your system. If you want to live dangerously, you can run:

```bash
curl -fsSL "https://raw.githubusercontent.com/tulilirockz/nuspawn/main/install.nu" | nu
```

It is NOT recommended to do that, though!

## Known Issues

### Networking

If you are trying to run your container and cant seem to get networking working, make sure that your configuration doesnt have the VirtualEthernet option enabled, like this:

```ini
[Network]
VirtualEthernet=no
```
