use meta.nu [NAME, NSPAWNHUB_STORAGE_ROOT, MACHINE_STORAGE_PATH, MACHINE_CONFIG_PATH]
use logger.nu *
use std assert
use start.nu ["main start" "main stop"]
use remove.nu ["main remove"]
use machine_manager.nu [CONFIG_EXTENSION, run_container, systemctl]

# Compose Nspawn machines from a compose YAML file
export def "main compose" [] {
  $"Usage: ($NAME) compose <command>..."
}

# Create new machines from compose manifest
export def --env "main compose up" [
  --nspawnhub-url: path = $NSPAWNHUB_STORAGE_ROOT # Fallback NspawnHub URL for images 
  --storage-root: path = $MACHINE_STORAGE_PATH # Storage root for machines
  --config-root: path = $MACHINE_CONFIG_PATH # Configuration path for machines
  --override-config = true # Whether to override an existing machine configuration if it is already configured
  --override # Override existing machines
  --config: string # Fallback configuration for all images
  --user: string = "root" # Default user to operate on machine
  --verify (-v): string = "checksum" # Fallback mode to verify images once pulled 
  manifest: path # Manifest to be used
] {
  let manifest_data = (open $manifest)
  if $manifest_data.version != "0.5" {
    logger error $"This ($NAME) version cannot parse any version other than 0.5."
    return
  }
  try {
    mkdir $config_root
    mkdir $storage_root
  } catch {
    logger error "Failure creating config/storage roots due to permission errors"
    return
  }

  assert ($manifest_data.machines != null)
  for machine in $manifest_data.machines {
    try {
      if (not $override) and (($"($storage_root)/($machine.name)" | path exists) or ($"($storage_root)/($machine.name).raw" | path exists)) {
        logger warning $"[($machine.name)] Machine is already initialized, skipping"
        continue
      }
    } catch {
      logger error $"[($machine.name)] Failure checking if machine has already been initialized"
      continue
    }

    assert ($machine.name != null) "Your machine must have a name"
    
    (main 
      init 
      --nspawnhub-url=($machine.nspawnhub_url? | default $nspawnhub_url) 
      --verify=($machine.verify? | default $verify) 
      --from-url=($machine.from-url?)
      --nspawn=(not $machine.systemd? | default true)
      --name=($machine.name) --config=($machine.config? | default $config) 
      --config-root=($config_root) 
      --storage-root=($storage_root) 
      --override=($override)
      $machine.image? 
      $machine.tag?
    )
    
    let machine_config_path = $"($config_root)/($machine.name).($CONFIG_EXTENSION)"
    if $machine.config? != null {
      main config apply ($machine.config | path expand) $machine.name
    }
    if $machine.inline_config? != null {
      try {
        if ($machine_config_path | path exists) and (not $override_config) {
          logger warning $"[($machine.name)] Configuration for machine already exists"
          continue
        }
      } catch {
        logger error $"[($machine.name)] Failure checking if machine configuration is applied"
        continue
      }
      try {
        $machine.inline_config | save -f $machine_config_path
      } catch {
        logger error $"[($machine.name)] Failure writing configuration to storage due to permission errors."
        continue
      }
    }
    if $machine.init_commands? != null {    
      run_container --nspawn=(not $machine.systemd? | default true) $machine.name $"($machine.init_commands | str join ' ; ')"
    }
    if $machine.properties? != null {
      for property in $machine.properties {
        systemctl 'set-property' $"systemd-nspawn@($machine.name).service" $"($property)"
      }
    }
  }
}

# Delete all images from a compose manifest 
export def "main compose down" [
  --storage-root = $MACHINE_STORAGE_PATH # Path for machine storage
  --config-root = $MACHINE_CONFIG_PATH # Path for nspawn configurations 
  --yes (-y) # Do not warn when deleting machine
  --full (-f) = false # Delete configuration for the machine too
  --type (-t): string = "tar" # Type of the machine to be deleted
  --machinectl (-m) = true # Use machinectl for operations   
  ...manifests: string # Manifests to be used
] {
  for manifest in $manifests {
    (main 
      remove
      --machinectl=$machinectl
      --storage-root=$storage_root
      --config-root=$config_root
      --full=$full
      --type=$type
      --yes=$yes
      ...((open $manifest).machines? | filter { |e| $e.name? != null } | select name).name
    )
  }
}

# Start machines from a compose manifest
export def "main compose start" [
  --restart (-r) # Restart instead of just starting up the machines
  --machinectl (-m) = true # Use machinectl for operations
  --force (-f) # Force stopping machine if using --restart option
  --kill (-k) # Send sigkill to machine if using --restart and --force option
  ...manifests: string # Manifest to be used
] {
  for manifest in $manifests {
    (main 
      start
      --machinectl=$machinectl
      --force=$force
      --kill=$kill
      ...((open $manifest).machines? | filter { |e| $e.name? != null } | select name).name
    )  
  }
}

# Stop machines from a compose manifest
export def "main compose stop" [
  --machinectl (-m) = true # Use machinectl for operations
  --kill (-k) # Send sigkill to systemd-nspawn unit for machine
  ...manifests: string # Manifests to be used
] {
  for manifest in $manifests {
    (main 
      stop
      --machinectl=$machinectl
      --kill=$kill
      ...((open $manifest).machines? | filter { |e| $e.name? != null } | select name).name
    )
  }
}
