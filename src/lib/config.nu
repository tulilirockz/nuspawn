use meta.nu [NAME, MACHINE_STORAGE_PATH]
use logger.nu *

const CONFIG_EXTENSION = "nspawn"

def get_config_path [machine_storage: string, machine_name: string, extension: string = $CONFIG_EXTENSION] {
  return $"($machine_storage)/($machine_name).($extension)"
}

# Manage machine configurations
export def "main config" [] {
  $"Usage: ($NAME) config <command>..."
}


# Applies a nspawn configuration file over to the machine storage root in order to be used with machinectl
export def "main config apply" [  
  --machine-storage: string = $MACHINE_STORAGE_PATH # Path where machines are stored
  --override # Override any existing configuration
  configuration_path: string # Path for configuration that will be applied to machine
  machine_name: string # Name of the machine where the configuration will be applied to
] {
  let target_config_path = (get_config_path machine_storage machine_name)

  try {
    if (not ($"($machine_storage)/($machine_name)" | path exists) and (not $override)) {
      let yesno = (input $"(ansi blue_bold)Machine does not exist, do you still with to apply? [y/N]> (ansi reset)")

      match $yesno {
        Y|Yes|yes|y => { }
        _ => { return }
      }   
    }
  } catch {
    logger error "Failure checking if machine exists due to permission errors"
    return
  }
  
  if ($target_config_path | path exists) and (not $override) {
    logger error $"Not overriding existing configuration in ($target_config_path)"
    return
  }

  try {
    cp -f $configuration_path $target_config_path
  } catch {
    logger error "Failure when applying configuration to machine"
    return
  }
}

# Modify machine configuration with $EDITOR
export def --env "main config edit" [
  --machine-storage: string = $MACHINE_STORAGE_PATH # Path where machines are stored
  --no-confirm (-f) # Create config even if machine or config does not exist
  machine_name: string # Name of the machine configuration that will be edited
] {
  let target_config_path = (get_config_path $machine_storage $machine_name)
  let editor = ($env.EDITOR? | default "nano")

  try {
    if (not ($"($machine_storage)/($machine_name)" | path exists) and (not $no_confirm)) {
      let yesno = (input $"(ansi blue_bold)Machine does not exist, do you still with to edit configuration? [y/N]> (ansi reset)")

      match $yesno {
        Y|Yes|yes|y => { }
        _ => { return }
      }   
    }
  } catch {
    logger error "Failure checking if machine exists due to permission errors"
    return
  }

  try {
    run-external $editor $target_config_path
  } catch {
    logger error $"Failure when editing configuration file, check if configuration exists in ($target_config_path)"
    return
  }

  logger success "Changes applied successfully"
}

# Reset configuration for machine
export def "main config remove" [
  --machine-storage: string = $MACHINE_STORAGE_PATH # Path where machines are stored
  --no-confirm (-f) # Do not confirm deleting the configuration
  machine_name: string # Name of the machine configuration that will be edited
] {
  let target_config_path = (get_config_path $machine_storage $machine_name)

  if not $no_confirm {
    logger warning $"Selected configuration: ($target_config_path)"
    let yesno = (input $"(ansi blue_bold)Do you really wish to delete the configuration? [y/N]> (ansi reset)")

    match $yesno {
      Y|Yes|yes|y => { }
      _ => { return }
    }   
  }
  
  try {
    rm -rivf $target_config_path 
  } catch {
    logger error $"Failure when deleting configuration ($target_config_path)"
    return
  }
}

# List all existing configurations
export def "main config list" [  
  --machine-storage: string = $MACHINE_STORAGE_PATH # Path where machines are stored
] {
  try {
    ls -l $machine_storage | where {|e| ($e.type == "file") and ($e.name | str ends-with $".($CONFIG_EXTENSION)")}
  } catch {
    logger error $"Failed listing configurations in ($machine_storage) due to permission errors"
  }
}

# Show configuration for machine
export def "main config show" [
  --machine-storage: string = $MACHINE_STORAGE_PATH # Path where machines are stored
  machine_name: string
] {
  let target_config_path = (get_config_path $machine_storage $machine_name)
  
  try {
    open $target_config_path | lines | str trim | split column "=" Property Value  
  } catch {
    logger error "Failure reading configuration, maybe due to permission errors."
  }
}
