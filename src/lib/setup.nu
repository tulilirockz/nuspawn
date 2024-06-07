# Setup a machine for CLI use
export def "main setup" [
  --machinectl (-m) = true # Use machinectl for operations
  --distro-image: string # Distro image
  --distro-release: string # Distro release
  ...machines: string # Machines to be setup
] {
  for machine in $machines {
    logger debug "Setting up passwordless root in machine"
    try { 
      (run_container 
        --machinectl=($machinectl)
        $machine
        "mkdir -p /etc/nuspawn"
        "echo 1 >> /etc/nuspawn/container" # For fancy shells when you want to know if you are in a container for your PS1 or virtual environment
        "sed -i "s/^root.*/root::1::::::/g" /etc/shadow || echo 'root::1::::::' >> /etc/shadow"
        $"echo '($distro_image):($distro_release)' > /etc/nuspawn/meta-distro.txt" e>| ignore) 
    }
  }
}

export def "main setup root" [] {

}

export def "main setup user" [] {

}
