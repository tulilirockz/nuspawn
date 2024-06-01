export extern machinectl [
  --verify: string = "no"
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
  --nspawn (-n),
  --environment (-e): string = "PATH=/usr/bin:/usr/local/bin:/bin" # Spaced environment variables for /usr/bin/env
  --env-binary: path = /usr/bin/env
  --shell-binary: path = /bin/sh
  machine: string,
  ...args: string
] {
  if not $nspawn {
    machinectl start $machine
    sleep 1sec
    machinectl shell $"($user)@($machine)" $env_binary $environment $shell_binary '-c' ($args | str join " ; ")
  } else {
    (systemd-run 
      --uid=0 
      --gid=0 
      -t 
      -q 
      "--"
      "systemd-nspawn"
      "-M" $machine
      $env_binary 
      $environment 
      $shell_binary 
      '-c' ($args | str join " ; ")
    ) 
  }
  try { machinectl stop $machine | ignore }
}

# Meant to be used as a way to run a single command at a time in a container using nspawn.
export def nspawn_run_container [
  --user: string = "root",
  --environment (-e): string = "PATH=/usr/bin:/usr/local/bin:/bin" # Spaced environment variables for /usr/bin/env
  --env-binary: path = /usr/bin/env
  --shell-binary: path = /bin/sh
  machine: string,
  ...args: string
] {
  
}
