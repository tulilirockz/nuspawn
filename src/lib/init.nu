use logger.nu *
use meta.nu [NSPAWNHUB_KEY_LOCATION, NSPAWNHUB_STORAGE_ROOT, MACHINE_STORAGE_PATH]

# Import tar/raw images to machinectl from nspawnhub or any other registry.
#
# Image format should be DISTRO/RELEASE/TYPE. E.G: debian/sid/tar
export def --env "main init" [
  --verify (-v): string = "checksum" # The type of verification ran on the images 
  --name (-n): string # Name of the image imported to machinectl
  --config (-c): string # Path for the nspawn config to be copied to /var/lib/machines
  --override (-o) # Overrides the existing machine in storage
  --override-config = true # Overrides the existing configuration for the container
  --type (-t): string = "raw" # Type of machine (Raw or Tarball)
  --nspawnhub-url: string = $NSPAWNHUB_STORAGE_ROOT # URL for Nspawnhub's storage root
  --machine-storage: string = $MACHINE_STORAGE_PATH # Local storage path for Nspawn machines 
  image: string = "debian"
  tag: string = "sid"
] {
  let nspawnhub_gpg_path = $"($env.XDG_DATA_HOME? | default $"($env.HOME)/.local/share")/nuspawn/nspawnhub.gpg"
  let nuspawn_cache = $"($env.XDG_CACHE_HOME? | default $"($env.HOME)/.cache")/nuspawn"

  if (not ($nspawnhub_gpg_path | path exists)) and ($verify == "gpg")  {
    logger print "Could not find nspawnhub's GPG keys"
    let yesno = (input $"(ansi blue_bold)Do you wish to fetch them? [y/n]: (ansi reset)")

    match $yesno {
      Y|Yes|yes|y => { }
      _ => { return }
    }
    
    logger print "Fetching Nspawnhub keys..."
    mkdir ($nspawnhub_gpg_path | path dirname)
    mkdir $"($env.XDG_DATA_HOME? | default $"($env.HOME)/.local/share")/gnupg" # prevent gnupg from being annoying
    run-external 'gpg' '--no-default-keyring' $"--keyring=($nspawnhub_gpg_path)" '--fingerprint'
    mkdir $nuspawn_cache
    let tfile = (mktemp -p $nuspawn_cache --suffix .gpg masterkey.nspawn.org.XXXXXXX)
    http get $NSPAWNHUB_KEY_LOCATION | save -f $tfile
    run-external 'gpg' '--no-default-keyring' $"--keyring=($nspawnhub_gpg_path)" '--import' $"($tfile)" 
  }
  
  let image = $"($nspawnhub_url)/($image)/($tag)/($type)/image.($type).xz"
  mut output_image = $"($image)-($tag)-($type)"
  if $name != null {
    $output_image = $name
  }

  try {
    http head $image | ignore
  } catch {
    logger error "Failed finding image in storage, check if image is valid"
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
    let nspawn_config = $"($machine_storage)/($output_image).nspawn"
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


  logger info $"Pulling image ($image) tag ($tag)"
  try {
    run-external 'machinectl' $"pull-($type)" $"--verify=($verify)" $"($image)" $"($output_image)" 
  } catch {
    logger error $"Failure when fetching image"
    return
  }

  logger info "Removing read-only attribute from image"
  try {
    run-external 'machinectl' 'read-only' $"($output_image)" 'false'
  } catch {
    logger error "Failed setting image as writable"
  }

  logger success "All done! This is your new machine:"
  # TODO: Make this look even fancier!
  run-external 'machinectl' 'show-image' $"($output_image)" | lines | str trim | split column "=" Property Value
}
