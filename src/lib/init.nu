use logger.nu *
use meta.nu [NSPAWNHUB_KEY_LOCATION, NSPAWNHUB_STORAGE_ROOT, MACHINE_STORAGE_PATH, MACHINE_CONFIG_PATH]
use machine_manager.nu [machinectl, run_container]
use std assert
use setup.nu ["main setup"]
use config.nu ["main config apply", "main config"]
use verify.nu [gpg]

# Import tar/raw images to machinectl from nspawnhub or any other registry and set them up for usage.
export def --env "main init" [
  --nspawnhub-url: path = $NSPAWNHUB_STORAGE_ROOT # URL for Nspawnhub's storage root
  --storage-root: path = $MACHINE_STORAGE_PATH # Local storage path for Nspawn machines 
  --config-root: path = $MACHINE_CONFIG_PATH # Local storage path for Nspawn machines
  --verify (-v): string = "checksum" # The type of verification ran on the images ("no", "checksum", "gpg") 
  --name (-n): string # Name of the machine to be called
  --config (-c): path # Path for the nspawn config to be applied
  --override (-o) # Overrides the existing machine in storage
  --override-config = true # Overrides the existing configuration for the container
  --type (-t): string = "tar" # Type of machine (Raw or Tarball)
  --from-url (-u): string # Fetch image from URL instead of NspawnHub
  --pull-only (-p): string # Just pull the image without setting up anything
  --nspawn (-n) # Use nspawn as the backend for operations instead of machinectl (necessary for systemd-less images)
  --yes (-y) # Skip any input questions and just confirm them
  image?: string = "debian"
  tag?: string = "sid"
] {
  let nspawnhub_gpg_path = $"($env.XDG_DATA_HOME? | default $"($env.HOME)/.local/share")/nuspawn/nspawnhub.gpg"
  let nuspawn_cache = $"($env.XDG_CACHE_HOME? | default $"($env.HOME)/.cache")/nuspawn"

  if ($verify == "gpg") and (not ($nspawnhub_gpg_path | path exists)) {
    logger error "Could not find nspawnhub's GPG keys"
    if not $yes {
      let yesno = (input $"(ansi blue_bold)Do you wish to fetch them? [y/n]: (ansi reset)")

      match $yesno {
        Y|Yes|yes|y => { }
        _ => { return }
      }
    }
    
    logger info "Fetching Nspawnhub keys..."
    mkdir ($nspawnhub_gpg_path | path dirname)
    mkdir $"($env.XDG_DATA_HOME? | default $"($env.HOME)/.local/share")/gnupg" # prevent gnupg from being annoying
    gpg --no-default-keyring --keyring=($nspawnhub_gpg_path) --fingerprint

    mkdir $nuspawn_cache
    let tfile = (mktemp -p $nuspawn_cache --suffix .gpg masterkey.nspawn.org.XXXXXXX)
    http get $NSPAWNHUB_KEY_LOCATION | save -f $tfile
    gpg --no-default-keyring --keyring=($nspawnhub_gpg_path) --import $"($tfile)" 
  }
  
  let nspawnhub_image_url = $"($nspawnhub_url)/($image)/($tag)/($type)/image.($type).xz"
  mut output_image = $"($image)-($tag)-($type)"
  if $name != null {
    $output_image = $name
  }
  
  try {
    http head (if $from_url != null { $from_url } else { $nspawnhub_image_url }) | ignore
  } catch {
    logger error "Failure finding remote image, check if image is valid"
    return
  }

  if ((machinectl show-image $output_image | complete | get exit_code) != 1) {
    if not $override {
      logger error "Image is already in storage, exiting."
      machinectl show-image $output_image
      return 
    } 

    logger info 'Deleting existing image'
    try { machinectl stop $output_image }
    try { machinectl remove $output_image }
  }
  
  if $config != null {
    logger info "Applying configuration to machine."
    main config apply -y $config $output_image
  }

  try {
    machinectl $"pull-($type)" $"--verify=($verify)" $"(if $from_url != null { $from_url } else { $nspawnhub_image_url })" $"($output_image)"
  } catch {
    logger error "Failure when fetching image"
    return
  }

  logger info "Removing read-only attribute from image"
  try {
    machinectl read-only $"($output_image)" "false"
  } catch {
    logger error "Failure setting image as writable"
  }

  if $pull_only != null {
    logger success "All done! This is your new machine:"
    machinectl show-image $output_image | lines | str trim
  }

  logger info "Setting up machine"
  main setup --nspawn=$nspawn $output_image
}
