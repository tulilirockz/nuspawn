use meta.nu [NAME]

export def "logger print" [...data: string] {
  print $"(ansi blue_bold)[($NAME)] (echo ...$data)(ansi reset)"
}

export def "logger error" [...data: string] {
  print $"(ansi red_bold)[($NAME)] (echo ...$data)(ansi reset)"
}
