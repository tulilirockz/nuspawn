use meta.nu [CONFIG_EXTENSION, get_nuspawn_cache]

export def get_config_path [
  config_root: string, 
  machine_name: string, 
  extension: string = $CONFIG_EXTENSION
] {
  return $"($config_root)/($machine_name).($extension)"
}

export def get_cached_file [
  --force (-f) # Override existing file
  manifest: string
] -> string {
  # Get a sum of the website so that we dont need to ping it any more than once.
  let cache_path = $"(get_nuspawn_cache)/($manifest | hash sha256)" 
  if (try { ($cache_path | path exists) } catch { false }) and (not $force) {
    return $cache_path
  }

  try {
    $manifest | url parse | ignore 
    http head $manifest | ignore
    mkdir (get_nuspawn_cache)
    print test
    http get --raw $manifest | save -f $cache_path
  } catch { $manifest }
  $cache_path 
}

export def get_machines_from_manifest [manifest: string] -> list<string> {
  ((open (get_cached_file $manifest)).machines? | filter { |e| $e.name? != null } | select name).name
}
