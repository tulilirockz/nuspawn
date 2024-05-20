use meta.nu [MACHINE_STORAGE_PATH, MACHINE_CONFIG_PATH]
use logger.nu *

# Delete all local images - WARNING: destructive operation, this WILL delete everything.
export def "main prune" [
  --storage-root = $MACHINE_STORAGE_PATH # Place where all images are located (WARNING: will delete everything there!) 
  --config-root = $MACHINE_CONFIG_PATH # Place where all images are located (WARNING: will delete everything there!) 
  --no-warning # Do not warn that this will delete everything from local storage
] -> null {
  if not $no_warning {
    logger warning "THIS COMMAND WILL CLEAR ALL IMAGES IN LOCAL STORAGE, type YES if you agree to delete everything"
    try {
    ls -a $storage_root
    ls -a $config_root
    } catch {
      logger error "Failure displaying files to be deleted due to permission errors"
      return
    }
    let yesno = (input $"(ansi blue_bold)Do you wish to delete all your local images? [N]: (ansi reset)")

    match $yesno {
      YES => { }
      _ => { return }
    }
  }

  logger warning $"Deleting images and configurations"
  try {
    # I dislike this pattern as much as the next person, but I really dont know how to make this work properly 
    # TODO: Make this better somehow
    print ...(glob $"($storage_root)/*") ...(glob $"($config_root)/*")
  } catch {
    logger error "Failure deleting local storage images due to permission errors"
    return
  }
}
