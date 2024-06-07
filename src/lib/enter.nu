use std assert
use machine_manager.nu [machinectl run_container]
use meta.nu [DEFAULT_MACHINE, DEFAULT_RELEASE, NAME]

# Enter and setup an nspawn machine with your current user
#
# Requires your machine to have a recent version of systemd-userdb if you are binding your current user to the machine
export def --env "main enter" [
  --machinectl (-m) = false # Use machinectl for operations instead of machinectl
  --boot # Force booting for machine when not using machinectl 
  --shadow = true # Copy your user hashed password from /etc/shadow and put it inside the machine
  --no-bind # Use this if you are having issue with user binding
  --extra-bind = "/home:/home" # Comma separated list of directories bound to the machine (e.g.: /home/developer:/opt/dev./home/tulili:/tmp/hosthome)
  --exec-user # Use specified user in user flag in non-booted environments
  --user: string # User that will be binded to the machine
  machine: string # Name of the machine to be logged into
] {   
  let user = (if $user != null { $user } else { ($env.USER? | default "root") })

  if ((machinectl show-image $machine | complete | get exit_code) == 1) {
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

  if $machinectl {
    try { machinectl -q start $machine e>| ignore }
    machinectl -q shell $"($user)@($machine)" e>| ignore # Should be pre-configured by init or compose
    return
  }

  (systemd-run 
    --uid=0 
    --gid=0 
    -t 
    -q
    --
    'systemd-nspawn'
    '-q'
    '-M'
    $'($machine)'
    '--set-credential=firstboot.locale:C.UTF-8'
    '--bind=/run/user'
    '--bind=/dev/dri'
    '--bind=/dev/shm'
    '--bind=/home'
    $'--setenv=DISPLAY=($env.DISPLAY? | default ":0")'
    $"--setenv=WAYLAND_DISPLAY=($env.WAYLAND_DISPLAY? | default "wayland-0")"
    (if not $no_bind {"-U"})
    (if not $no_bind { $"--bind-user=($user)" }) 
    (if $boot {"-b"} else { $"--chdir=($env.PWD? | default "/home")" })
    #(if $exec_user { $"--user=($user)" })
  )
}
