use std assert
use machine_manager.nu [machinectl run_container]

# Enter and setup an nspawn container with your current user
# Requires your container to have a recent version of systemd-userdb if you are binding your current user to the machine
export def --env "main enter" [
  --machinectl (-m) # Use machinectl for operations instead of machinectl
  --shadow = true # Copy your user hashed password from /etc/shadow and put it inside the container
  --root-user: string = "root" # User with root privileges in the container
  --environment (-e): list<string> # Test
  --setup-no-bind = false # Sets up the container for usage without binding user
  --no-bind = false # Use this if you are having issue with user binding
  --bind-dirs = "/home:/home" # Comma separated list of directories bound to the container (e.g.: /home/developer:/opt/dev./home/tulili:/tmp/hosthome)
  --user: string # User that will be binded to the container
  machine: string # Name of the machine to be logged into
  ...args: list<string> # Extra arguments to pass to the backend
] {   
  let user = (if $user != null { $user } else { ($env.USER? | default root) })

  if not $machinectl {
    try {
      machinectl stop $machine | ignore
    }
    (systemd-run 
      --uid=0 
      --gid=0 
      -t 
      -q
      --
      'systemd-nspawn'
      '-b'
      '-M'
      $'($machine)' 
      '--bind=/home:/home'
      '--bind=/run/user:/run/user'
      '--set-credential=firstboot.locale:C.UTF-8'
      '--bind=/dev/dri'
      '--bind=/dev/shm'
      $'--setenv=DISPLAY=($env.DISPLAY? | default ":0")'
      $"--setenv=WAYLAND_DISPLAY=($env.WAYLAND_DISPLAY? | default "wayland-1")"
      (if not $no_bind { $"--bind-user=($user)" }) 
      (if not $no_bind {"-U"})
    )
    return
  }
  machinectl shell $"($user)@($machine)" # Should be pre-configured by init or compose
}
