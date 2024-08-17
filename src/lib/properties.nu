# Set systemd properties to a running container
export def "main prop" [
  machine: string # Machine to be used 
  properties: string # Properties to be applied
  ...args: string
] {
  systemctl set-properties $"systemd-nspawn@($machine)" $properties ...($args)
}
