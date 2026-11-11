#!/usr/bin/env bash

USB_ROOT="${USB_ROOT:-}"
MACOS_DIR="${MACOS_DIR:-}"
WS_DIR="${WS_DIR:-}"
ARCHIVE_SRC="${ARCHIVE_SRC:-}"
DOCUMENT_SRC="${DOCUMENT_SRC:-}"
PROJECT_SRC="${PROJECT_SRC:-}"
SOFTWARE_DEST="${SOFTWARE_DEST:-$HOME/Downloads/Software}"
ARCHIVE_DEST="${ARCHIVE_DEST:-$HOME/Downloads/Archive}"
DOCUMENT_DEST="${DOCUMENT_DEST:-$HOME/Downloads/Document}"
PROJECT_DEST="${PROJECT_DEST:-$HOME/project}"

config_load(){
  local f
  for f in "$KINARYA_ROOT/config/kinarya.conf" "${KINARYA_HOME:-$HOME/.kinarya}/kinarya.conf"; do
    if [[ -f $f ]]; then
      # shellcheck disable=SC1090
      source "$f"
      dim "loaded config: $f"
    fi
  done
}

find_dir_ci(){
  local parent=$1 name=$2 d b want
  [[ -d $parent ]] || return 1
  want=$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')
  for d in "$parent"/*; do
    [[ -d $d ]] || continue
    b=$(printf '%s' "$(basename "$d")" | tr '[:upper:]' '[:lower:]')
    if [[ $b == "$want" ]]; then printf '%s\n' "$d"; return 0; fi
  done
  return 1
}

detect_usb(){
  local d base
  if [[ -n $USB_ROOT && -d $USB_ROOT ]]; then printf '%s\n' "$USB_ROOT"; return 0; fi
  for d in /Volumes/*; do
    [[ -d $d ]] || continue
    base=$(basename "$d")
    case "$base" in
      "Macintosh HD"|Recovery|"com.apple.TimeMachine"*) continue ;;
    esac
    if find_dir_ci "$d" MacOS >/dev/null 2>&1 || [[ -d $d/Workspaces ]]; then
      printf '%s\n' "$d"; return 0
    fi
  done
  return 1
}

resolve_paths(){
  if [[ -z $USB_ROOT ]]; then USB_ROOT=$(detect_usb 2>/dev/null || true); fi
  local base="$USB_ROOT"

  if [[ -z $MACOS_DIR ]]; then
    if [[ -n $base ]]; then MACOS_DIR=$(find_dir_ci "$base" MacOS || true); fi
    if [[ -z $MACOS_DIR && -n $base ]]; then MACOS_DIR="$base/MacOS"; fi
  fi

  if [[ -z $WS_DIR ]]; then
    if [[ -n $base ]]; then WS_DIR=$(find_dir_ci "$base" Workspaces || true); fi
    if [[ -z $WS_DIR && -n $base ]]; then WS_DIR="$base/Workspaces"; fi
  fi

  local ws="$WS_DIR"
  if [[ -z $ARCHIVE_SRC ]]; then
    ARCHIVE_SRC=$(find_dir_ci "$ws" Archive 2>/dev/null || true)
    if [[ -z $ARCHIVE_SRC ]]; then ARCHIVE_SRC="$ws/Archive"; fi
  fi
  if [[ -z $DOCUMENT_SRC ]]; then
    DOCUMENT_SRC=$(find_dir_ci "$ws" Document 2>/dev/null || true)
    if [[ -z $DOCUMENT_SRC ]]; then DOCUMENT_SRC="$ws/Document"; fi
  fi
  if [[ -z $PROJECT_SRC ]]; then
    PROJECT_SRC=$(find_dir_ci "$ws" project 2>/dev/null || true)
    if [[ -z $PROJECT_SRC ]]; then PROJECT_SRC="$ws/project"; fi
  fi

  export USB_ROOT MACOS_DIR WS_DIR ARCHIVE_SRC DOCUMENT_SRC PROJECT_SRC
  export SOFTWARE_DEST ARCHIVE_DEST DOCUMENT_DEST PROJECT_DEST
}

validate_macos_dir(){
  resolve_paths
  if [[ -z $USB_ROOT || ! -d $USB_ROOT ]]; then
    err "USB drive not found. Mount it, or set USB_ROOT in a config file."
    return 1
  fi
  if [[ ! -d $MACOS_DIR ]]; then
    err "Software folder not found: $MACOS_DIR"
    return 1
  fi
  return 0
}

show_paths(){
  resolve_paths
  printf '  %sUSB%s        %s\n' "$C_DIM" "$C_RESET" "${USB_ROOT:-(not found)}"
  printf '  %ssoftware%s   %s\n' "$C_DIM" "$C_RESET" "${MACOS_DIR:-(unset)}"
  printf '  %sworkspaces%s %s\n' "$C_DIM" "$C_RESET" "${WS_DIR:-(unset)}"
  printf '  %sdest%s       %s | %s | %s | %s\n' "$C_DIM" "$C_RESET" \
    "$SOFTWARE_DEST" "$ARCHIVE_DEST" "$DOCUMENT_DEST" "$PROJECT_DEST"
}
