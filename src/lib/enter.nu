use std assert
use machine_manager.nu [machinectl, run_container, privileged_run, machine_exists]
use meta.nu [DEFAULT_MACHINE, DEFAULT_RELEASE, NAME, MACHINE_STORAGE_PATH]

# Enter a machine
#
# Requires your machine to have a recent version of systemd-userdb if you are binding your current user to the machine
export def --env "main enter" [
  --storage-root: path = $MACHINE_STORAGE_PATH # Path where machines are stored
  --set-xdg = true # Set XDG variables by default 
  --machinectl (-m) = false # Use machinectl for operations instead of machinectl
  --boot # Force booting for machine when not using machinectl 
  --shadow = true # Copy your user hashed password from /etc/shadow and put it inside the machine
  --no-bind # Use this if you are having issue with user binding
  --user: string # User that will be binded to the machine
  --hostname: string # Hostname
  --type: string = "tar" # Type of the machine (change this if running into checking errors)
  --vm (-v) # Treat machine as vm -> run with systemd-vmspawn
  machine: string # Name of the machine to be logged into
  ...args: string
] {   
  let user = (if $user != null { $user } else { ($env.USER? | default "root") })
  let hostname = (if $hostname != null { $hostname } else { $"(run-external hostname).($machine)" })

  if not (machine_exists $machine --storage-root=($storage_root) -t "tar") {
    let yesno = (input $"(ansi blue_bold)[($NAME)] Machine does not seem to be initialized, do you want to initialize a default ($DEFAULT_MACHINE) ($DEFAULT_RELEASE) machine? [Y/n]: (ansi reset)")

    match $yesno {
      Y|Yes|yes|y => { }
      _ => { return }
    }
    
    (main 
      init
      --override=true
      --override-config=true
      --machinectl=true
      --name=($machine) 
      $DEFAULT_MACHINE
      $DEFAULT_RELEASE)
    return
  }

  if $vm {
    (
      systemd-vmspawn 
      (if $type == "raw" { "-i" } else { "-D" })
      $"--machine=($MACHINE_STORAGE_PATH)"
      
    )
    return
  }

  if $machinectl {
    try { machinectl -q start $machine e>| ignore }
    machinectl -q shell $"($user)@($machine)" ...($args) e>| ignore # Should be pre-configured by init or compose
    return
  }

  (privileged_run
    "systemd-nspawn"
    "--quiet"
    "--set-credential=firstboot.locale:C.UTF-8"
    "--bind=/run/user"
    "--bind=/dev/dri"
    "--bind=/dev/shm"
    "--bind=/home"
    $"--machine=($machine)"
    $"--setenv=XDG_RUNTIME_DIR=($env.XDG_RUNTIME_DIR? | default "/run/user/1000")"
    $"--setenv=XDG_CONFIG_DIR=($env.XDG_CONFIG_HOME? | default "~/.config")"
    $"--setenv=XDG_DATA_DIR=($env.XDG_DATA_HOME? | default "~/.local/share")"
    $"--setenv=XDG_STATE_DIR=($env.XDG_STATE_HOME? | default "~/.local/state")"
    $"--hostname=($hostname)"
    $"--private-users=(if $no_bind { "no" } else { "pick" })"
    $"--private-users-ownership=auto"
    $"--setenv=PATH=/usr/bin:/usr/sbin:/usr/local/bin"
    $"--setenv=DISPLAY=($env.DISPLAY? | default ":0")"
    $"--setenv=WAYLAND_DISPLAY=($env.WAYLAND_DISPLAY? | default "wayland-0")"
    (if $boot { "--boot" } else { $"--chdir=($env.PWD? | default "/home")" } )
    (if not $no_bind { $"--bind-user=($user)" } else { "--private-users=no" })
    ...($args)
  )
}
