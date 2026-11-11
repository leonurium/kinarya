#!/usr/bin/env bash

KINARYA_HOME="${KINARYA_HOME:-$HOME/.kinarya}"
STATE_FILE="$KINARYA_HOME/state"
LOG_DIR="$KINARYA_HOME/logs"
BACKUP_DIR="$KINARYA_HOME/backup"

state_init(){
  if [[ ${DRY_RUN:-false} == true ]]; then return 0; fi
  mkdir -p "$KINARYA_HOME" "$LOG_DIR" "$BACKUP_DIR"
  [[ -f $STATE_FILE ]] || : > "$STATE_FILE"
}

state_done(){ grep -qxF "$1" "$STATE_FILE" 2>/dev/null; }

state_mark(){
  if [[ ${DRY_RUN:-false} == true ]]; then return 0; fi
  state_init
  grep -qxF "$1" "$STATE_FILE" 2>/dev/null || printf '%s\n' "$1" >> "$STATE_FILE"
}

state_clear(){
  local id=${1:-}
  if [[ -z $id ]]; then
    : > "$STATE_FILE"
  else
    grep -vxF "$id" "$STATE_FILE" > "$STATE_FILE.tmp" 2>/dev/null || true
    mv "$STATE_FILE.tmp" "$STATE_FILE"
  fi
}
