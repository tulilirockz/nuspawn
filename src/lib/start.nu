use logger.nu *
use machine_manager.nu [machinectl, systemctl]
# Start a machine
export def "main start" [
  --machinectl (-m) = true # Use machinectl for operations
  --kill (-k) # Send sigkill to machine unit before starting
  --force (-f) # Force stopping machine
  ...machines: string # Machines to be started
] {
  assert (($machines | length) != 0) "A machine should be specified"

  for machine in $machines {
    if $force { 
      main stop --kill=($kill) --machinectl=($machinectl) $machine
    }

    logger info $"[($machine)] Starting"
    if $machinectl {
      try { machinectl -q start $machine }
    } else {
      try { systemctl start $"systemd-nspawn@($machine)" }
    }
  }
}
# Stop a machine
export def "main stop" [
  --machinectl (-m) = true # Use machinectl for operations
  --kill (-k) # Send sigkill to systemd-nspawn unit for machine
  ...machines: string # Machines to be started
] {
  assert (($machines | length) != 0) "A machine should be specified"

  let stopcmd = (if $kill { "kill" } else { "stop" })
  for machine in $machines {
    logger info $"[($machine)] Stopping"
    if $machinectl {
      try { machinectl -q $stopcmd $machine e>| ignore }
      return
    }
    try { systemctl $stopcmd $"systemd-nspawn@($machine)" }
  }
}
