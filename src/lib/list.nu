use logger.nu *
use meta.nu [NSPAWNHUB_STORAGE_ROOT, MACHINE_STORAGE_PATH]
use machine_manager.nu machinectl
# List the current nspawnhub images
export def "main remote list" [
  --nspawnhub-url: string = $NSPAWNHUB_STORAGE_ROOT # URL for Nspawnhub's storage root
] -> table<Distro, Release>? {
  let NSPAWNHUB_LIST = $"($nspawnhub_url)/list.txt"
  try {
    http get $NSPAWNHUB_LIST
      | lines
      | range 2..
      | split column "|" image tag init
      | reject init
      | uniq
      | each { |e| $e | str trim }
  } catch {
    logger error $"Failed fetching current image information from ($NSPAWNHUB_LIST)"
  }
}
# List local storage machines
export def "main list" [
  --storage-root: path = $MACHINE_STORAGE_PATH # Path where machines are stored
  --machinectl (-m) = true # Use machinectl for operations
] -> table? {  
  try {
    let images = (
      if $machinectl { machinectl --output=json list-images | from json } 
      else { ls -l $storage_root | select name readonly type created })
    if ($images | length) == 0 {
      logger error "No images found."
      return
    }
    $images
  } catch {
    logger error "Failure listing machines due to permission issues"
  }
}
