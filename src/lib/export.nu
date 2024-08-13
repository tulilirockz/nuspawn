use logger.nu *
use meta.nu NAME

# Export programs from a machine by writing scripts and desktop files for exported apps
export def "main export" [] {
  $"Usage: ($NAME) export <command>"
}

# Generate a script that will run a binary in a machine through nuspawn enter
export def "main export binary" [
  --extra-flags: string # Flags for the exported binary
  --export-path: path = "~/.local/bin" # Path where the binary will be exported to
  --nuspawn-args: string # Arguments that will be passed to nuspawn
  --nuspawn-prefix: string # Any prefix that will run before the nuspawn caller runs (e.g.: bwrap nuspawn) 
  --prefix: string # Any prefix that will run before the command gets ran (e.g.: gamescope steam) 
  --nuspawn-binary: string = "nuspawn" # Path to the nuspawn script (must be executable) (defaults to $PATH)
  machine: string # Machine that the program will be executed on
  binary: string # Binary that will be exported to the host
] {
  mkdir $export_path
  let exported_binary_path = $"($export_path)/($binary | path basename)"
  $"#!/bin/sh
  ($nuspawn_prefix) ($nuspawn_binary) enter ($nuspawn_args) ($machine) /bin/sh -c \"($prefix) ($binary) ($extra_flags)\"
  " | save -f $exported_binary_path
  run-external "chmod" "+x" $exported_binary_path
  logger success $"Succesfully exported binary to ($exported_binary_path)"
}

# Export desktop files and data from a program in a machine 
export def "main export app" [] {
  logger error "To be implemented"
}
