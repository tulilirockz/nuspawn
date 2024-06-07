use meta.nu [NSPAWNHUB_STORAGE_ROOT, MACHINE_STORAGE_PATH, MACHINE_CONFIG_PATH, DEFAULT_MACHINE, DEFAULT_RELEASE]
use pull.nu ["main pull"]
use config.nu ["main config", "main config apply"]
use setup.nu ["main setup"]

# Initialize a machine and set it up for usage
export def "main init" [
  --nspawnhub-url: string = $NSPAWNHUB_STORAGE_ROOT # URL for Nspawnhub's storage root
  --config-root: path = $MACHINE_CONFIG_PATH # Path where machine configurations are stored
  --storage-root: path = $MACHINE_STORAGE_PATH # Path where machines are stored
  --verify (-v): string = "checksum" # The type of verification ran on the images ("no", "checksum", "gpg") 
  --name (-n): string # Name of the machine to be called
  --override (-f) # Override the existing machine in storage
  --override-config = true # Override the existing configuration in storage
  --config (-c): path # Configuration to be applied to the machine
  --type (-t): string = "tar" # Type of machine (Raw or Tarball)
  --from-url (-u): string # Fetch image from URL instead of NspawnHub
  --machinectl (-m) = true # Use machinectl for operations
  --tar-extension: string = "tar.xz" # Extension to be used for fetching tarballs (only needed if not using machinectl)
  --yes (-y) # Skip any input questions and just confirm them
  image?: string = DEFAULT_MACHINE
  release?: string = DEFAULT_RELEASE
] {
  let name = if $name != null { $name } else {  $"($image)-($release)-($type)" }

  try {
    (main
      pull
      --nspawnhub-url=($nspawnhub_url)
      --storage-root=($storage_root)
      --config-root=($config_root)
      --verify=($verify)
      --type=($type)
      --from-url=($from_url)
      --machinectl=($machinectl)
      --override=($override)
      --name=($name)
      --yes=($yes)
      --tar-extension=($tar_extension)
      $image 
      $release)

    if $config != null {
      (main
        config
        apply
        --config-root=($config_root)
        --force=($override_config) 
        --yes=($yes)
        $config
        $name)
    }

    sleep 1sec
    (main
      setup
      --machinectl=($machinectl)
      $name)
    (run_container 
      --machinectl=($machinectl)
      $name
      $"echo '($image):($release)' >> /etc/nuspawn/meta.distro.txt") 
  }
}
