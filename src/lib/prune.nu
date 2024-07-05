use meta.nu [MACHINE_STORAGE_PATH, MACHINE_CONFIG_PATH]
use list.nu ["main list"]
use logger.nu *
# Delete all local images 
#
# WARNING: Destructive operation. This WILL delete everything.
export def "main prune" [
  --config-root: path = $MACHINE_CONFIG_PATH # Path where machine configurations are stored
  --storage-root: path = $MACHINE_STORAGE_PATH # Path where machines are stored
  --clean = true # Remove fetched hidden images
  --machinectl = true # Use machinectl for operations
  --yes (-y) # Do not warn that this will delete everything from local storage
] -> null {
  if not $yes {
    logger warning "THIS COMMAND WILL CLEAR ALL IMAGES IN LOCAL STORAGE, type YES if you agree to delete everything"
    main list --machinectl=($machinectl)
    
    let yesno = (input $"(ansi blue_bold)Do you wish to delete all your local images? [N]: (ansi reset)")

    match $yesno {
      YES => { }
      _ => { return }
    }
  }

  logger warning $"Deleting images and configurations"
  try {
    if $machinectl {
      machinectl --output=json list-images | from json | each { |e| logger info $"Removing ($e.name)" ; machinectl remove $e.name } | ignore
    } else {
      rm -rfv --interactive=(not $yes) ...(glob $"($storage_root)/*") ...(glob $"($config_root)/*")
    }
    if $clean and $machinectl {
      machinectl clean
    }
  } catch {
    logger error "Failure deleting local storage images due to permission errors"
    return
  }
  logger success "Machines successfully pruned from your system"
}
