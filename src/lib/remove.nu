use meta.nu [MACHINE_STORAGE_PATH, MACHINE_CONFIG_PATH]
use config.nu [get_config_path]
use logger.nu *

# Delete an nspawn image or machine
export def "main remove" [
  --storage-root = $MACHINE_STORAGE_PATH # Path for machine storage
  --config-root = $MACHINE_CONFIG_PATH # Path for nspawn configurations 
  --yes (-y) # Do not warn when deleting machine
  --full (-f) = true # Delete configuration for the machine too
  --type (-t): string = "tar" # Type of the machine to be deleted 
  machine_name: string # Which machine will be deleted
] -> null {
  if not $yes {
    try {
      ls -la $"($storage_root)/($machine_name)*"
    } catch {
      logger error "Failure displaying files to be deleted due to permission errors"
      return
    }
    let yesno = (input $"(ansi blue_bold)Do you wish to delete the selected image? [y/N]: (ansi reset)")

    match $yesno {
      YES|yes|Yes|Y|y => { }
      _ => { return }
    }
  }

  logger warning $"Deleting image and configurations"
  try {
    rm -fivr ...(glob $"($storage_root)/(machine_name)*")
    if $full {
      rm -fivr ...(glob $"($config_root)/($machine_name)*") 
    }
  } catch {
    logger error "Failure deleting local storage image due to permission errors"
    return
  }
}
