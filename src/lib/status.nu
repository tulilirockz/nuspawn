use logger.nu *

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
