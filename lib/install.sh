#!/usr/bin/env bash

find_first_app(){ find "$1" -maxdepth 3 -name '*.app' -print -quit 2>/dev/null || true; }
find_first_pkg(){ find "$1" -maxdepth 3 -name '*.pkg' -print -quit 2>/dev/null || true; }

install_item(){
  local f=$1
  case "$f" in
    *.pkg) install_pkg "$f" ;;
    *.dmg) install_dmg "$f" ;;
    *.zip) install_zip "$f" ;;
    *.xip) warn "Xcode .xip archives are handled by the Xcode step" ;;
    *.app) install_app "$f" ;;
    *) warn "Unsupported installer: $(basename "$f")" ;;
  esac
}

install_pkg(){
  need_sudo || return 1
  info "Installing package $(basename "$1")"
  run_cmd sudo installer -pkg "$1" -target /
}

install_app(){
  local src=$1 name dest
  name=$(basename "$src")
  dest="/Applications/$name"
  if [[ -d $dest ]]; then
    if confirm "$name already exists in /Applications. Replace it?" n; then
      need_sudo || return 1
      run_cmd sudo rm -rf "$dest"
    else
      dim "keeping existing $name"
      return 0
    fi
  fi
  need_sudo || return 1
  info "Copying $name → /Applications"
  run_cmd sudo ditto "$src" "$dest"
}

install_dmg(){
  local dmg=$1 mnt app pkg
  if [[ $DRY_RUN == true ]]; then dim "[dry-run] mount + install $(basename "$dmg")"; return 0; fi
  mnt=$(mktemp -d "${TMPDIR:-/tmp}/kinarya-dmg.XXXXXX") || return 1
  info "Mounting $(basename "$dmg")"
  if ! hdiutil attach "$dmg" -nobrowse -mountpoint "$mnt" >/dev/null; then
    err "Failed to mount $(basename "$dmg")"
    rmdir "$mnt" 2>/dev/null || true
    return 1
  fi
  app=$(find_first_app "$mnt")
  pkg=$(find_first_pkg "$mnt")
  if [[ -n $app ]]; then install_app "$app"
  elif [[ -n $pkg ]]; then install_pkg "$pkg"
  else warn "No .app or .pkg inside $(basename "$dmg")"; fi
  hdiutil detach "$mnt" >/dev/null 2>&1 || { sleep 1; hdiutil detach "$mnt" -force >/dev/null 2>&1 || true; }
  rmdir "$mnt" 2>/dev/null || true
}

install_zip(){
  local zip=$1 stage app
  if [[ $DRY_RUN == true ]]; then dim "[dry-run] unzip + install $(basename "$zip")"; return 0; fi
  stage=$(mktemp -d "${TMPDIR:-/tmp}/kinarya-zip.XXXXXX") || return 1
  info "Extracting $(basename "$zip")"
  if ! ditto -x -k "$zip" "$stage"; then err "Extraction failed"; rm -rf "$stage"; return 1; fi
  app=$(find_first_app "$stage")
  if [[ -n $app ]]; then install_app "$app"; else warn "No .app inside $(basename "$zip")"; fi
  rm -rf "$stage" 2>/dev/null || true
}
