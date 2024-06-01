use logger.nu *

# Rename a machine
export def "main rename" [
  --machinectl (-m) = true # Use machinectl for operations
  current: string # Current machine name
  new: string # New machine name
] {
  if $machinectl {

  }
}
