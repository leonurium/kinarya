#!/usr/bin/env bash

ensure_dir(){ if [[ -d $1 ]]; then return 0; fi; run_cmd mkdir -p "$1"; }
dir_has_entries(){ [[ -d $1 && -n "$(ls -A "$1" 2>/dev/null)" ]]; }
human_size(){ du -sh "$1" 2>/dev/null | cut -f1; }
need_path(){ [[ -e $1 ]] || { err "Missing: $1"; return 1; }; }
