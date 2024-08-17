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
  --prune-all # Remove all images from storage
  --clean = true # Remove fetched hidden images
  --yes (-y) # Do not warn when deleting machine
  --all (-a) # Delete configuration for the machine too
  --kill (-k) # Send sigkill to systemd-nspawn unit for machine
  --force (-f) # Force deletion/stopping when possible
  --type (-t): string = "tar" # Type of the machine to be deleted
  --machinectl (-m) = false # Use machinectl for operations 
  machine?: string # Machines to be deleted
] {
  if (not $prune_all) {
    assert ((($machine != null) or ($machine == ""))) "A machine should be specified if not pruning all machines"
  }
  assert ($type == "tar" or $type == "raw") "The only valid machine types are tar or raw"

  if $prune_all {    
    if not $yes {      
      let yesno = (input $"(ansi blue_bold)Do you wish to delete all your local images? [y/N]: (ansi reset)" | str trim | str downcase)

      match $yesno {
        yes | y => { }
        _ => { return }
      }
    }

    logger warning $"Deleting images and configurations"
    try {
      if $machinectl {
        machinectl --output=json list-images | from json | select name | get name | machinectl remove ...$in
        machinectl clean
      } else {
        rm -rfv --interactive=(not $yes) ...(glob $"($storage_root)/*") ...(glob $"($config_root)/*")
      }
    } catch { |err|
      error make -u { 
        msg: $"Could not remove machine from storage, exited with error: ($err.msg)" 
        help: "Try running as a privileged user"
      }
    }
    
    if $clean and $machinectl {
      try { machinectl clean }
    }
    logger success "Machines successfully removed from your system"
    return
  }

  let machine_exists = (
    try {
      machine_exists --machinectl=($machinectl) --storage-root=($storage_root) -t $type $machine
    } catch {
      error make -u {
        msg: "Failed checking if machine already exists or not in storage"
        help: $"Make sure to have access to the ($storage_root) folder"
      }
      return
    })

  if (not $yes) and ($machine_exists) {
    let yesno = (input $"(ansi blue_bold)Do you wish to delete the selected image \"($machine)\"? \(($machine)\) [y/N]: (ansi reset)" | str trim | str downcase)

    match $yesno {
      yes | y => { }
      _ => { return }
    }
  } else if (not $machine_exists) {
    error make -u {
      msg: $"Machine ($machine) does not exist in storage"
      help: "Either you do not have this image, or maybe you didn't setup the storage root properly"
    }
    return
  }

  logger info "Making sure the machine is stopped"
  try {
    NUSPAWN_LOG=0 (main 
      stop
      --kill=($kill)
      --machinectl=($machinectl)
      $machine)
  }

  logger warning $"Removing machine ($machine)(if $all { ' and configurations' }), this can take a while"
  if $machinectl {
    try {
      machinectl remove $machine
    } catch { |err|
      error make -u { msg: $"Could not remove machine from storage, exited with error: ($err.msg)" }
      return
    }
  } else {  
    try { rm -fvr --interactive=(not $yes) ...(glob $"($storage_root)/($machine)*") } catch { |err|
      error make -u { 
        msg: $"Could not remove machine from storage, exited with error: ($err.msg)"
        help: "Try running as a privileged user"
      }
      return
    }
    if $all {
      try { rm -fvr --interactive=(not $yes) ...(glob $"($config_root)/($machine)*") }
    }
  }
  logger success $"Machine ($machine) succesfully removed"
}
