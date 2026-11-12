#!/usr/bin/env bash

pref_dock(){
  local dom=com.apple.dock
  info "Dock: small size (32px), magnification (72px), auto-hide, bottom"
  run_cmd defaults write "$dom" tilesize -int 32
  run_cmd defaults write "$dom" largesize -int 72
  run_cmd defaults write "$dom" magnification -bool true
  run_cmd defaults write "$dom" autohide -bool true
  run_cmd defaults write "$dom" orientation -string bottom
  prune_dock_items
  run_cmd killall Dock || true
}

dock_filter_array(){
  local file=$1 key=$2 pattern=$3
  local pb=/usr/libexec/PlistBuddy i=0 n=0 url
  $pb -c "Delete :${key}_keep" "$file" >/dev/null 2>&1 || true
  $pb -c "Add :${key}_keep array" "$file" >/dev/null 2>&1 || true
  while $pb -c "Print :$key:$i" "$file" >/dev/null 2>&1; do
    url=$($pb -c "Print :$key:$i:tile-data:file-data:_CFURLString" "$file" 2>/dev/null || true)
    if [[ -n $url ]] && [[ $url =~ $pattern ]]; then
      $pb -c "Copy :$key:$i :${key}_keep:$n" "$file" >/dev/null 2>&1 || true
      n=$((n+1))
    fi
    i=$((i+1))
  done
  $pb -c "Delete :$key" "$file" >/dev/null 2>&1 || true
  $pb -c "Copy :${key}_keep :$key" "$file" >/dev/null 2>&1 || true
  $pb -c "Delete :${key}_keep" "$file" >/dev/null 2>&1 || true
}

prune_dock_items(){
  if ! confirm "Reset Dock icons to: Finder, Apps, System Settings, Downloads, Trash?" y; then
    dim "kept existing Dock icons"
    return 0
  fi
  if [[ $DRY_RUN == true ]]; then
    dim "[dry-run] filter Dock icons (keep Finder, Apps, System Settings, Downloads, Trash)"
    return 0
  fi

  ensure_dir "$BACKUP_DIR"
  defaults export com.apple.dock "$BACKUP_DIR/com.apple.dock.$(date +%Y%m%d-%H%M%S).plist" 2>/dev/null || true

  local tmp; tmp=$(mktemp) || return 1
  if ! defaults export com.apple.dock "$tmp"; then
    err "Could not export the Dock preferences"
    rm -f "$tmp"
    return 1
  fi
  dock_filter_array "$tmp" persistent-apps '(Apps\.app|System Settings\.app|System%20Settings\.app)'
  dock_filter_array "$tmp" persistent-others 'Downloads'
  if ! defaults import com.apple.dock "$tmp"; then
    err "Could not import the pruned Dock preferences"
    rm -f "$tmp"
    return 1
  fi
  rm -f "$tmp"
  ok "Dock icons reset (existing entries kept, bookmarks preserved)"
}

pref_finder(){
  info "Finder: show status bar, path bar and tab bar"
  run_cmd defaults write com.apple.finder ShowStatusBar -bool true
  run_cmd defaults write com.apple.finder ShowPathbar -bool true
  run_cmd defaults write com.apple.finder ShowTabView -bool true
  run_cmd defaults write com.apple.finder AppleWindowTabbingMode -string always
  run_cmd killall Finder 2>/dev/null || true
}

pref_trackpad(){
  info "Trackpad: tap to click"
  run_cmd defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
  run_cmd defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
}

pref_clock(){
  info "Clock: show seconds"
  run_cmd defaults write com.apple.menuextra.clock ShowSeconds -bool true
  run_cmd killall ControlCenter 2>/dev/null || true
  run_cmd killall SystemUIServer 2>/dev/null || true
}

pref_battery(){
  info "Battery: show percentage"
  run_cmd defaults write com.apple.controlcenter BatteryShowPercentage -bool true
  run_cmd defaults -currentHost write com.apple.controlcenter BatteryShowPercentage -bool true
  run_cmd killall ControlCenter 2>/dev/null || true
}

module_prefs(){
  pref_dock
  pref_finder
  pref_trackpad
  pref_clock
  pref_battery
  dim "Announce the time has no reliable CLI on modern macOS — see the Finalize checklist."
}
