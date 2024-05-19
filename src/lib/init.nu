use logger.nu *
use meta.nu [NSPAWNHUB_KEY_LOCATION, NSPAWNHUB_STORAGE_ROOT]

# Import tar/raw images to machinectl from nspawnhub or any other registry.
#
# Image format should be DISTRO/RELEASE/TYPE. E.G: debian/sid/tar
export def --env "main init" [
  --verify (-v): string = "checksum" # The type of verification ran on the images 
  --name (-n): string # Name of the image imported to machinectl
  --config (-c): string # Path for the nspawn config to be copied to /var/lib/machines
  --override (-o) # Overrides the existing machine in storage
  --override-config # Overrides the existing configuration for the container
  --type (-t): string = "tar" # Type of machine (Raw or Tarball) 
  distro: string = "debian"
  release: string = "sid"
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
  
  let image = $"($NSPAWNHUB_STORAGE_ROOT)/($distro)/($release)/($type)/image.($type).xz"
  mut output_image = $"($distro)-($release)-($type)"
  if $name != null {
    $output_image = $name
  }

  try {
    http head $image | ignore
  } catch {
    logger print "Failed fetching image, try checking images with nuspawn list"
    return
  }

  if ((run-external 'machinectl' 'show-image' $output_image | complete | get exit_code) != 1) {
    if not $override {
      logger print "Image is already in storage, exiting."
      run-external 'machinectl' 'show-image' $output_image
      return 
    } 

    logger print 'Deleting existing image'
    run-external 'machinectl' 'remove' $output_image
  } 
  if $config != null {
    logger print "Applied configuration to /var/lib/machines."
    let nspawn_config = $"/var/lib/machines/($output_image).nspawn" 
    if not ($output_image | path exists) or $override_config {
      pkexec cp $config $nspawn_config
    } else {
      open $config | save $nspawn_config --append
    }
  }


  logger print $"Pulling the image via machinectl pull-($type)"
  try {
    run-external 'machinectl' $"pull-($type)" $"($image)" $"($output_image)" $"--verify=($verify)"
  } catch {
    logger error $"Failure when fetching image, most likely a network error."
    return
  }

  logger print "Removing read-only attribute from image"
  try {
    run-external 'machinectl' 'read-only' $"($output_image)" 'false'
  } catch {
    logger error "Failed setting image as writable"
  }

  logger print "All done! This is your new machine:"
  run-external 'machinectl' 'show-image' $"($output_image)"
}
