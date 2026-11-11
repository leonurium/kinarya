#!/usr/bin/env bash

USB_ENTRIES=()

is_xcode_xip(){ [[ $(basename "$1") == Xcode*.xip ]]; }
is_simulator_dmg(){ [[ $(basename "$1") == *Simulator* && $(basename "$1") == *.dmg ]]; }

scan_usb_software(){
  local dir=$1
  USB_ENTRIES=()
  while IFS= read -r f; do
    if [[ -n $f ]]; then USB_ENTRIES+=("$f"); fi
  done < <(find "$dir" -mindepth 1 -maxdepth 1 ! -name '.*' | sort)
}

print_usb_entries(){
  local i=1 e
  for e in "${USB_ENTRIES[@]}"; do
    printf '  %2d) %-44s %8s\n' "$i" "$(basename "$e")" "$(human_size "$e")"
    i=$((i+1))
  done
}

module_software(){
  validate_macos_dir || return 1
  resolve_paths
  scan_usb_software "$MACOS_DIR"

  if [[ ${#USB_ENTRIES[@]} -eq 0 ]]; then
    warn "No software found in $MACOS_DIR"
    return 0
  fi

  header "Software on USB — $MACOS_DIR"
  print_usb_entries
  printf '\nSelect items to copy & install.\n'
  printf '  examples: "1 3 5"   "1-4"   "a" (all)\n'
  printf '  Xcode .xip and simulator .dmg are copied here and installed by the Xcode step.\n'
  printf 'Selection: '
  local selection=""
  read -r selection || true

  local -a sel=()
  local idx
  while IFS= read -r idx; do if [[ -n $idx ]]; then sel+=("$idx"); fi; done < <(parse_selection "$selection" "${#USB_ENTRIES[@]}")

  if [[ ${#sel[@]} -eq 0 ]]; then warn "Nothing selected"; return 0; fi

  ensure_dir "$SOFTWARE_DEST"
  local src name
  for idx in "${sel[@]}"; do
    src="${USB_ENTRIES[$((idx-1))]}"
    info "Copying $(basename "$src") → $SOFTWARE_DEST"
    run_cmd ditto "$src" "$SOFTWARE_DEST/$(basename "$src")"
  done
  ok "Copied ${#sel[@]} item(s) to $SOFTWARE_DEST"

  header "Install selected software"
  for idx in "${sel[@]}"; do
    src="$SOFTWARE_DEST/$(basename "${USB_ENTRIES[$((idx-1))]}")"
    name=$(basename "$src")
    if is_xcode_xip "$name" || is_simulator_dmg "$name"; then
      dim "skip install: $name (handled by the Xcode step)"
      continue
    fi
    if confirm "Install $name?" y; then
      install_item "$src" || warn "Install failed: $name"
    else
      dim "skipped $name"
    fi
  done
}
