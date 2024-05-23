use logger.nu *
use meta.nu [NSPAWNHUB_KEY_LOCATION, NSPAWNHUB_STORAGE_ROOT, MACHINE_STORAGE_PATH, MACHINE_CONFIG_PATH]
use std assert

# Import tar/raw images to machinectl from nspawnhub or any other registry.
export def --env "main init" [
  --verify (-v): string = "checksum" # The type of verification ran on the images 
  --name (-n): string # Name of the image imported to machinectl
  --config (-c): string # Path for the nspawn config to be copied to /var/lib/machines
  --override (-o) # Overrides the existing machine in storage
  --override-config = true # Overrides the existing configuration for the container
  --type (-t): string = "tar" # Type of machine (Raw or Tarball)
  --nspawnhub-url: string = $NSPAWNHUB_STORAGE_ROOT # URL for Nspawnhub's storage root
  --storage-root: string = $MACHINE_STORAGE_PATH # Local storage path for Nspawn machines 
  --config-root: string = $MACHINE_CONFIG_PATH # Local storage path for Nspawn machines
  --from-url (-u): string # Fetch image from URL instead of NspawnHub
  image?: string = "debian"
  tag?: string = "sid"
] {
  let nspawnhub_gpg_path = $"($env.XDG_DATA_HOME? | default $"($env.HOME)/.local/share")/nuspawn/nspawnhub.gpg"
  let nuspawn_cache = $"($env.XDG_CACHE_HOME? | default $"($env.HOME)/.cache")/nuspawn"

  if ($verify == "gpg") and (not ($nspawnhub_gpg_path | path exists)) {
    logger error "Could not find nspawnhub's GPG keys"
    let yesno = (input $"(ansi blue_bold)Do you wish to fetch them? [y/n]: (ansi reset)")

    match $yesno {
      Y|Yes|yes|y => { }
      _ => { return }
    }
    
    logger info "Fetching Nspawnhub keys..."
    mkdir ($nspawnhub_gpg_path | path dirname)
    mkdir $"($env.XDG_DATA_HOME? | default $"($env.HOME)/.local/share")/gnupg" # prevent gnupg from being annoying
    run-external 'gpg' '--no-default-keyring' $"--keyring=($nspawnhub_gpg_path)" '--fingerprint'
    mkdir $nuspawn_cache
    let tfile = (mktemp -p $nuspawn_cache --suffix .gpg masterkey.nspawn.org.XXXXXXX)
    http get $NSPAWNHUB_KEY_LOCATION | save -f $tfile
    run-external 'gpg' '--no-default-keyring' $"--keyring=($nspawnhub_gpg_path)" '--import' $"($tfile)" 
  }
  
  let full_image_name = $"($nspawnhub_url)/($image)/($tag)/($type)/image.($type).xz"
  mut output_image = $"($image)-($tag)-($type)"
  if $name != null {
    $output_image = $name
  }

  
  try {
    if $from_url == null {
      http head $full_image_name | ignore
    } else {
      http head $from_url | ignore
    }
  } catch {
    logger error "Failure finding remote image, check if image is valid"
    return
  }

  if ((run-external 'machinectl' 'show-image' $output_image | complete | get exit_code) != 1) {
    if not $override {
      logger error "Image is already in storage, exiting."
      run-external 'machinectl' 'show-image' $output_image
      return 
    } 

    logger info 'Deleting existing image'
    run-external 'machinectl' 'remove' $output_image
  }
  
  if $config != null {
    logger info "Applying configuration to machine."
    let nspawn_config = $"($config_root)/($output_image).nspawn"
    try { 
      if not ($output_image | path exists) or $override_config {
        cp $config $nspawn_config
      } else {
        open $config | save $nspawn_config --append
      }
    } catch {
      logger error "Failure when modifiying machine configuration, please run as root"
      return
    }
  }


  try {
    if $from_url != null {
      logger info $"Pulling image from URL ($from_url)"  
      run-external 'machinectl' $"pull-($type)" $"--verify=($verify)" $"($from_url)" $"($output_image)" 
    } else {
      logger info $"Pulling image ($image) tag ($tag)"
      run-external 'machinectl' $"pull-($type)" $"--verify=($verify)" $"($full_image_name)" $"($output_image)" 
    }
  } catch {
    logger error "Failure when fetching image"
    return
  }

  logger info "Removing read-only attribute from image"
  try {
    run-external 'machinectl' 'read-only' $"($output_image)" 'false'
  } catch {
    logger error "Failure setting image as writable"
  }

  logger success "All done! This is your new machine:"
  run-external 'machinectl' 'show-image' $"($output_image)" | lines | str trim
}
