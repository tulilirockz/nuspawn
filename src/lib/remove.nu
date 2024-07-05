use meta.nu [MACHINE_STORAGE_PATH, MACHINE_CONFIG_PATH]
use manifest.nu [get_config_path]
use logger.nu *
use machine_manager.nu [machinectl machine_exists]
use start.nu ["main stop"]
use std assert
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
  assert ($type == "tar" or $type == "raw") "The only valid machine types are tar or raw"
  for machine in $machines {
    let machine_exists = (machine_exists --storage-root=($storage_root) -t $type $machine)

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

    logger warning $"Removing machine [($machine)] (if $all { 'and configurations' })"
    if $machinectl {
      try {
        machinectl remove $machine
      } catch {
        logger error "Could not remove machine from storage"
        return
      }
      logger success "Machine succesfully removed"
      return
    }   
    try { rm -fivr ...(glob $"($storage_root)/($machine)*") } catch {
      logger error "Could not remove machine from storage"
      return
    }
    if $all {
      try { rm -fivr ...(glob $"($config_root)/($machine)*") } catch {
        logger error "Could not remove machine configuration from storage"
        return
      }
    }
    logger success "Machine succesfully removed"
  }
}
