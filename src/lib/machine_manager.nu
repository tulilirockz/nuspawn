export extern journalctl [
  --output: string
  ...args: string
]
export extern systemd-cgls [
  ...args: string
]
export extern systemd-cgtop [
  ...args: string
]
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
  -q
  --set-credential: string
  --bind: string
  --setenv: string
  -b
  -U
  --chdir: string
  --bind-user: string
  --user: string
  --hostname: string
  ...args: string
]
export extern systemd-run [
  --uid: number
  --gid: number
  --pty (-t)
  --quiet (-q)
  ...args: string
]
export extern systemd-vmspawn [
  --image (-i)
  --directory (-d)
  --machine (-m)
  machine: string
  ...args: string
]
export extern "machinectl pull-tar" [url: string, name?: string]
export extern "machinectl pull-raw" [url: string, name?: string]
export extern "machinectl remove" [machine: string]
export extern "machinectl shell" [user_connection: string, ...args: string]
export extern "machinectl read-only" [machine: string, enabled: string]
export extern "machinectl list-images" []
export extern "machinectl show-image" [machine: string]
export extern "machinectl rename" [old: string, new: string]
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
  --stop = true,
  --environment (-e): string = "PATH=/usr/sbin:/usr/bin:/usr/local/bin:/bin" # Spaced environment variables for /usr/bin/env
  --env-binary: path = /usr/bin/env
  --shell-binary: path = /bin/sh
  --timeout-max: int = 10
  machine: string,
  ...args: string
] {
  if $machinectl {
    if $start {    
      mut timeout: int = 0
      while (machinectl --output=json | from json | select machine | find $machine | length) == 0 {
        if $timeout == $timeout_max {
          error make -u {
            msg: "Could not connect to machine, timed out"
            help: "Constant failed attempts may happen when running as root"
          }
          return
        }
        try {
          machinectl -q start $machine
          sleep 1sec
        } catch {
          error make -u {
            msg: $"Failure starting machine ($machine)"
            help: "You can check your journalctl logs to see if something happened"
          }
          return
        }
      }
    }

    machinectl -q shell $"($user)@($machine)" $env_binary $environment $shell_binary '-c' ($args | str join " ; ")
    if $stop {
      try { machinectl -q stop $machine }
    }
  } else {
    (privileged_run
      "systemd-nspawn"
      "-q"
      $"--machine=($machine)"
      $env_binary
      $environment
      $shell_binary 
      '-c' ($args | str join " ; ")
    )
    if $stop {
      try { systemctl stop $"systemd-nspawn@($machine)" }
    }
  }
}

export def privileged_run [
  ...args
] {
  systemd-run --uid=0 --gid=0 -t -q "--" ...($args)
}

export def machine_exists [
  --storage-root: string
  --type (-t): string
  --machinectl = false
  machine: string
] {
  if $machinectl {
    return ((machinectl list-images --output=json | from json | where {|e| $e.name == $machine } | length) != 0)
  }

  return (match $type {
    "tar" => ($"($storage_root)/($machine)" | path exists)
    "raw" => ($"($storage_root)/($machine).($type)" | path exists)
    _ => (($"($storage_root)/($machine)" | path exists) or ($"($storage_root)/($machine).($type)" | path exists))
  })
}
