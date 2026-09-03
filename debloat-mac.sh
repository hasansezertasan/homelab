#!/usr/bin/env bash
# Conservative, reversible resource tuning for a dedicated homelab Mac.
#
# Usage:
#   ./debloat-mac.sh apply    # capture current state, then tune
#   ./debloat-mac.sh status   # report current state (no sudo)
#   ./debloat-mac.sh undo     # restore the captured state

set -euo pipefail

BOLD=$'\033[1m'; DIM=$'\033[2m'; RED=$'\033[31m'; GRN=$'\033[32m'
YEL=$'\033[33m'; BLU=$'\033[34m'; RST=$'\033[0m'

step() { printf "\n${BOLD}${BLU}==>${RST} ${BOLD}%s${RST}\n" "$*"; }
ok()   { printf "    ${GRN}✓${RST} %s\n" "$*"; }
skip() { printf "    ${DIM}·${RST} ${DIM}%s${RST}\n" "$*"; }
warn() { printf "    ${YEL}!${RST} %s\n" "$*"; }
fail() { printf "    ${RED}✗${RST} %s\n" "$*" >&2; exit 1; }

ACTION="${1:-apply}"
STATE_DIR="${HOMELAB_DEBLOAT_STATE_DIR:-$HOME/.config/homelab/debloat}"
UID_NUM="$(id -u)"
PHOTO_SERVICE="com.apple.photoanalysisd"

[[ "$(uname -s)" == "Darwin" ]] || fail "This script is macOS-only."
[[ "$EUID" -ne 0 ]] || fail "Don't run as root; the script requests sudo only for Spotlight."

case "$ACTION" in
  apply|status|undo) ;;
  -h|--help)
    sed -n '2,8p' "$0"
    exit 0
    ;;
  *) fail "usage: $0 [apply|status|undo]" ;;
esac

state_path() {
  printf '%s/%s' "$STATE_DIR" "$1"
}

save_once() {
  local name="$1" value="$2" path
  path="$(state_path "$name")"
  [[ -f "$path" ]] && return 0
  mkdir -p "$STATE_DIR"
  chmod 700 "$STATE_DIR"
  printf '%s\n' "$value" > "$path"
  chmod 600 "$path"
}

spotlight_state() {
  local output
  output="$(mdutil -s / 2>/dev/null || true)"
  case "$output" in
    *"Indexing enabled"*)  printf 'enabled' ;;
    *"Indexing disabled"*) printf 'disabled' ;;
    *)                     printf 'unknown' ;;
  esac
}

photo_state() {
  local output line
  output="$(launchctl print-disabled "user/$UID_NUM" 2>/dev/null || true)"
  line="$(printf '%s\n' "$output" | grep -F "\"$PHOTO_SERVICE\"" | head -1 || true)"
  case "$line" in
    *"=> true"*)  printf 'disabled' ;;
    *"=> false"*) printf 'enabled' ;;
    *)             printf 'default' ;;
  esac
}

defaults_state() {
  local key="$1" value
  if value="$(defaults read com.apple.universalaccess "$key" 2>/dev/null)"; then
    case "$value" in
      1|true|TRUE) printf 'true' ;;
      0|false|FALSE) printf 'false' ;;
      *) printf 'unknown' ;;
    esac
  else
    printf 'unset'
  fi
}

apply_spotlight() {
  local current
  current="$(spotlight_state)"
  if [[ "$current" == "unknown" ]]; then
    warn "Spotlight state could not be determined; leaving it unchanged"
    return
  fi
  save_once spotlight "$current"
  if [[ "$current" == "disabled" ]]; then
    skip "Spotlight indexing already disabled on the startup volume"
  elif sudo mdutil -i off / >/dev/null \
       && [[ "$(spotlight_state)" == "disabled" ]]; then
    ok "Spotlight indexing disabled on the startup volume"
  else
    rm -f "$(state_path spotlight)"
    warn "could not disable Spotlight indexing"
  fi
}

apply_photoanalysis() {
  local current
  current="$(photo_state)"
  save_once photoanalysis "$current"
  if [[ "$current" == "disabled" ]]; then
    skip "$PHOTO_SERVICE already disabled"
    return
  fi
  if launchctl disable "user/$UID_NUM/$PHOTO_SERVICE" 2>/dev/null \
     && [[ "$(photo_state)" == "disabled" ]]; then
    launchctl bootout "gui/$UID_NUM/$PHOTO_SERVICE" 2>/dev/null || true
    ok "$PHOTO_SERVICE disabled for this user"
  else
    rm -f "$(state_path photoanalysis)"
    warn "could not disable $PHOTO_SERVICE"
  fi
}

