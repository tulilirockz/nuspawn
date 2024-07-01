use logger.nu *
use meta.nu [NSPAWNHUB_KEY_LOCATION, NSPAWNHUB_STORAGE_ROOT, MACHINE_STORAGE_PATH, MACHINE_CONFIG_PATH, DEFAULT_MACHINE, DEFAULT_RELEASE]
use machine_manager.nu [machinectl, run_container]
use std assert
use setup.nu ["main setup"]
use start.nu ["main start", "main stop"]
use remove.nu ["main remove"]
use config.nu ["main config apply", "main config"]
use verify.nu [gpg]
# Import tar/raw images to machinectl from nspawnhub or any other registry
export def --env "main pull" [
  --nspawnhub-url: string = $NSPAWNHUB_STORAGE_ROOT # URL for Nspawnhub's storage root
  --config-root: path = $MACHINE_CONFIG_PATH # Path where machine configurations are stored
  --storage-root: path = $MACHINE_STORAGE_PATH # Path where machines are stored
  --verify (-v): string = "checksum" # The type of verification ran on the images ("no", "checksum", "gpg") 
  --name (-n): string # Name of the machine to be called
  --override (-f) # Overrides the existing machine in storage
  --type (-t): string = "tar" # Type of machine (Raw or Tarball)
  --from-url (-u): string # Fetch image from URL instead of NspawnHub
  --machinectl (-m) = true # Use machinectl for operations
  --yes (-y) # Skip any input questions and just confirm them
  --fetch: string # Fetch image to path instead of pulling to machine storage
  --tar-extension: string = "tar.xz" # Extension when fetching tar images (only needed with machinectl=false)
  image?: string = DEFAULT_MACHINE
  tag?: string = DEFAULT_RELEASE
] {
  let nspawnhub_gpg_path = $"($env.XDG_DATA_HOME? | default $"($env.HOME)/.local/share")/nuspawn/nspawnhub.gpg"
  if ($verify == "gpg") and (not ($nspawnhub_gpg_path | path exists)) {
  let nuspawn_cache = $"($env.XDG_CACHE_HOME? | default $"($env.HOME)/.cache")/nuspawn"
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

  let fetched_url = (
    if $from_url != null { $from_url } 
    else { $"($nspawnhub_url)/($image)/($tag)/($type)/image.($type).xz"})
  
  try {
    http head ($fetched_url) | ignore
  } catch {
    logger error "Failure finding remote image, check if image is valid"
    return
  }

  if $fetch != null {
    logger info "Fetching image to out path..."
    try {
      http get $fetched_url | save -f $fetch
    } catch {
      logger error "Failure fetching image due to either network error or permission error"
      return
    }
    logger success "Fetched image successfully!"
    return
  }

  let machine = (
    if $name != null { $name }
    else { $"($image)-($tag)-($type)" })

  let machine_exists = (machine_exists -t $type --storage-root=($storage_root) $machine)

  if $machine_exists and (not $override) {
    logger error "Machine is already in storage, exiting."
    return 
  } else if ($override) {
    logger info 'Deleting existing image'
    main remove --machinectl=($machinectl) --yes=($yes) $machine
  }

  logger info "Pulling machine to storage root..."
  try {
    if $machinectl {
      machinectl $"pull-($type)" $"--verify=($verify)" $"($fetched_url)" $"($machine)"
    } else {
      http get ($fetched_url) | save -f $"($storage_root)/($machine).($tar_extension)"
      rm -rf $"($storage_root)/($machine)"
      mkdir $"($storage_root)/($machine)"
      tar -x -v -f $"($storage_root)/($machine).($tar_extension)" -C $"($storage_root)/($machine)" 
      rm -f $"($storage_root)/($machine).($tar_extension)" 
    }
  } catch {
    logger error "Failure when fetching image due to permission errors"
    return
  }

  logger info "Removing read-only attribute from image"
  try {
    # FIXME: I dont know how to make this without machinectl yet! Please do a PR if you do.
    machinectl read-only $"($machine)" "false"
  } catch {
    logger error "Failure setting image as writable"
  }

  logger success "Finished pulling machine"
}
