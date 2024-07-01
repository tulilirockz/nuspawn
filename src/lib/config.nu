use meta.nu [NAME, MACHINE_STORAGE_PATH, MACHINE_CONFIG_PATH, CONFIG_EXTENSION]
use machine_manager.nu machinectl
use logger.nu *
export def get_config_path [
  config_root: string, 
  machine_name: string, 
  extension: string = $CONFIG_EXTENSION
] {
  return $"($config_root)/($machine_name).($extension)"
}
# Manage machine configurations
export def "main config" [] {
  $"Usage: ($NAME) config <command>..."
}
# Applies a nspawn configuration file to selected machines
export def "main config apply" [
  --config-root: path = $MACHINE_CONFIG_PATH # Path where machine configurations are stored
  --storage-root: path = $MACHINE_STORAGE_PATH # Path where machines are stored
  --force # Override any existing configuration
  --yes (-y) # Say yes to all input-related questions
  --append # Explicitly append configuration over to config file
  configuration: path # Path for configuration that will be applied to machine
  ...machines: string # Machines whose configurations will be applied
] {
  for machine in $machines {
    let target_config_path = (get_config_path $config_root $machine)
  
    try {
      mkdir ($config_root | path dirname)
    } catch {
      logger error "Failure creating configuration path due to permission errors."
      return
    }
    
    try {
      if (not ($"($storage_root)/($machine)" | path exists) and (not $force) and (not $yes)) {
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
      open $configuration | save -f --append $target_config_path
      return
    }

    if ($target_config_path | path exists) and (not $force) {
      logger error $"Not overriding existing configuration in ($target_config_path)"
      return
    }

    try {
      cp -f $configuration $target_config_path
    } catch {
      logger error "Failure when applying configuration to machine"
      return
    }
    logger success $"[($machine)] Applied configuration to machine"
  }
}
# Modify machine configuration
export def --env "main config edit" [
  --config-root: path = $MACHINE_CONFIG_PATH # Path where machine configurations are stored
  --storage-root: path = $MACHINE_STORAGE_PATH # Path where machines are stored
  --machinectl (-m) = true # Use machinectl for operations
  --force (-f) # Create config even if machine or config does not exist
  machine: string # Name of the machine configuration that will be edited
] {
  let target_config_path = (get_config_path $config_root $machine)
  let editor = ($env.EDITOR? | default "nano")
  
  try { mkdir ($config_root | path dirname) }
  
  try {
    if $machinectl {
      machinectl edit $target_config_path
      return
    }
    run-external $editor $target_config_path
  } catch {
    logger error $"Failure when editing configuration file, check if configuration exists in ($target_config_path)"
    return
  }

  logger success "Changes applied successfully"
}
# Reset configuration for machine
export def "main config remove" [
  --config-root: path = $MACHINE_CONFIG_PATH # Path where machine configurations are stored
  --yes (-y) # Do not confirm deleting the configuration
  ...machines: string # Machines whose configurations will be deleted
] {
  for machine in $machines {
    let target_config_path = (get_config_path $config_root $machine)

    if not ( $target_config_path | path exists) {
      logger error $"[($machine)] Could not find configuration file for machine"
      continue
    }

    if not $yes {
      logger warning $"Selected configuration: ($target_config_path)"
      let yesno = (input $"(ansi blue_bold)Do you really wish to delete the configuration? [y/N]> (ansi reset)")

      match $yesno {
        Y|Yes|yes|y => { }
        _ => { return }
      }   
    }
    
    try {
      rm -rvf $target_config_path 
    } catch {
      logger error $"Failure when deleting configuration ($target_config_path)"
      continue
    }
  }
}
# List all existing configurations
export def "main config list" [  
  --config-root: path = $MACHINE_CONFIG_PATH # Path where machine configurations are stored
  prefix: string = "" # Prefix for machines that will be shown
] {
  try {
    mkdir ($config_root | path dirname)
  } catch {
    logger error "Failure creating configuration path due to permission errors."
    return
  }

  try {
    ls -l $config_root | where {|e| ($e.type == "file") and ($e.name | str ends-with $".($CONFIG_EXTENSION)") and ($e.name | str starts-with $prefix)}
  } catch {
    logger error $"Failed listing configurations due to permission errors"
  }
}
# Show configuration for a machine
export def "main config show" [
  --config-root: path = $MACHINE_CONFIG_PATH # Path where machine configurations are stored
  --machinectl (-m) = true # Use machinectl for operations
  ...machines: string
] {
  for machine in $machines {
    let target_config_path = (get_config_path $config_root $machine)

    try { mkdir ($target_config_path | path dirname) }

    logger info $"[($machine)] Configuration in ($target_config_path)"
    try {
      if $machinectl {
        machinectl cat $machine
        return
      }
      print (open $target_config_path | lines | str trim) 
    } catch {
      logger error "Failure reading configuration due to permission errors."
    }
  }
}
