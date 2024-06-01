# Setup a machine for CLI use
export def "main setup" [
  --nspawn (-n)
  machine: string
] {
  (run_container 
    --nspawn=$nspawn 
    $machine
    "mkdir -p /etc/nuspawn"
    "echo 1 >> /etc/nuspawn/container" # For fancy shells when you want to know if you are in a container for your PS1 or virtual environment
    "sed -i "s/^root.*/root::1::::::/g" /etc/shadow" 
    $"echo 'root::1::::::' >> /etc/shadow" # Will add a duplicate if the image already has a definition, but doesnt matter in the end
  )
}
