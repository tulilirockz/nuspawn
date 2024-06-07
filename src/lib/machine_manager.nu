# This file only exists for preventing accidental spilling of arguments because of dynamic callings to these programs
# Like, imagine a function calls machinectl pull-($type), calling machinectl pull-tar would work, pull-raw, too, but not pull-iso or something like that!

export extern machinectl [
  --verify: string = "no"
  --output: string
  ...args: string
]

export extern systemctl [
  ...args: string
]

export extern systemd-nspawn [
   --machine (-M): string
  ...args: string
]

export extern systemd-run [
  --uid: number
  --gid: number
  --pty (-t)
  --quiet (-q)
  ...args: string
]

export extern "machinectl pull-tar" [url: string, name?: string]
export extern "machinectl pull-raw" [url: string, name?: string]
export extern "machinectl remove" [machine: string]
export extern "machinectl shell" [user_connection: string, ...args: string]
export extern "machinectl read-only" [machine: string, enabled: string]
export extern "machinectl list-images" []
export extern "machinectl show-image" [machine: string]
export extern "machinectl stop" [machine: string]
export extern "systemctl start" [unit: string]
export extern "systemctl stop" [unit: string]
export extern "systemctl kill" [unit: string]
export extern "systemctl enable" [unit: string]
export extern "systemctl disable" [unit: string]
export extern "systemctl set-propery" [unit: string, property: string]

export const CONFIG_EXTENSION = "nspawn"

# Meant to be used as a way to run a single command at a time in a container using machinectl.
export def run_container [
  --user: string = "root",
  --machinectl (-m),
  --start = true,
  --environment (-e): string = "PATH=/usr/sbin:/usr/bin:/usr/local/bin:/bin" # Spaced environment variables for /usr/bin/env
  --env-binary: path = /usr/bin/env
  --shell-binary: path = /bin/sh
  machine: string,
  ...args: string
] {
  if $machinectl {
    if $start {    
      try {
        machinectl -q start $machine
      } catch { 
        logger error $"[($machine)] Failure starting machine"
        return
      }
    }
    sleep 3sec
    machinectl -q shell $"($user)@($machine)" $env_binary $environment $shell_binary '-c' ($args | str join " ; ")
    try { machinectl -q stop $machine }
  } else {
    (privileged_run
      "systemd-nspawn"
      "-M" $machine
      $env_binary
      $environment
      $shell_binary 
      '-c' ($args | str join " ; ")
    )
    try { systemctl stop $"systemd-nspawn@($machine)" }
  }
}

export def privileged_run [
  ...args
] {
  systemd-run --uid=0 --gid=0 -t -q "--" ...($args)
}
