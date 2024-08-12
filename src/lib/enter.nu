use std assert
use machine_manager.nu [machinectl, run_container, privileged_run, machine_exists]
use meta.nu [DEFAULT_MACHINE, DEFAULT_RELEASE, NAME, MACHINE_STORAGE_PATH]
use logger.nu *
use start.nu ["main stop"]

# Enter a machine
#
# Requires your machine to have a recent version of systemd-userdb if you are binding your current user to the machine
export def --env "main enter" [
  --storage-root: path = $MACHINE_STORAGE_PATH # Path where machines are stored
  --no-set-xdg # Set XDG variables by default
  --ro-binds # Set the binds to be read-only
  --ro-overlays # Set the overlays to be read-only
  --extra-bind: string # Extra paths for binding to the container (comma separated list of paths)
  --extra-overlay: string # Extra overlay paths for the container (comma separated list of paths) 
  --extra-env: string # Extra environment variables to pass to the container (comma separated list) 
  --machinectl (-m) = false # Use machinectl for operations instead of machinectl
  --boot # Force booting for machine when not using machinectl 
  --no-user-bind # Use this if you are having issue with user binding
  --no-default-binds # Do not bind any directory or file by default
  --no-default-env # Do not set any environment variables by default
  --user: string # User that will be binded to the machine
  --run-user # Log into the machine as the specified user in user argument
  --hostname: string # Hostname that the machine will get
  --type: string = "tar" # Type of the machine (change this if running into checking errors) can be one of "raw" | "image" or "tar" | "directory"
  --runner: string = "nspawn" # Runner of the machine: nspawn or vmspawn
  --no-kill # Do not kill machine preemptively before running launcher command
  --yes # Do not print any confirmation prompts 
  machine: string # Name of the target to be logged into (either a directory, machine name, or image name)
  ...args: string
] {   
  assert (($runner == "nspawn" or $runner == "vmspawn")) "Runner can only be one of two values: vmspawn or nspawn"
  # $type's default value must be in front due to boolean short curcuit evalutaion
  assert (($type == "tar" or $type == "raw" or $type == "image" or $type == "directory")) "Type can only be one of four values: raw, image, tar or directory"

  let user = (if $user != null { $user } else { ($env.USER? | default "root") })
  # sudo does not work properly if you dont set this in the nspawn runner
  let hostname = (if $hostname != null { $hostname } else { $"(run-external hostname | complete | get stdout | str trim).($machine)" })

  if not (machine_exists $machine --machinectl=true --storage-root=($storage_root) -t "tar") {
    let yesno = if $yes { "Y"} else {(input $"(ansi blue_bold)[($NAME)] Machine does not seem to be initialized, do you want to initialize a default ($DEFAULT_MACHINE) ($DEFAULT_RELEASE) machine? [Y/n]: (ansi reset)")}

    match $yesno {
      Y|Yes|yes|y => { }
      _ => { return }
    }
    
    (main 
      pull
      --override=true
      --machinectl=($machinectl)
      --name=($machine) 
      $DEFAULT_MACHINE
      $DEFAULT_RELEASE)
    return
  }

  if not $no_kill {
    NUSPAWN_LOG=0 main stop --machinectl=($machinectl) $machine
  }

  if $machinectl {
    try { machinectl -q start $machine e>| ignore }
    machinectl --runner=$runner -q shell $"($user)@($machine)" ...($args) e>| ignore # Should be pre-configured by init or compose
    return
  }

  if $runner == "vmspawn" {
    (systemd-vmspawn 
      (if $type == "raw" { $"--image=($MACHINE_STORAGE_PATH)/($machine).raw" } else { $"--directory=($MACHINE_STORAGE_PATH)/($machine)" })
      $"--machine=($machine)"
      $machine
      ...($args))
    return
  }

  # Command declaration must be here because final_args must not be empty or just contain an empty string
  mut final_args: list<string> = [
    "systemd-nspawn"
    "--quiet"
    "--set-credential=firstboot.locale:C.UTF-8"
    "--set-credential=passwd.hashed-password.root:"
    $"--set-credential=passwd.hashed-password.($user):"
    $"--hostname=($hostname)"
    $"--private-users=(if $no_user_bind { "no" } else { "pick" })"
    $"--private-users-ownership=auto"
    "--keep-unit"
    "--resolv-conf=replace-stub"
    (if $boot { "--boot" } else { $"--chdir=($env.PWD? | default "/home")" } )
    (if not $no_user_bind { $"--bind-user=($user)" } else { "--private-users=no" })
  ]

  # These only run when explicit values are set due to the "machine" type (the default thing, without explicit values) interpreting paths in /var/lib/machines. 
  # If someone is setting the type to these explicit ones, they want the path parsing instead of --machine parsing.
  if ($type == "directory") {
    $final_args = ($final_args | append [$"--directory=($machine)"])
  } else if ($type == "image") {
    $final_args = ($final_args | append [$"--image=($machine)"])
  } else if ($type == "tar" or $type == "raw") {
    $final_args = ($final_args | append [$"--machine=($machine)"])
  }

  if ($run_user) {
    $final_args = ($final_args | append [$"--user=($user)"])
  }

  if (not $no_default_env) {
    $final_args = ($final_args | append ([
      $"PATH=/usr/bin:/usr/sbin:/usr/local/bin"
      $"DISPLAY=($env.DISPLAY? | default ":0")"
      $"WAYLAND_DISPLAY=($env.WAYLAND_DISPLAY? | default "wayland-0")"
      $"TERM=xterm-256color"
    ] | each {|e| $"--setenv=($e)"}))

    if (not $no_set_xdg) {
      $final_args = ($final_args | append ([
        $"XDG_RUNTIME_DIR=($env.XDG_RUNTIME_DIR? | default "/run/user/1000")"
        $"XDG_CONFIG_DIR=($env.XDG_CONFIG_HOME? | default "~/.config")"
        $"XDG_DATA_DIR=($env.XDG_DATA_HOME? | default "~/.local/share")"
        $"XDG_STATE_DIR=($env.XDG_STATE_HOME? | default "~/.local/state")"
      ] | each {|e| $"--setenv=($e)"}))
    }
  }

  if (not $no_default_binds) {
    $final_args = ($final_args | append ([
      "/run/user"
      "/dev/dri"
      "/dev/shm"
      "/home"
    ] | each {|e| $"--bind=($e)"}))
  }  

  if ($extra_bind != "" and $extra_bind != null) {
    $final_args = ($final_args | append ($extra_bind | split row "," | each {|e| $"--bind(if $ro_binds {"-ro"} else {""})=($e)"}))
  }
  if ($extra_env != "" and $extra_env != null) {
    $final_args = ($final_args | append ($extra_env | split row "," | each {|e| $"--setenv=($e)"}))
  }
  if ($extra_overlay != "" and $extra_overlay != null) {
    $final_args = ($final_args | append ($extra_overlay | split row "," | each {|e| $"--overlay(if $ro_overlays {"-ro"} else {""})=($e)"}))
  }

  logger debug $"($final_args)"
  privileged_run ...($final_args) ...($args)
}
