use meta.nu [MACHINE_STORAGE_PATH, MACHINE_CONFIG_PATH]
use config.nu [get_config_path]
use logger.nu *
use machine_manager.nu machinectl

# Delete a machine or image
export def "main remove" [
  --storage-root = $MACHINE_STORAGE_PATH # Path for machine storage
  --config-root = $MACHINE_CONFIG_PATH # Path for nspawn configurations 
  --yes (-y) # Do not warn when deleting machine
  --full (-f) = false # Delete configuration for the machine too
  --type (-t): string = "tar" # Type of the machine to be deleted
  --machinectl (-m) = true # Use machinectl for operations 
  ...machines: string # Which machine will be deleted
] -> null {
  for machine in $machines {
    if not $yes {
      let yesno = (input $"(ansi blue_bold)Do you really wish to delete the selected image? \(($machine)\) [y/N]: (ansi reset)")

      match $yesno {
        YES|yes|Yes|Y|y => { }
        _ => { return }
      }
    }

    logger warning $"Deleting image and configurations"
    if $machinectl {
      machinectl remove $machine
      return
    }
    
    rm -fivr ...(glob $"($storage_root)/($machine)*")
    if $full {
      rm -fivr ...(glob $"($config_root)/($machine)*") 
    }
  }
}
