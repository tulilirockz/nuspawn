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
===

A Nushell wrapper over systemd-nspawn and machinectl pull with inspired by the the [nspawn](https://github.com/nspawn/nspawn/tree/master) nspawnhub wrapper script.

We aim to make this as self-contained with as few dependencies as possible, using just the [nushell](https://nushell.sh) and few binaries like [machinectl](https://www.freedesktop.org/software/systemd/man/latest/machinectl.html) and [gpg](https://www.gnupg.org/).

If you are trying to run your container and cant seem to get networking working, make sure that your firewall allows the systemd units under `systemd-nspawn@MACHINE` access to the network.

## Usage

The CLI usage is still a WIP, but for now, it should work just like the nspawn wrapper.
Make sure to check `nuspawn --help` for more up-to-date information about the CLI


- ASCIINEMA HERE

### Managing your machines

### Init

```bash
nuspawn remote list # Table of all the available distros

# This should be the minimum necessary to pull your image, from there you can use machinectl.
nuspawn init 
machinectl start debian-sid-tar
machinectl login debian-sid-tar

# Advanced usage example: Importing a nspawn configuration to the container and verifiying using the nspawnhub gpg key
nuspawn init debian sid --name "mydebbox" --config=./distrobox-like.nspawn --verify=gpg
```

### Managing configurations

## Installing

### Fedora/OpenSUSE/RHEL (RPM)

### Debian/Ubuntu (DEB)

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
