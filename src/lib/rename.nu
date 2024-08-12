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
  assert ($type == "tar" or $type == "raw" ) "The only valid machine types are tar or raw"
  
  if $machinectl {
    try {
      machinectl rename $current $new
    } catch { |err|
      error make -u { msg: $"Failed renaming machine ($current), exited with error: ($err.msg)" }
      return
    }
    return
  } else {
    let extension = if $type == "tar" { "" } else { ".raw" }
    try {
      mv $"($storage_root)/($current)($extension)" $"($storage_root)/($new)($extension)"
    } catch {
      error make -u {
        msg: "Failed renaming machine due to permission errors"
        help: "Try running as a privileged user"
      }
      return
    }
  }
  logger success $"Successfully renamed machine ($current) to ($new)"
}
