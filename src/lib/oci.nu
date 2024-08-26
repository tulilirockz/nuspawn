use meta.nu [MACHINE_STORAGE_PATH]
use machine_manager.nu [machine_exists, privileged_run]
use remove.nu "main remove"
use std assert
use logger.nu *

# Pull an OCI image and import it to machine storage
export def "main oci pull" [
  --storage-root: path = $MACHINE_STORAGE_PATH # Path where machines are stored
  --tmpdir: path = "/tmp" # Temporary directory where images will be fetched to
  --runtime (-r) = "docker" # Selected runtime to get the image
  --extract (-e) = true # Extract the image after fetching it
  --force (-f) # Force override if image already exists
  --machinectl (-m) = true # Use machinectl for operations
  name: string # Machine name that will be output from the image
  image: string # OCI image that will be fetched/stored
] {
  try {
    run-external $runtime info | ignore
  } catch {
    error make -u {
      msg: "Failed finding OCI runtime in $PATH"
      help: "Try installing podman or docker first. If you already have one of those installed, add them to your $PATH variable"
    }
    return
  }

  let tmpdir = (mktemp -d -p $tmpdir)
  
  logger info $"Creating container through ($runtime)"
  let fetched_image = (run-external $runtime create $image)
  
  logger info $"Exporting image to machine storage"
  run-external $runtime export $fetched_image $'--output=($tmpdir)/($name).tar'

  mut image_already_imported = (
    try {
      machine_exists -t tar --machinectl=($machinectl) --storage-root=($storage_root) $name
    } catch { |err|
      error make -u {
        msg: "Failed checking if machine already exists or not in storage"
        help: $"Make sure to have access to the ($storage_root) folder"
      }
      return
    }
  )

  if $image_already_imported and (not $force) {
    error make -u {
      msg: "Image already imported to storage"
      help: "If this was intentional, rerun with the --force argument"
    }
    return
  } else if ($image_already_imported) and ($force) {
    main remove $name --yes --force -t "tar" --all
    $image_already_imported = false
  }

  if $extract and not $image_already_imported {
    logger debug "Extracting image rootfs as machine"
    try {
      privileged_run "mkdir" "-p" $"($storage_root)/($name)"
      privileged_run "tar" "-x" "-f" $"($tmpdir)/($name).tar" "-C" $"($storage_root)/($name)"
    } catch {
      error make -u {
        msg: "Could not add image to storage due to permission issues"
        help: "Try running as a privileged user"
      }
      return
    }
    logger success $"Successfully imported machine ($image) as ($name)"
  }
}
