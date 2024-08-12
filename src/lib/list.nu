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
    error make -u {
      msg: $"Failed fetching the latest image list from ($nspawnhub_url)"
      help: "If this keeps happening when you have a network connection there might be an error with this program itself, make a bug report"
    }
    return
  }
}
# List local storage machines
export def "main list" [
  --storage-root: path = $MACHINE_STORAGE_PATH # Path where machines are stored
  --machinectl (-m) = true # Use machinectl for operations
] -> table? {  
    let images = (
      if $machinectl { machinectl --output=json list-images | from json } 
      else {
        ls -l $storage_root | select name readonly type created })

    if ($images | length) == 0 {
      error make -u {
        msg: $"Could not find any images"
        help: $"You can fetch new images with the \"pull\" or \"oci pull\" commands"
      }
      return
    }
    $images
}
