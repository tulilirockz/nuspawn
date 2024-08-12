# Export programs from a machine by writing scripts and desktop files for exported apps
export def "main export" [] {}

export def "main export bin" [
  --extra-flags: string # Flags for the exported binary
  machine: string
] {
  let script = "
  #!/bin/sh
  nuspawn enter ($machine) --
  
  
  "

}
export def "main export app" [] {}
