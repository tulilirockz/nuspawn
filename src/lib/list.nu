use logger.nu *
use meta.nu [NSPAWNHUB_STORAGE_ROOT]

# List the current nspawnhub images
export def "main remote list" [
  --nspawnhub-url = $NSPAWNHUB_STORAGE_ROOT # Root URL for NspawnHub's storage
] -> table<Distro, Release>? {
  let NSPAWNHUB_LIST = $"($nspawnhub_url)/list.txt"
  try {
    http get $NSPAWNHUB_LIST
      | lines
      | range 2..
      | split column "|" image tag init
      | reject init
      | each { |e| $e | str trim }
  } catch {
    logger error $"Failed fetching current image information from ($NSPAWNHUB_LIST)"
    return
  }
}

# List local storage images
export def "main list" [
  target: string = "/var/lib/machines" # Machine storage location
] -> table<name, readonly, type, created>? {
  try {
    ls -l $target | select name readonly type created
  } catch {
    logger error $"Failed listing images, your user should have permissions over the ($target) folder. Try running as root"
    return
  }
}
