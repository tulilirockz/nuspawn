# Lists the current nspawnhub images in a fancy table
export def "main remote-list" [] {
  const NSPAWNHUB_LIST = "https://hub.nspawn.org/storage/list.txt"
  http get $NSPAWNHUB_LIST
    | str replace -a "nspawn -i" "nuspawn init"
    | lines
    | range 2..
    | split column "|" DISTRO RELEASE INIT
    | each { |e| $e | str trim }
}
