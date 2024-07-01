use meta.nu [MACHINE_STORAGE_PATH, MACHINE_CONFIG_PATH]
use logger.nu *
use machine_manager.nu "machinectl rename"

# Rename a machine
export def "main rename" [
  --machinectl (-m) = true # Use machinectl for operations
  --config-root: path = $MACHINE_CONFIG_PATH # Path where machine configurations are stored
  --storage-root: path = $MACHINE_STORAGE_PATH # Path where machines are stored
  --type (-t) = "tar" # Type of the machine that will be renamed
  current: string # Current machine name
  new: string # New machine name
] {

  if $machinectl {
    try {
      machinectl rename $current $new
    } catch {
      logger error $"Failed renaming machine [($current)]"
      return
    }
    logger success "Successfully renamed machine"
    return
  }
  assert ($type == "tar" or $type == "raw" ) "The only valid machine types are tar or raw"
  let extension = if $type == "tar" { "" } else { ".raw" }
  try {
    mv $"($storage_root)/($current)($extension)" $"($storage_root)/($new)($extension)"
  } catch {
    logger error "Failure renaming machine"
    return
  }
  logger success "Successfully renamed machine"
}