apply_accessibility_setting() {
  local key="$1" label="$2" current
  current="$(defaults_state "$key")"
  if [[ "$current" == "unknown" ]]; then
    warn "$label state could not be determined; leaving it unchanged"
    return
  fi
  save_once "$key" "$current"
  if [[ "$current" == "true" ]]; then
    skip "$label already enabled"
  elif defaults write com.apple.universalaccess "$key" -bool true \
       && [[ "$(defaults_state "$key")" == "true" ]]; then
    ok "$label enabled (logout may be required)"
  else
    rm -f "$(state_path "$key")"
    warn "could not enable $label; Terminal may need Full Disk Access"
  fi
}

restore_spotlight() {
  local path previous desired
  path="$(state_path spotlight)"
  [[ -f "$path" ]] || { skip "Spotlight was not changed by homelab"; return; }
  previous="$(<"$path")"
  case "$previous" in
    enabled)  desired=on ;;
    disabled) desired=off ;;
    *) warn "invalid saved Spotlight state: $previous"; return ;;
  esac
  if sudo mdutil -i "$desired" / >/dev/null \
     && [[ "$(spotlight_state)" == "$previous" ]]; then
    rm -f "$path"
    ok "Spotlight indexing restored to $previous"
  else
    warn "could not restore Spotlight indexing"
  fi
}

restore_photoanalysis() {
  local path previous
  path="$(state_path photoanalysis)"
  [[ -f "$path" ]] || { skip "$PHOTO_SERVICE was not changed by homelab"; return; }
  previous="$(<"$path")"
  case "$previous" in
    disabled)
      launchctl disable "user/$UID_NUM/$PHOTO_SERVICE" 2>/dev/null || {
        warn "could not restore $PHOTO_SERVICE"; return;
      }
      ;;
    enabled|default)
      # launchctl has no public "remove override" operation. Enabling restores
      # the effective pre-bootstrap state when the service used its default.
      launchctl enable "user/$UID_NUM/$PHOTO_SERVICE" 2>/dev/null || {
        warn "could not restore $PHOTO_SERVICE"; return;
      }
      launchctl kickstart "gui/$UID_NUM/$PHOTO_SERVICE" 2>/dev/null || true
      ;;
    *) warn "invalid saved Photos-analysis state: $previous"; return ;;
  esac
  if [[ "$previous" == "disabled" && "$(photo_state)" != "disabled" ]]; then
    warn "could not verify restoration of $PHOTO_SERVICE"
    return
  fi
  rm -f "$path"
  ok "$PHOTO_SERVICE restored to its previous effective state ($previous)"
}

restore_accessibility_setting() {
  local key="$1" label="$2" path previous
  path="$(state_path "$key")"
  [[ -f "$path" ]] || { skip "$label was not changed by homelab"; return; }
  previous="$(<"$path")"
  case "$previous" in
    true)  defaults write com.apple.universalaccess "$key" -bool true ;;
    false) defaults write com.apple.universalaccess "$key" -bool false ;;
    unset) defaults delete com.apple.universalaccess "$key" 2>/dev/null || true ;;
    *) warn "invalid saved state for $label: $previous"; return ;;
  esac
  if [[ "$(defaults_state "$key")" != "$previous" ]]; then
    warn "could not restore $label; Terminal may need Full Disk Access"
    return
  fi
  rm -f "$path"
  ok "$label restored to $previous (logout may be required)"
}

show_status() {
  local managed=no
  [[ -d "$STATE_DIR" ]] && managed=yes
  printf "  %-26s %s\n" "homelab state snapshot" "$managed"
  printf "  %-26s %s\n" "Spotlight indexing" "$(spotlight_state)"
  printf "  %-26s %s\n" "Photos analysis" "$(photo_state)"
  printf "  %-26s %s\n" "Reduce motion" "$(defaults_state reduceMotion)"
  printf "  %-26s %s\n" "Reduce transparency" "$(defaults_state reduceTransparency)"
}

case "$ACTION" in
  apply)
    umask 077
    step "Conservative macOS resource tuning"
    apply_spotlight
    apply_photoanalysis
    apply_accessibility_setting reduceMotion "Reduce motion"
    apply_accessibility_setting reduceTransparency "Reduce transparency"
    ;;
  undo)
    step "Restoring pre-tuning macOS state"
    restore_spotlight
    restore_photoanalysis
    restore_accessibility_setting reduceMotion "Reduce motion"
    restore_accessibility_setting reduceTransparency "Reduce transparency"
    rmdir "$STATE_DIR" 2>/dev/null || true
    ;;
  status)
    show_status
    ;;
esac
