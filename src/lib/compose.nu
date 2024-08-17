use meta.nu [NAME, NSPAWNHUB_STORAGE_ROOT, MACHINE_STORAGE_PATH, MACHINE_CONFIG_PATH]
use logger.nu *
use std assert
use start.nu ["main start" "main stop"]
use setup.nu ["main setup all"]
use remove.nu ["main remove"]
use pull.nu ["main pull"]
use oci.nu ["main oci pull"]
use machine_manager.nu [CONFIG_EXTENSION, run_container, systemctl, machine_exists]
use manifest.nu [get_cached_file, get_machines_from_manifest]

const COMPOSE_VERSION = "0.7"

# Compose machines from a compose manifest
export def "main compose" [] {
  $"Usage: ($NAME) compose <command>..."
}

# Create new machines from a compose manifest
export def --env "main compose up" [
  --nspawnhub-url: path = $NSPAWNHUB_STORAGE_ROOT # Fallback NspawnHub URL for images 
  --config-root: path = $MACHINE_CONFIG_PATH # Path where machine configurations are stored
  --storage-root: path = $MACHINE_STORAGE_PATH # Path where machines are stored
  --machinectl (-m) = true # Use machinectl for operations
  --force (-f) # Override existing machines
  --config (-c): string # Fallback configuration for all parsed images
  --user (-u): string = "root" # Default user to operate on machines
  --verify (-v): string = "checksum" # Fallback mode to verify images once pulled 
  --oci-runtime: string = "docker" # OCI runtime that the oci pull command will use if necessary
  --yes (-y) # Skip any input questions and just confirm them
  --no-setup (-s) = false # Do not do default setup for machines
  ...manifests: string # Manifests to be used
] {
  for manifest in $manifests {
    let manifest_data = (open (get_cached_file $manifest) | from yaml)

    assert ($manifest_data.version == $COMPOSE_VERSION) $"This ($NAME) compose version incompatible with ($COMPOSE_VERSION)" 
    assert ($manifest_data.machines != null) "You must have a machine declared"

    for machine in $manifest_data.machines {
      assert ($machine.name != null) "Your machine must have a name"
      
      try {
        if (not $force) and (($"($storage_root)/($machine.name)" | path exists) or ($"($storage_root)/($machine.name).raw" | path exists)) {
          logger warning $"[($machine.name)] Machine is already initialized, skipping"
          continue
        }
      } catch {
        error make -u {
          msg: "Failed checking if machine already exists or not in storage"
          help: $"Make sure to have access to the ($storage_root) folder"
        }
        continue
      }

      if ($machine.oci? | default false) {
        (main oci pull
          --machinectl=($machinectl)
          --force=($force)
          --extract=true
          --runtime=($oci_runtime)
          $"($machine.image?)($machine.tag?)"
          $machine.name
        )
      } else {
        (main
          pull
          --machinectl=($machinectl)
          --nspawnhub-url=($machine.nspawnhub_url? | default $nspawnhub_url) 
          --verify=($machine.verify? | default $verify) 
          --from-url=($machine.from-url?)
          --config-root=($config_root) 
          --storage-root=($storage_root)
          --force=($force)
          --yes=($yes)
          $machine.name 
          $machine.image? 
          $machine.tag?
        )
      }
            
      
      if (not ($machine.no_setup? | default false)) or (not $no_setup) {
        logger info "Setting up machine"
        try { main setup all --machinectl=($machine.systemd? | default true) $machine.name }
      }
      
      let machine_config_path = $"($config_root)/($machine.name).($CONFIG_EXTENSION)"
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
          logger warning $"[($machine.name)] Failure checking if machine configuration is applied"
          continue
        }
        logger info $"[($machine.name)] Writing inline configuration"
        let return = ($machine.inline_config | save -f $machine_config_path | complete)
        if ($return.exit_code != 0) {
          logger warning $"[($machine.name)] Failure writing inline configuration\n($return.stderr)"
          continue 
        }
      }

      if $machine.init_commands? != null {
        logger info $"[($machine.name)] Executing initialization commands"
        (run_container
          --machinectl=($machine.systemd? | default true)
          $machine.name
          ...($machine.init_commands))
      }
      
      if $machine.properties? != null {
        for property in $machine.properties {
          systemctl set-property $"systemd-nspawn@($machine.name).service" $"($property)"
        }
      }
    }
  }
}

# Delete all images from a compose manifest
export def "main compose down" [
  --machinectl (-m) = false # Use machinectl for operations 
  --config-root: path = $MACHINE_CONFIG_PATH # Path where machine configurations are stored
  --storage-root: path = $MACHINE_STORAGE_PATH # Path where machines are stored
  --yes (-y) # Do not warn when deleting machine
  --all (-a) # Delete configuration for the machine too
  --force (-f) # Force deletion/stopping when possible
  --type (-t): string = "tar" # Type of the machine to be deleted
  manifest: string # Manifest to be used
] {
  for machine in (get_machines_from_manifest $manifest) {
    (main
      remove
      --config-root=($config_root)
      --storage-root=($storage_root)
      --yes=($yes)
      --all=($all)
      --force=($force)
      --type=($type)
      --machinectl=($machinectl)
      $machine
    )
  }
}

# Start machines from a compose manifest
export def "main compose start" [
  --machinectl (-m) = false # Use machinectl for operations
  --force (-f) # Force stopping machine
  --kill (-k) # Send sigkill to machine if using --restart and --force option
  manifest: string # Manifests to be used
] {
  for machine in (get_machines_from_manifest $manifest) {
    (main 
      start
      --machinectl=($machinectl)
      --force=($force)
      --kill=($kill)
      $machine
    )
  }
}

# Stop machines from a compose manifest
export def "main compose stop" [
  --machinectl (-m) = true # Use machinectl for operations
  --kill (-k) # Send sigkill to systemd-nspawn unit for machine
  manifest: string # Manifest to be used
] {
  for machine in (get_machines_from_manifest $manifest) {
    (main 
      stop
      --machinectl=($machinectl)
      --kill=($kill)
      $machine
    )
  }
}
