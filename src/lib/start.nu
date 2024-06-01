use logger.nu *
use machine_manager.nu [machinectl, systemctl]

# Start a machine (or its transient service)
export def "main start" [
  --machinectl (-m) = true # Use machinectl for operations
  --kill (-k) # Send sigkill to machine unit before starting
  --force (-f) # Force stopping machine if using --restart option
  ...machines: string # Machines to be started
] {
  for machine in $machines {
    if $force { 
      main stop --kill=$kill --machinectl=$machinectl $machine
    }

    logger info $"[($machine)] Starting"
    if $machinectl {
      try { machinectl start $machine }
    } else {
      try { systemctl start $"systemd-nspawn@($machine)" }
    }
  }
}

# Stop a machine (or its transient service)
export def "main stop" [
  --machinectl (-m) = true # Use machinectl for operations
  --kill (-k) # Send sigkill to systemd-nspawn unit for machine
  ...machines: string # Machines to be started
] {
  let stopcmd = (if $kill { "kill" } else { "stop" })
  for machine in $machines {
    logger info $"[($machine)] Stopping"
    if $machinectl {
      try { machinectl $stopcmd $machine }
      return
    }
    try { systemctl $stopcmd $"systemd-nspawn@($machine)" }
  }
}
