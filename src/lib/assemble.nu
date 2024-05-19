use meta.nu [NAME]

# Assemble Nspawn machines from YAML
export def "main assemble" [] {
  $"Usage: ($NAME) assemble <command>..."
}

export def "main assemble create" [
  --override (-f) # Replace if machine already exists
] {

}

export def "main assemble remove" [] {

}
