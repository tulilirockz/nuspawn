use meta.nu [NAME, NSPAWNHUB_STORAGE_ROOT, MACHINE_STORAGE_PATH, MACHINE_CONFIG_PATH]
use logger.nu *
use std assert

const CONFIG_EXTENSION = "nspawn"

# Compose Nspawn machines from YAML
export def "main compose" [] {
  $"Usage: ($NAME) compose <command>..."
}

# Create new machines from YAML manifest
export def --env "main compose create" [
  --storage-root: string = $MACHINE_STORAGE_PATH # Storage root for machines
  --config-root: string = $MACHINE_CONFIG_PATH # Configuration path for machines
  --config: string # Fallback configuration for all images
  --user: string = "root" # Default user to operate on machine
  --verify (-v): string = "checksum" # Fallback mode to verify images once pulled 
  --nspawnhub-url: string = $NSPAWNHUB_STORAGE_ROOT # Fallback NspawnHub URL for images 
  manifest: string # Manifest to be used
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
      if (($"($storage_root)/($machine.name)" | path exists) or ($"($storage_root)/($machine.name).raw" | path exists)) {
        logger warning $"[($machine.name)] Machine is already initialized, skipping"
        continue
      }
    } catch {
      logger error $"[($machine.name)] Failure checking if machine has already been initialized"
      continue
    }

    assert ($machine.name != null)
    assert ($machine.image != null)
    assert ($machine.tag != null)
  
    let machine_config_path = $"($config_root)/($machine.name).($CONFIG_EXTENSION)"
    main init --nspawnhub-url=($machine.nspawnhub_url? | default $nspawnhub_url) --verify=($machine.verify? | default $verify) --name=($machine.name) --config=($machine.config? | default $config) --config-root=($config_root) --storage-root=($storage_root) $machine.image $machine.tag
    if $machine.config? != null {
      main config apply ($machine.config | path expand) $machine.name
    }
    if $machine.inline_config? != null {
      try {
        if ($machine_config_path | path exists) {
          logger warning $"[($machine.name)] Configuration for machine already exists"
          continue
        }
      } catch {
        logger error $"[($machine.name)] Failure checking if machine configuration is applied"
        continue
      }
      try {
        $machine.inline_config | save $machine_config_path
      } catch {
        logger error $"[($machine.name)] Failure writing configuration to storage due to permission errors."
        continue
      }
    }
    if $machine.init_commands? != null {
      run-external 'machinectl' 'start' $'($machine.name)'
      sleep 2sec
      run-external 'machinectl' 'shell' $"($user)@($machine.name)" '/usr/bin/env' $"($machine.env? | default "" | str join ' ')" '/bin/sh' '-c' $"($machine.init_commands | str join ' ; ')"
      run-external 'machinectl' 'stop' $'($machine.name)'
    }
    if $machine.properties? != null {
      for property in $machine.properties {
        run-external 'systemctl' 'set-property' $"systemd-nspawn@($machine.name).service" $"($property)"
      }
    }
  }
}

# Delete all images specified in 
export def "main compose remove" [
  --storage-root: string = $MACHINE_STORAGE_PATH # Storage root for machines
  --config-root: string = $MACHINE_CONFIG_PATH # Configuration path for machines
  --delete-all (-a) # Delete all related files (configuration files, etc...)
  --yes (-y) # Delete without confirmation
  manifest: string # Manifest to be used
] {
  let manifest_data = (open $manifest)

  assert ($manifest_data.machines != null)
  for machine in $manifest_data.machines {
    assert ($machine.name != null)
    assert ($machine.type != null)
    logger info $"Deleting ($machine.name)"
    try {
      rm -rfvi $"($config_root)/($machine.name).($CONFIG_EXTENSION)"
    } catch { }
    try {
      rm -rfvi ...(glob $"($storage_root)/($machine.name)*")
    } catch { }
  }
}