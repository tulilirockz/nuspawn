use logger.nu *
use machine_manager.nu [journalctl, systemd-cgls, systemd-cgtop]

# Get status for all the machines or just a specific one
export def "main status" [
  machine?: string
] {
  if $machine != null {
    let data = (machinectl status $machine --output json | complete | get stdout | from json)
    if ($data | length) == 0 {
      logger warning $"Machine ($machine) is not running"
      return
    }
    return
  }

  let data = (machinectl list --output json | from json)
  if ($data | length) == 0 {
    logger warning "No machine is currently running"
    return
  }
  $data
}

# Get journalctl logs for the machine
export def "main log" [machine: string, ...args: string] {
  journalctl --machine=($machine) ...($args) --output=json | lines | each {|e| $e | from json}
}

# List processes inside the machine
export def "main ps" [machine: string, ...args: string] {
  systemd-cgls $machine ...($args)
}

# List processes through top-like interface 
export def "main top" [machine: string, ...args: string] {
  systemd-cgtop $machine ...($args)
}
