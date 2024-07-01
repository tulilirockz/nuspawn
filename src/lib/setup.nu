use meta.nu [NUSPAWN_CONTAINER_PATH]

# Setup a machine for CLI usage
export def "main setup" [
  --machinectl (-m) = true # Use machinectl for operations
  --image: string = "unspecified" # Distro image
  --release: string = "unspecified" # Distro release
  ...machines: string # Machines to be setup
] {
  for machine in $machines {
    main setup meta $machine --image=$image --release=$release --machinectl=$machinectl
    main setup user $machine root --machinectl=$machinectl --description "System Administrator"
    main setup sudo $machine --machinectl=$machinectl
  }
}

export def "main setup sudo" [
  --machinectl (-m) = true # Use machinectl for operations
  machine: string
] {
  try {
    logger info $"[($machine)] Setting up sudo"
    (run_container
      --machinectl=($machinectl) 
      $machine
      "sed -i -e 's/ ALL$/ NOPASSWD:ALL/' /etc/sudoers"
    )
  }
}

# Set up a machine with distro information and others
export def "main setup meta" [
  --machinectl (-m) = true # Use machinectl for operations
  --image: string = "unspecified" # Distro image
  --release: string = "unspecified" # Distro release
  machine: string
] {
  try { 
    logger info $"[($machine)] Setting up meta information"
    (run_container 
      --machinectl=($machinectl)
      $machine
      $"mkdir -p ($NUSPAWN_CONTAINER_PATH)"
      $"echo 1 >> ($NUSPAWN_CONTAINER_PATH)/container"
      "echo 'VARIANT_ID=container' >> /etc/os-release"
      $"echo '($image):($release)' > ($NUSPAWN_CONTAINER_PATH)/meta-distro.txt" e>| ignore) 
  }
}

# Set up a selected user manually within the machine
export def "main setup user" [
  --machinectl (-m) = true # Use machinectl for operations
  --uid (-u) # UID for user in machine
  --gid (-g) # GID for the user in machine
  --description (-d): string = "Machine operator"
  --shell: path = "/usr/bin/bash" # Shell that the user will use
  machine: string # Machine that will be setup
  user: string = "root" # User that will be setup inside of the machine
] {
  let userid = if $uid != null { $uid } else {
    match $user {
      "root" => 0
      _ => 1000
    }
  }
  let groupid = if $gid != null { $gid } else {
    match $user {
      "root" => 0
      _ => 1000
    }
  }
  let home = match $user {
    "root" => "/root"
    _ => $"/home/($user)"
  }
    
  let part2 = $".*/($user)::1::::::/g\" /etc/shadow || echo \'::1::::::\' >> /etc/shadow" # Workaround needed due to the ".*" wildcard in sed
    logger info $"[($machine)] Setting up user ($user)"
  try {
    (run_container 
      --machinectl=($machinectl)
      $machine
      $"grep ($user) /etc/passwd || echo '($user):x:($userid):($groupid):($description):($home):($shell)' >> /etc/passwd"
      $"sed -i \"s/^($user)($part2)" 
      e>| ignore) 
  }
}
