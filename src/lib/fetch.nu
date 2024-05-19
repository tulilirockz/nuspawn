use meta.nu [NAME, NSPAWNHUB_STORAGE_ROOT]
use logger.nu *

# Fetch image off of remote and save to specified location, allowing you to manually mess around with it 
export def "main fetch" [
  --type (-t) = "tar" # Type of the image (raw, tar)
  --extract (-e) # Extract image if it is a tarball
  --out-extract (-o) # Path where images should be extracted to
  --force (-f) # Override if image is already fetched in $out
  distro: string # Distribution in Nspawnhub as of 'remote list'
  release: string # Release for that distribution
  out: string # Path where the image should be fetched to
] {
  let image = $"($NSPAWNHUB_STORAGE_ROOT)/($distro)/($release)/($type)/image.($type).xz"
  try {
    http head $image | ignore
  } catch {
    logger error "Failed to find image in remote, check out remote list."
    return
  }

  if (($out | path exists) and (not $force)) {
    logger error $"Image is already fetched in ($out), exiting."
    return
  }
  
  logger print "Fetching image, please wait..."

  try {
    http get $image | save -f $out
  } catch {
    logger error "Failed fetching image"
    return
  }
  logger print "Image fetched successfully!"

  if $extract {
    logger print $"Extracting image to ($out_extract)"
    try {
      mkdir $out_extract
      run-external 'tar' 'xf' $'($out)' '--directory' $"($out_extract)"
    } catch {
      logger error "Failed extracting image due to OS error, maybe you dont have tar on your $PATH."
      return
    }
  }
}
