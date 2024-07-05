export const NAME = "nuspawn"
export const VERSION = "%VERSION%"
export const GIT_COMMIT = "%GIT_COMMIT%"
export const NSPAWNHUB_STORAGE_ROOT = "https://hub.nspawn.org/storage"
export const NSPAWNHUB_KEY_LOCATION = "https://hub.nspawn.org/storage/masterkey.pgp"
export const MACHINE_STORAGE_PATH = "/var/lib/machines"
export const MACHINE_CONFIG_PATH = "/etc/systemd/nspawn"
export const NUSPAWN_PROFILES_PATH = "/etc/nuspawn/profiles"
export const CONFIG_EXTENSION = "nspawn"
export const DEFAULT_MACHINE = "debian"
export const DEFAULT_RELEASE = "sid"
export const NUSPAWN_CONTAINER_PATH = "/etc/nuspawn"
export def get_nuspawn_cache [] -> string {
  $"($env.XDG_CACHE_HOME? | default $"($env.HOME)/.cache")/nuspawn"
}
export def get_nuspawn_gpg_path [] -> string {
  $"($env.XDG_DATA_HOME? | default $"($env.HOME)/.local/share")/nuspawn/nspawnhub.gpg"
}
