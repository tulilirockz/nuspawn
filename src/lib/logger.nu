use meta.nu [NAME]
use std assert
export def "logger info" [...data: string] {
  logger raw (ansi blue_bold) ...$data 
}
export def "logger success" [...data: string] {
  logger raw (ansi green_bold) ...$data
}
export def "logger error" [...data: string] {
  logger raw (ansi red_bold) ...$data
}
export def "logger warning" [...data: string] {
  logger raw (ansi yellow_bold) ...$data
}
export def "logger debug" [...data: string] {
  logger raw (ansi green_bold) ...$data
}
export def "logger raw" [color: string, ...data: string] {
  if $env.NO_COLOR? != null and $env.NO_COLOR? == "1" {
    print ($"[($NAME)] (echo ...$data | str join ' ')" | ansi strip)
    return
  }
  print $"($color)[($NAME)] (echo ...$data | str join ' ')(ansi reset)"
}
