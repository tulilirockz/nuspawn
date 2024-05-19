# Delete all local images - WARNING: destructive operation, this WILL delete everything.
export def "main prune" [
  --no-warning # Do not warn that this will delete everything from local storage
] {
  if not $no_warning {
    logger error "WARNING: THIS COMMAND WILL CLEAR ALL IMAGES IN LOCA STORAGE"
    let yesno = (input $"(ansi blue_bold)Do you wish to delete all your local images? [y/n]: (ansi reset)")

    match $yesno {
      Y|Yes|yes|y => { }
      _ => { return }
    }
  }
  pkexec rm -rf /var/lib/machines/*
}
