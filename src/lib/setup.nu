use meta.nu [NUSPAWN_CONTAINER_PATH]

# Setup a machine for CLI usage
export def "main setup" [
  --machinectl (-m) = false # Use machinectl for operations
  --image: string = "unspecified" # Distro image
  --release: string = "unspecified" # Distro release
  ...machines: string # Machines to be setup
] {
  for machine in $machines {
    main setup user $machine --start=true --stop=false root --machinectl=$machinectl --description="System Administrator"
    main setup meta $machine --image=$image  --release=$release --machinectl=$machinectl
    main setup sudo $machine --machinectl=$machinectl
    main setup networking $machine --machinectl=$machinectl
    main setup groups $machine --machinectl=$machinectl
  }
}

# Set up passwordless sudo for machine
export def "main setup sudo" [
  --machinectl (-m) = true # Use machinectl for operations
  --start (-s) = true # Start the machine before doing operations
  --stop (-s) = true # Stop the machine after doing operations
  machine: string
] {
  try {
    logger info $"[($machine)] Setting up sudo"
    (run_container
      --machinectl=($machinectl) 
      --start=($start)
      --stop=($stop)
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
  --start (-s) = true # Start the machine before doing operations
  --stop (-s) = true # Stop the machine after doing operations
  machine: string
] {
  try { 
    logger info $"[($machine)] Setting up meta information"
    let variables = [
      "DISPLAY=:0"
      "WAYLAND=wayland-0"
      "PATH=/usr/bin:/usr/sbin:/usr/local/bin"
      "XDG_RUNTIME_DIR=/run/user/1000"
      "XDG_CONFIG_HOME=~/.config"
      "XDG_DATA_HOME=~/.local/share"
    ] | str join "\n"
    
    (run_container 
      --machinectl=($machinectl)
      --start=($start)
      --stop=($stop)
      $machine
      $"stat /etc/profile.d/nuspawn.sh || printf \"($variables)\" >> /etc/profile.d/nuspawn.sh"
      $"mkdir -p ($NUSPAWN_CONTAINER_PATH)"
      $"echo 1 >> ($NUSPAWN_CONTAINER_PATH)/container"
      "grep VARIANT_ID=container /etc/os-release || printf 'VARIANT_ID=container' >> /etc/os-release"
      $"stat ($NUSPAWN_CONTAINER_PATH)/meta-distro.txt || echo '($image):($release)' > ($NUSPAWN_CONTAINER_PATH)/meta-distro.txt" e>| ignore) 
  }
}

# Set up a selected user manually within the machine
export def "main setup user" [
  --machinectl (-m) = true # Use machinectl for operations
  --uid (-u) # UID for user in machine
  --gid (-g) # GID for the user in machine
  --description (-d): string = "Machine operator"
  --shell: path = "/usr/bin/bash" # Shell that the user will use
  --start (-s) = true # Start the machine before doing operations
  --stop (-s) = true # Stop the machine after doing operations
  machine: string # Machine that will be setup
  user: string = "root" # User that will be setup inside of the machine
] {
  logger info $"[($machine)] Setting up user ($user)"
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

  let part2 = $".*/($user)::1::::::/g\" /etc/shadow" # Workaround needed due to the ".*" wildcard in sed
  try {
    (run_container 
      --machinectl=($machinectl)
      --start=($start)
      --stop=($stop)
      $machine
      $"grep ($user) /etc/passwd || echo '($user):x:($userid):($groupid):($description):($home):($shell)' >> /etc/passwd"
      $"sed -i \"s/^($user)($part2) || echo \'($user)::1::::::\' >> /etc/shadow"
      e>| ignore) 
  }
}

# Setup groups for users in the machine
export def "main setup groups" [
  --machinectl (-m) = true # Use machinectl for operations
  --start (-s) = true # Start the machine before doing operations
  --stop (-s) = true # Stop the machine after doing operations
  machine: string
  user: string = "root" # User that will be setup inside of the machine
] {
  logger info $"[($machine)] Setting up groups"
  try {
    (run_container 
      --machinectl=($machinectl)
      --start=($start)
      --stop=($stop)
      $machine
      $"usermod -aG video,render,sudo,wheel ($user)"
      e>| ignore) 
  }
}

# Setup networking resolving for machine
export def "main setup networking" [
  --machinectl (-m) = true # Use machinectl for operations
  --start (-s) = true # Start the machine before doing operations
  --stop (-s) = true # Stop the machine after doing operations
  machine: string
  dns: string = "1.1.1.1" # DNS server to be used by default
  resolv_location = "/etc/resolv.conf"
] {
  logger info $"[($machine)] Setting up networking"
  try {
    (run_container 
      --machinectl=($machinectl)
      --start=($start)
      --stop=($stop)
      $machine
      $"grep 'nameserver ($dns)' ($resolv_location) || echo 'nameserver ($dns)' >> ($resolv_location)"
      e>| ignore) 
  }
}
