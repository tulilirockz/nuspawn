use meta.nu [NAME, MACHINE_STORAGE_PATH, MACHINE_CONFIG_PATH, CONFIG_EXTENSION]
use machine_manager.nu machinectl
use logger.nu *
use manifest.nu *
use machine_manager.nu machine_exists
use manifest.nu [get_cached_file, get_config_path]

# Manage machine 
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
  --type: string = "tar" # Type of the machine
  configuration: string # Path for configuration that will be applied to machine
  ...machines: string # Machines whose configurations will be applied
] {
  let configuration = (get_cached_file $configuration)
  for machine in $machines {
    let target_config_path = (get_config_path $config_root $machine)
    
    try {
      if (not (machine_exists $machine -t $type --storage-root=($storage_root)) and (not $force) and (not $yes)) {
        let yesno = (input $"(ansi blue_bold)Machine does not exist, do you still with to apply? [y/N]> (ansi reset)")

        match $yesno {
          Y|Yes|yes|y => { }
          _ => { return }
        }   
      }
    } catch {
      error make -u {
        msg: "Failed checking if machine already exists or not in storage"
        help: $"Make sure to have access to the ($config_root) folder"
      }
      return
    }

    try {
      mkdir ($config_root | path dirname)
    } catch {
      error make -u {
        msg: "Failed creating configuration root folder"
        help: $"Make sure to have access to the ($config_root) parent folder"
      }
      return
    }
    
    if $append {
      open $configuration | save -f --append $target_config_path
      return
    }

    if ($target_config_path | path exists) and (not $force) {
      error make -u {
        msg: "The configuration file already exists"
        help: $"If this was intentional, rerun with the --force argument"
      }
      return
    }

    try {
      cp -f $configuration $target_config_path
    } catch {
      error make -u {
        msg: "Failed applying configuration to machine"
        help: $"Make sure to have access to the ($config_root) folder"
      }
      return
    }
    logger success $"Applied configuration to machine ($machine)"
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
    error make -u {
      msg: "Failed opening configuration file for editing, make sure it exists"
      help: $"Also make sure to have access to the ($config_root) folder"
    }
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
      logger warning $"[($machine)] Could not find configuration file for machine"
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
      logger warning $"Failed deleting configuration file for machine ($config_root)"
      return
    }
  }
}
# List all existing configurations
export def "main config list" [  
  --config-root: path = $MACHINE_CONFIG_PATH # Path where machine configurations are stored
] {
  try {
    ls -l $config_root | where {|e| ($e.type == "file") and ($e.name | str ends-with $".($CONFIG_EXTENSION)")}
  } catch {
    error make -u {
      msg: $"Failed listing configuration files"
      help: $"Make sure to have access to the ($config_root) folder"
    }
    return
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

    logger info $"[($machine)] Configuration in ($target_config_path)"
    try {
      if $machinectl {
        machinectl cat $machine
        return
      }
      print (open $target_config_path | lines | str trim) 
    } catch {
      error make -u {
        msg: $"Failed reading configuration file"
        help: $"Make sure to have access to the ($config_root) folder"
      }
      return
    }
  }
}
