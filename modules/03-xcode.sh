#!/usr/bin/env bash

EXPAND_DIR=""
LAST_XCODE_APP=""

xcode_version(){
  local n; n=$(basename "$1")
  n=${n#Xcode_}
  n=${n%.xip}
  n=${n%%_*}
  printf '%s\n' "$n"
}

expand_xip(){
  local xip=$1 stage
  stage=$(mktemp -d "${TMPDIR:-/tmp}/kinarya-xip.XXXXXX") || return 1
  EXPAND_DIR="$stage"
  if [[ $DRY_RUN == true ]]; then
    dim "[dry-run] xip --expand $(basename "$xip")"
    return 0
  fi
  info "Expanding $(basename "$xip") — this can take several minutes"
  if ! ( cd "$stage" && xip --expand "$xip" ); then
    err "xip failed for $(basename "$xip")"
    rm -rf "$stage"
    return 1
  fi
}

ensure_clt(){
  if pkgutil --pkg-info=com.apple.pkg.CLTools_Executables >/dev/null 2>&1; then
    ok "Command Line Tools installed"
    return 0
  fi
  warn "Command Line Tools not detected"
  if confirm "Run 'xcode-select --install' now? (a macOS dialog will appear)" y; then
    run_cmd xcode-select --install || true
    info "Complete the dialog, then return here"
    pause
  fi
}

select_xcode(){
  local app=$1
  [[ -d $app ]] || { warn "Xcode not found at $app"; return 1; }
  if [[ "$(xcode-select -p 2>/dev/null || true)" == "$app/Contents/Developer" ]]; then
    ok "xcode-select already points to $app"
    return 0
  fi
  need_sudo || return 1
  run_cmd sudo xcode-select -s "$app"
  ok "xcode-select → $app"
}

install_one_xcode(){
  local xip=$1 ver app built
  ver=$(xcode_version "$xip")
  app="/Applications/Xcode_${ver}.app"

  confirm "Install $(basename "$xip") as $app?" y || return 0

  ensure_dir "$SOFTWARE_DEST"
  run_cmd ditto "$xip" "$SOFTWARE_DEST/$(basename "$xip")"

  expand_xip "$SOFTWARE_DEST/$(basename "$xip")" || return 1

  if [[ $DRY_RUN == true ]]; then
    dim "[dry-run] move Xcode.app → $app"
    LAST_XCODE_APP="$app"
    return 0
  fi

  built=$(find "$EXPAND_DIR" -maxdepth 1 -name '*.app' -print -quit 2>/dev/null || true)
  if [[ -z $built ]]; then err "No .app produced from $(basename "$xip")"; return 1; fi

  need_sudo || return 1
  if [[ -d $app ]]; then
    if confirm "$app exists. Replace it?" n; then run_cmd sudo rm -rf "$app"; else dim "keeping existing $app"; rm -rf "$EXPAND_DIR" 2>/dev/null || true; return 0; fi
  fi
  run_cmd sudo mv "$built" "$app"
  ok "Installed $app"
  LAST_XCODE_APP="$app"
  rm -rf "$EXPAND_DIR" 2>/dev/null || true
}

module_xcode(){
  validate_macos_dir || return 1
  resolve_paths

  local -a xips=()
  local f i=1
  while IFS= read -r f; do if [[ -n $f ]]; then xips+=("$f"); fi; done < <(find "$MACOS_DIR" -maxdepth 1 -iname 'Xcode*.xip' ! -name '._*' | sort)

  if [[ ${#xips[@]} -eq 0 ]]; then
    warn "No Xcode*.xip found in $MACOS_DIR"
  else
    header "Xcode archives on USB"
    for f in "${xips[@]}"; do
      printf '  %2d) %-44s %8s\n' "$i" "$(basename "$f")" "$(human_size "$f")"
      i=$((i+1))
    done
    printf 'Select Xcode version(s): '
    local sel=""; read -r sel || true
    local idx
    for idx in $(parse_selection "$sel" "${#xips[@]}"); do
      install_one_xcode "${xips[$((idx-1))]}" || warn "Xcode install failed for item $idx"
    done
  fi

  ensure_clt

  local target="$LAST_XCODE_APP"
  if [[ -z $target ]]; then
    target=$(ls -d /Applications/Xcode*.app 2>/dev/null | sort -V | tail -1 || true)
  fi
  if [[ -n $target ]]; then
    select_xcode "$target" || true
    need_sudo || true
    run_cmd sudo xcodebuild -license accept || true
    run_cmd sudo xcodebuild -runFirstLaunch || true
  else
    warn "No Xcode app in /Applications; skipping xcode-select / license"
  fi

  local -a sims=()
  i=1
  while IFS= read -r f; do if [[ -n $f ]]; then sims+=("$f"); fi; done < <(find "$MACOS_DIR" -maxdepth 1 -iname '*Simulator*.dmg' ! -name '._*' | sort)

  if [[ ${#sims[@]} -eq 0 ]]; then
    info "No simulator .dmg found"
    return 0
  fi

  header "Simulator runtimes"
  for f in "${sims[@]}"; do
    printf '  %2d) %-44s %8s\n' "$i" "$(basename "$f")" "$(human_size "$f")"
    i=$((i+1))
  done
  printf 'Select simulator runtime(s): '
  local ssel=""; read -r ssel || true
  local idx
  for idx in $(parse_selection "$ssel" "${#sims[@]}"); do
    f="${sims[$((idx-1))]}"
    confirm "Add $(basename "$f") as a simulator runtime?" y || continue
    ensure_dir "$SOFTWARE_DEST"
    run_cmd ditto "$f" "$SOFTWARE_DEST/$(basename "$f")"
    require_cmd xcrun || continue
    run_cmd xcrun simctl runtime add "$SOFTWARE_DEST/$(basename "$f")" || warn "simctl add failed for $(basename "$f")"
  done
}
