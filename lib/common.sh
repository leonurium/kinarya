#!/usr/bin/env bash

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'
  C_RED=$'\033[31m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'
  C_BLUE=$'\033[34m'; C_CYAN=$'\033[36m'
else
  C_RESET=""; C_BOLD=""; C_DIM=""; C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""; C_CYAN=""
fi

DRY_RUN=${DRY_RUN:-false}
ASSUME_YES=${ASSUME_YES:-false}
FORCE=${FORCE:-false}

info(){ printf '%s %s\n' "${C_BLUE}•${C_RESET}" "$*"; }
ok(){   printf '%s %s\n' "${C_GREEN}✔${C_RESET}" "$*"; }
warn(){ printf '%s %s\n' "${C_YELLOW}!${C_RESET}" "$*" >&2; }
err(){  printf '%s %s\n' "${C_RED}✘${C_RESET}" "$*" >&2; }
dim(){  printf '%s%s%s\n' "$C_DIM" "$*" "$C_RESET"; }
header(){ printf '\n%s%s%s\n' "${C_BOLD}${C_CYAN}" "$*" "$C_RESET"; }

have_cmd(){ command -v "$1" >/dev/null 2>&1; }
is_macos(){ [[ "$(uname -s)" == Darwin ]]; }
require_cmd(){ have_cmd "$1" || { err "Missing required command: $1"; return 1; }; }

confirm(){
  local prompt=$1 default=${2:-y} reply hint
  if [[ $ASSUME_YES == true ]]; then dim "auto-yes: $prompt"; return 0; fi
  hint="[y/N]"
  if [[ $default == y ]]; then hint="[Y/n]"; fi
  printf '%s %s %s ' "${C_CYAN}?${C_RESET}" "$prompt" "$hint"
  read -r reply || reply=""
  reply=${reply:-$default}
  [[ $reply =~ ^[Yy]$ ]]
}

run_cmd(){
  if [[ $DRY_RUN == true ]]; then dim "[dry-run] $*"; return 0; fi
  "$@"
}

append_line(){
  local file=$1; shift
  local text="$*"
  if [[ $DRY_RUN == true ]]; then dim "[dry-run] append to $file: $text"; return 0; fi
  ensure_dir "$(dirname "$file")"
  printf '%s\n' "$text" >> "$file"
}

ensure_profile_line(){
  local line=$1 file="${2:-$HOME/.zprofile}"
  if [[ -f $file ]] && grep -qF "$line" "$file" 2>/dev/null; then
    ok "$file already has: $line"
    return 0
  fi
  append_line "$file" "$line"
  ok "added to $file: $line"
}

pause(){
  if [[ $ASSUME_YES == true ]]; then return 0; fi
  printf '%s' "Press Enter to continue… "
  read -r _ || true
}

parse_selection(){
  local line=$1 max=$2 token
  line="${line//,/ }"
  for token in $line; do
    case "$token" in
      a|A|all|ALL) seq 1 "$max" ;;
      *-*)
        if [[ $token =~ ^([0-9]+)-([0-9]+)$ ]]; then seq "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"; fi ;;
      *)
        if [[ $token =~ ^[0-9]+$ ]]; then printf '%s\n' "$token"; fi ;;
    esac
  done | awk -v m="$max" '$1>=1 && $1<=m' | sort -n -u
}

SUDO_KEEPALIVE_PID=""
need_sudo(){
  if [[ $DRY_RUN == true ]]; then return 0; fi
  if ! sudo -n true 2>/dev/null; then
    info "Administrator password required for this step"
    sudo -v || { err "sudo authentication failed"; return 1; }
  fi
  if [[ -z $SUDO_KEEPALIVE_PID ]]; then
    ( while sudo -n true 2>/dev/null; do sleep 50; done ) &
    SUDO_KEEPALIVE_PID=$!
  fi
}

stop_sudo(){
  if [[ -n ${SUDO_KEEPALIVE_PID:-} ]]; then
    kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
    SUDO_KEEPALIVE_PID=""
  fi
}
