use meta.nu [MACHINE_STORAGE_PATH, MACHINE_CONFIG_PATH]
use config.nu [get_config_path]
use logger.nu *
use machine_manager.nu machinectl
use start.nu ["main stop"]

# Delete a machine or image
export def "main remove" [
  --config-root: path = $MACHINE_CONFIG_PATH # Path where machine configurations are stored
  --storage-root: path = $MACHINE_STORAGE_PATH # Path where machines are stored
  --yes (-y) # Do not warn when deleting machine
  --all (-a) # Delete configuration for the machine too
  --kill (-k) # Send sigkill to systemd-nspawn unit for machine
  --force (-f) # Force deletion/stopping when possible
  --type (-t): string = "tar" # Type of the machine to be deleted
  --machinectl (-m) = true # Use machinectl for operations 
  ...machines: string # Machines to be deleted
] -> null {
  for machine in $machines {
    let machine_exists = (
      if $machinectl { ((machinectl show-image $machine | complete | get exit_code)) != 1 }
      else { false }) # TODO: implement this maybe as a separate command

    if (not $yes) and ($machine_exists) {
      let yesno = (input $"(ansi blue_bold)Do you really wish to delete the selected image? \(($machine)\) [y/N]: (ansi reset)")

      match $yesno {
        YES|yes|Yes|Y|y => { }
        _ => { return }
      }
    } else if (not $machine_exists) {
      logger info $"Machine [($machine)] does not exist"
      return
    }

    (main 
      stop
      --kill=($kill)
      --machinectl=($machinectl)
      $machine)

    logger warning $"Removing image (if $all { 'and configurations' })"
    if $machinectl {
      machinectl remove $machine
      return
    }
        
    try { rm -fivr ...(glob $"($storage_root)/($machine)*") }
    if $all {
      try { rm -fivr ...(glob $"($config_root)/($machine)*") }
    }
  }
}
