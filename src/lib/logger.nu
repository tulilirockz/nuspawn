use meta.nu [NAME]

export def "logger info" [...data: string] {
  print $"(ansi blue_bold)[($NAME)] (echo ...$data)(ansi reset)"
}

export def "logger success" [...data: string] {
  print $"(ansi green_bold)[($NAME)] (echo ...$data)(ansi reset)"
}

export def "logger error" [...data: string] {
  print $"(ansi red_bold)[($NAME)] (echo ...$data)(ansi reset)"
}

export def "logger warning" [...data: string] {
  print $"(ansi yellow_bold)[($NAME)] (echo ...$data)(ansi reset)"
}
