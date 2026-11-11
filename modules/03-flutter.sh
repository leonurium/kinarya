#!/usr/bin/env bash

device_arch(){
  if [[ "$(uname -m)" == "arm64" ]]; then printf 'arm64\n'
  elif [[ "$(sysctl -n hw.optional.arm64 2>/dev/null)" == "1" ]]; then printf 'arm64\n'
  else printf 'x64\n'; fi
}

flutter_zip_arch(){
  case "$(basename "$1")" in
    *arm64*) printf 'arm64\n' ;;
    *)       printf 'x64\n' ;;
  esac
}

module_flutter(){
  resolve_paths
  local target="${PROJECT_DEST:-$PROJECT_SRC}"
  if [[ -z $target ]]; then
    warn "No project folder configured (set PROJECT_DEST)"
    return 0
  fi

  local -a scan_dirs=()
  if [[ -n $PROJECT_DEST && -d $PROJECT_DEST ]]; then scan_dirs+=("$PROJECT_DEST"); fi
  if [[ -n $PROJECT_SRC && -d $PROJECT_SRC && $PROJECT_SRC != "$PROJECT_DEST" ]]; then scan_dirs+=("$PROJECT_SRC"); fi
  if [[ ${#scan_dirs[@]} -eq 0 ]]; then
    warn "Project folder not found (run the workspaces step first)"
    return 0
  fi
  info "Project folder: $target"

  local -a zips=()
  local d f
  for d in "${scan_dirs[@]}"; do
    while IFS= read -r f; do if [[ -n $f ]]; then zips+=("$f"); fi; done < <(find "$d" -maxdepth 1 -iname 'flutter*.zip' ! -name '._*' | sort)
    if [[ ${#zips[@]} -gt 0 ]]; then break; fi
  done

  if [[ ${#zips[@]} -eq 0 ]]; then
    warn "No Flutter zip found in: ${scan_dirs[*]}"
    return 0
  fi

  local arch; arch=$(device_arch)
  header "Flutter SDK (this Mac: $arch)"

  local -a match=()
  local z i=1
  for z in "${zips[@]}"; do
    if [[ $(flutter_zip_arch "$z") == "$arch" ]]; then
      printf '  %2d) %-46s %8s  %s\n' "$i" "$(basename "$z")" "$(human_size "$z")" "${C_GREEN}matches this Mac${C_RESET}"
      match+=("$z")
    else
      printf '  %2d) %-46s %8s  %s\n' "$i" "$(basename "$z")" "$(human_size "$z")" "${C_DIM}other arch${C_RESET}"
    fi
    i=$((i+1))
  done

  if [[ ${#match[@]} -eq 0 ]]; then
    warn "No Flutter zip matches this Mac (arch: $arch)"
    if confirm "Install a mismatched build anyway (it may not run natively)?" n; then
      match=("${zips[@]}")
    else
      return 0
    fi
  fi

  local chosen=""
  if [[ ${#match[@]} -eq 1 ]]; then
    chosen="${match[0]}"
    ok "Selected $(basename "$chosen")"
  else
    printf 'Which version? '
    local sel=""; read -r sel || true
    local idx
    for idx in $(parse_selection "$sel" "${#match[@]}"); do chosen="${match[$((idx-1))]}"; break; done
  fi
  if [[ -z $chosen ]]; then warn "Nothing selected"; return 0; fi

  confirm "Unzip $(basename "$chosen") into $target and add it to PATH?" y || { dim "skipped Flutter"; return 0; }

  local fdir="$target/flutter"
  if [[ -e $fdir ]]; then
    if confirm "$fdir already exists. Replace it?" n; then
      run_cmd rm -rf "$fdir"
    else
      dim "keeping existing $fdir"
    fi
  fi

  if [[ $DRY_RUN == true ]]; then
    dim "[dry-run] ditto -x -k $(basename "$chosen") $target"
  else
    ensure_dir "$target"
    info "Extracting Flutter — this can take a minute…"
    ditto -x -k "$chosen" "$target" || { err "Failed to extract Flutter"; return 1; }
  fi

  if [[ ! -d $fdir ]]; then
    local cand; cand=$(find "$target" -maxdepth 1 -type d -iname 'flutter*' ! -name '._*' | head -n 1 || true)
    if [[ -n $cand ]]; then fdir="$cand"; fi
  fi
  if [[ ! -d $fdir && $DRY_RUN != true ]]; then
    err "Flutter folder not found after extraction"
    return 1
  fi

  local bin="$fdir/bin" pathref
  if [[ $bin == "$HOME/"* ]]; then pathref="\$HOME/${bin#$HOME/}"; else pathref="$bin"; fi
  ensure_profile_line "export PATH=\"$pathref:\$PATH\""
  export PATH="$bin:$PATH"

  if [[ $DRY_RUN != true ]]; then
    if confirm "Run 'flutter --version' now (first run downloads the Dart SDK)?" y; then
      flutter --version || warn "flutter --version failed"
    else
      dim "Open a new terminal to use the flutter command"
    fi
  fi
}
