use meta.nu [MACHINE_STORAGE_PATH]
use machine_manager.nu privileged_run
use logger.nu *

# Pull an OCI (docker/podman) image and import it to machine storage
export def "main oci pull" [
  --storage-root: path = $MACHINE_STORAGE_PATH # Path where machines are stored
  --tmpdir: path = "/tmp" # Temporary directory where images will be fetched to
  --runtime (-r) = "docker" # Selected runtime to get the image
  --extract (-e) = true # Extract the image after fetching it
  --force (-f) # Force override if image already exists
  image: string # OCI image that will be fetched/stored
  name: string = "out" # Machine name that will be output from the image
] {
  let image_already_fetched = (try { ($"($tmpdir)/($name).tar" | path exists) } catch { false })
  if $image_already_fetched {
    logger warning "Image has already been fetched to temporary directory, skipping."
  } else {
    logger info $"Creating container through ($runtime)"
    let fetched_image = (run-external $runtime create $image)
    logger info $"Exporting image to machine storage"
    try {
      run-external $runtime export $fetched_image $'--output=($tmpdir)/($name).tar'
    } catch {
      logger error "Failure exporting image storage to machine storage"
      return
    }
  }
  
  let image_already_imported = (machine_exists -t "tar" --storage-root=($storage_root) $name)
  if not $image_already_imported {
    logger error "Image already imported to storage"
    return
  }
  if $extract and $image_already_imported {
    logger info "Extracting image rootfs as machine"
    try {
      privileged_run "mkdir" "-p" $"($storage_root)/($name)"
      privileged_run "tar" "xf" $"($tmpdir)/($name).tar" "-C" $"($storage_root)/($name)"
    } catch {
      logger error "Failure extracting container image to machine storage"
      return
    }
  }
  logger success $"Successfully imported machine ($image) as ($name)"
}
