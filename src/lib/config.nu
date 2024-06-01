use meta.nu [NAME, MACHINE_STORAGE_PATH, MACHINE_CONFIG_PATH]
use logger.nu *

const CONFIG_EXTENSION = "nspawn"

export def get_config_path [config_root: string, machine_name: string, extension: string = $CONFIG_EXTENSION] {
  return $"($config_root)/($machine_name).($extension)"
}

# Manage machine configurations
export def "main config" [] {
  $"Usage: ($NAME) config <command>..."
}

# Applies a nspawn configuration file over to the machine storage root
export def "main config apply" [  
  --config-root: string = $MACHINE_CONFIG_PATH # Path where machines are stored
  --machine-root: string = $MACHINE_STORAGE_PATH # Path where machines are stored
  --override # Override any existing configuration
  --yes (-y) # Say yes to all input-related questions
  --append # Explicitly append configuration over to config file
  configuration_path: string # Path for configuration that will be applied to machine
  machine_name: string # Name of the machine where the configuration will be applied to
] {
  let target_config_path = (get_config_path $config_root $machine_name)
  
  try {
    mkdir ($config_root | path dirname)
  } catch {
    logger error "Failure creating configuration path due to permission errors."
    return
  }
  
  try {
    if (not ($"($machine_root)/($machine_name)" | path exists) and (not $override) and (not $yes)) {
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
  
  if $append {
    open $configuration_path | save -f --append $target_config_path
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
  --config-root: string = $MACHINE_CONFIG_PATH # Path where machines are stored
  --machine-root: string = $MACHINE_STORAGE_PATH # Path where machines are stored
  --force (-f) # Create config even if machine or config does not exist
  machine_name: string # Name of the machine configuration that will be edited
] {
  let target_config_path = (get_config_path $config_root $machine_name)
  let editor = ($env.EDITOR? | default "nano")
  
  try {
    mkdir ($config_root | path dirname)
  } catch {
    logger error "Failure creating configuration path due to permission errors."
    return
  }

  try {
    if (not ($"($machine_root)/($machine_name)" | path exists) and (not $force)) {
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
  --config-root: string = $MACHINE_STORAGE_PATH # Path where machines are stored
  --force (-f) # Do not confirm deleting the configuration
  machine_name: string # Name of the machine configuration that will be edited
] {
  let target_config_path = (get_config_path $config_root $machine_name)

  if not $force {
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
  --config-root: string = $MACHINE_CONFIG_PATH # Path where machines are stored
] {
  try {
    mkdir ($config_root | path dirname)
  } catch {
    logger error "Failure creating configuration path due to permission errors."
    return
  }

  try {
    ls -l $config_root | where {|e| ($e.type == "file") and ($e.name | str ends-with $".($CONFIG_EXTENSION)")}
  } catch {
    logger error $"Failed listing configurations due to permission errors"
  }
}

# Show configuration for machine
export def "main config show" [
  --config_root: string = $MACHINE_CONFIG_PATH # Path where machines are stored
  machine_name: string
] {
  let target_config_path = (get_config_path $config_root $machine_name)

  try {
    mkdir ($target_config_path | path dirname)
  } catch {
    logger error "Failure creating configuration path due to permission errors."
    return
  }
  
  try {
    open $target_config_path | lines | str trim | split column "=" Property Value  
  } catch {
    logger error "Failure reading configuration due to permission errors."
  }
}
