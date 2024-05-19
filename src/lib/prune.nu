use meta.nu [MACHINE_STORAGE_PATH]
use logger.nu *

# Delete all local images - WARNING: destructive operation, this WILL delete everything.
export def "main prune" [
  --storage-path = $MACHINE_STORAGE_PATH # Place where all images are located (WARNING: will delete everything there!) 
  --no-warning # Do not warn that this will delete everything from local storage
] -> null {
  if not $no_warning {
    logger warning "THIS COMMAND WILL CLEAR ALL IMAGES IN LOCAL STORAGE, type YES if you agree to delete everything"
    let yesno = (input $"(ansi blue_bold)Do you wish to delete all your local images? [N]: (ansi reset)")

    match $yesno {
      YES => { }
      _ => { return }
    }
  }

  logger warning $"Deleting everything in ($storage_path)"
  try {
    ls -l $storage_path
    rm -r $"($storage_path)/*" $"($storage_path)/.*"
  } catch {
    logger error "Failure when deleting images, try running as root"
    return
  }
}
