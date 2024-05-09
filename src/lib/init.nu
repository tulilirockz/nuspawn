use meta.nu [NAME]

const NSPAWNHUB_KEY_LOCATION = "https://hub.nspawn.org/storage/masterkey.pgp" 
const NSPAWNHUB_STORAGE_ROOT = "https://hub.nspawn.org/storage"

def fancy_print [...data: string] {
  print $"(ansi blue_bold)[($NAME)] (echo ...$data)(ansi reset)"
}

def fancy_error [...data: string] {
  print $"(ansi blue_bold)[($NAME)] (echo ...$data)(ansi reset)"
}

# Import tar/raw images to machinectl from nspawnhub or any other registry.
#
# Image format should be DISTRO/RELEASE/TYPE. E.G: debian/sid/tar
export def --env "main init" [
  --verify (-v): string = "checksum" # The type of verification ran on the images 
  --name (-n): string # Name of the image imported to machinectl
  --config (-c): string # Path for the nspawn config to be copied to /var/lib/machines
  --override (-o) # Overrides the existing machine in storage
  --override-config # Overrides the existing configuration for the container
  init: string
] {
  let nspawnhub_gpg_path = $"($env.XDG_DATA_HOME? | default $"($env.HOME)/.local/share")/nuspawn/nspawnhub.gpg"
  let nuspawn_cache = $"($env.XDG_CACHE_HOME? | default $"($env.HOME)/.cache")/nuspawn"

  if (not ($nspawnhub_gpg_path | path exists)) and ($verify == "gpg")  {
    fancy_print "Could not find nspawnhub's GPG keys"
    let yesno = (input $"(ansi blue_bold)Do you wish to fetch them? [y/n]: (ansi reset)")

    match $yesno {
      Y|Yes|yes|y => { }
      _ => { return }
    }
    
    fancy_print "Fetching..."
    mkdir ($nspawnhub_gpg_path | path dirname)
    mkdir $"($env.XDG_DATA_HOME? | default $"($env.HOME)/.local/share")/gnupg" # prevent gnupg from being annoying
    run-external 'gpg' '--no-default-keyring' $"--keyring=($nspawnhub_gpg_path)" '--fingerprint'
    mkdir $nuspawn_cache
    let tfile = (mktemp -p $nuspawn_cache --suffix .gpg masterkey.nspawn.org.XXXXXXX)
    http get $NSPAWNHUB_KEY_LOCATION | save -f $tfile
    run-external 'gpg' '--no-default-keyring' $"--keyring=($nspawnhub_gpg_path)" '--import' $"($tfile)" 
  }
  
  let userdata = ($init | split column "/" DISTRO RELEASE TYPE)
  let image = $"($NSPAWNHUB_STORAGE_ROOT)/($userdata.DISTRO.0)/($userdata.RELEASE.0)/($userdata.TYPE.0)/image.($userdata.TYPE.0).xz"
  mut output_image = $"($userdata.DISTRO.0)-($userdata.RELEASE.0)-($userdata.TYPE.0)"
  if $name != null {
    $output_image = $name
  }

  try {
    http head $image | ignore
  } catch {
    fancy_print "Failed fetching image, try checking images with nuspawn list"
    return
  }

  if ((run-external 'machinectl' 'show-image' $output_image | complete | get exit_code) != 1) {
    if not $override {
      fancy_print "Image is already in storage, exiting."
      run-external 'machinectl' 'show-image' $output_image
      return 
    } 

    fancy_print 'Deleting existing image'
    run-external 'machinectl' 'remove' $output_image
  } 

  fancy_print $"Pulling the image via machinectl pull-($userdata.TYPE.0)"
  if $config != null {
    log debug "Applied configuration to /var/lib/machines."
    let nspawn_config = $"/var/lib/machines/($output_image).nspawn" 
    if not ($output_image | path exists) or $override_config {
      pkexec cp $config $nspawn_config
    } else {
      open $config | save $nspawn_config --append
    }
  }

  try {
    run-external 'machinectl' $"pull-($userdata.TYPE.0)" $"($image)" $"($output_image)" $"--verify=($verify)"
  } catch {
    fancy_error $"Failure when fetching image, most likely a network error."
    return
  }

  fancy_print "Removing read-only attribute from image"
  try {
    run-external 'machinectl' 'read-only' $"($output_image)" 'false'
  } catch {
    fancy_error "Failed setting image as writable"
  }

  fancy_print "All done! This is your new machine:"
  run-external 'machinectl' 'show-image' $"($output_image)"
}
