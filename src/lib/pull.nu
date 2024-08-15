use logger.nu *
use meta.nu [get_nuspawn_cache, get_nuspawn_gpg_path, NSPAWNHUB_KEY_LOCATION, NSPAWNHUB_STORAGE_ROOT, MACHINE_STORAGE_PATH, MACHINE_CONFIG_PATH, DEFAULT_MACHINE, DEFAULT_RELEASE]
use machine_manager.nu [machinectl, run_container, machine_exists]
use std assert
use setup.nu ["main setup"]
use start.nu ["main start", "main stop"]
use remove.nu ["main remove"]
use config.nu ["main config apply", "main config"]

export extern gpg [
  --no-default-keyring
  --keyring: string
  --fingerprint
  --import
  target?: string
]

# Import tar/raw images to the machine storage from nspawnhub or any other registry
export def --env "main pull" [
  --nspawnhub-url: string = $NSPAWNHUB_STORAGE_ROOT # URL for Nspawnhub's storage root
  --config-root: path = $MACHINE_CONFIG_PATH # Path where machine configurations are stored
  --storage-root: path = $MACHINE_STORAGE_PATH # Path where machines are stored
  --verify (-v): string = "checksum" # The type of verification ran on the images ("no", "checksum", "gpg") 
  --name (-n): string # Name of the machine to be called
  --override (-f) # Overrides the existing machine in storage
  --type (-t): string = "tar" # Type of machine (Raw or Tarball)
  --from-url (-u): string # Fetch image from URL instead of NspawnHub
  --from-path (-p): path # Import image from local path
  --machinectl (-m) = true # Use machinectl for operations
  --yes (-y) # Skip any input questions and just confirm them
  --fetch-to: string # Fetch image to path instead of pulling to machine storage
  --tar-extension: string = "tar.xz" # Extension when fetching tar images (only needed with machinectl=false)
  image?: string = DEFAULT_MACHINE
  tag?: string = DEFAULT_RELEASE
] {
  assert ($name != null) "Name must be not empty"

  let nspawnhub_gpg_path = (get_nuspawn_gpg_path)
  if ($verify == "gpg") and (not ($nspawnhub_gpg_path | path exists)) {
    logger warning "Could not find nspawnhub's GPG keys"
    let nuspawn_cache = (get_nuspawn_cache)
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

  if $from_path != null {
    if $machinectl {
      machinectl import-($type) $from_path
      logger success "Imported image successfully"
      return 
    }
    
    match $type {
      "tar" => {
        cp $from_path $storage_root
        let target_path = ($from_path | path basename)
        let filename = ($target_path | split row ".").0
        mkdir $"($storage_root)/($filename)"
        tar -xvf $"($storage_root)/($target_path)" -C $"($storage_root)/($filename)"
      }
      "raw" => {
        cp $from_path $storage_root
      }
    }
    
    logger success "Imported image successfully"
    return
  }

  let fetched_url = (
    if $from_url != null { $from_url } 
    else { $"($nspawnhub_url)/($image)/($tag)/($type)/image.($type).xz"})
  
  try {
    http head ($fetched_url) | ignore
  } catch {
    error make -u {
      msg: "Failure finding remote image, check if image is valid"
      help: "Check available images in nuspawn remote list"  
    }
    return
  }

  if $fetch_to != null {
    logger info "Fetching image to out path..."
    try {
      http get $fetched_url | save -f $fetch_to
    } catch {
      error make -u {
        msg: "Failure fetching image"
        help: "This error happened because of some error while saving or fetching the image, check your filesystem and network" 
      }
      return
    }
    logger success "Fetched image successfully!"
    return
  }

  let machine = (
    if $name != null { $name }
    else { $"($image)-($tag)-($type)" })

  let machine_exists = (
  try {
    machine_exists -t $type --machinectl=($machinectl) --storage-root=($storage_root) $machine
  } catch { |err|
    print $err
    error make -u {
      msg: "Failed checking if machine already exists or not in storage"
      help: $"Make sure to have access to the ($storage_root) folder"
    }
  })

  if $machine_exists and (not $override) {
    error make -u {
      msg: "Machine is already in storage"
      help: "If this is intentional, run with the -f (--override) flag" 
    }
    return
  }
  if $machine_exists { 
    logger info 'Deleting existing image'
    main remove --machinectl=($machinectl) --yes=($yes) --all $machine
  }

  logger info "Pulling machine to storage root..."
  if $machinectl {
    try {
      machinectl $"pull-($type)" $"--verify=($verify)" $"($fetched_url)" $"($machine)"
    } catch {
      error make -u {
        msg: "Failure when fetching image due to permission errors"
        help: "Try rerunning the command without verifications (--verify=no)"
      }
      return
    }
  } else {
    http get ($fetched_url) | save -f $"($storage_root)/($machine).($tar_extension)"
    rm -rf $"($storage_root)/($machine)"
    mkdir $"($storage_root)/($machine)"
    tar -x -f $"($storage_root)/($machine).($tar_extension)" -C $"($storage_root)/($machine)" 
    rm -f $"($storage_root)/($machine).($tar_extension)" 
  }

  logger info "Removing read-only attribute from image"
  try {
    # FIXME: I dont know how to make this without machinectl yet! Please do a PR if you do.
    machinectl read-only $"($machine)" "false"
  } catch {
    error make -u {
      msg: "Failure setting image as writable"
      help: "Might be either a permission issue or filesystem issue, please report with logs if this happens to you" 
    }
    return
  }

  logger success "Finished pulling machine"
}
