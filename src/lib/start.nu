use logger.nu *
use machine_manager.nu [machinectl, systemctl]

# Start a machine
export def "main start" [
  --machinectl (-m) = false # Use machinectl for operations
  --kill (-k) # Send sigkill to machine unit before starting
  --force (-f) # Force stopping machine
  machine: string # Machines to be started
] {

    if $force { 
      main stop --kill=($kill) --machinectl=($machinectl) $machine
    }

    logger info $"Starting ($machine)"
    try {
      if $machinectl {
        machinectl start $machine
      } else {
        systemctl -q start $"systemd-nspawn@($machine)"
      }
    } catch {
      error make -u {
        msg: $"Failed starting machine ($machine)"
        help: $"Check journalctl -e -u systemd-nspawn@($machine).service for exit status"
      }
    }
    logger info "Machine successfully started"
}

# Stop a machine
export def "main stop" [
  --machinectl (-m) = false # Use machinectl for operations
  --kill (-k) # Send sigkill to systemd-nspawn unit for machine
  machine: string # Machines to be started
] {

  let stopcmd = (if $kill { "kill" } else { "stop" })
    logger info $"Stopping ($machine)" 
    try {
      if $machinectl {
        machinectl $stopcmd $machine 
      } else {
        systemctl $stopcmd $"systemd-nspawn@($machine)"
      }
    } catch {
      error make -u {
        msg: $"Failed stopping machine ($machine)"
        help: $"Check journalctl -u systemd-nspawn@($machine).service for exit status"
      }
    }
    logger info "Machine successfully stopped"
}
