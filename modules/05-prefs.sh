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

prune_dock_items(){
  local dom=com.apple.dock
  local plist="$HOME/Library/Preferences/$dom.plist"
  if [[ $DRY_RUN != true && -f $plist ]]; then
    ensure_dir "$BACKUP_DIR"
    cp "$plist" "$BACKUP_DIR/com.apple.dock.$(date +%Y%m%d-%H%M%S).plist" 2>/dev/null || true
  fi
  if ! confirm "Reset Dock icons to: Finder, Apps, System Settings, Downloads, Trash?" y; then
    dim "kept existing Dock icons"
    return 0
  fi
  run_cmd defaults write "$dom" persistent-apps -array
  run_cmd defaults write "$dom" persistent-apps -array-add '{ "tile-type" = "file-tile"; "tile-data" = { "dock-extra" = 1; "file-data" = { "_CFURLString" = "file:///System/Applications/Apps.app/"; "_CFURLStringType" = 15; }; }; }'
  run_cmd defaults write "$dom" persistent-apps -array-add '{ "tile-type" = "file-tile"; "tile-data" = { "dock-extra" = 1; "file-data" = { "_CFURLString" = "file:///System/Applications/System%20Settings.app/"; "_CFURLStringType" = 15; }; }; }'
  run_cmd defaults write "$dom" persistent-others -array
  run_cmd defaults write "$dom" persistent-others -array-add "{ \"tile-type\" = \"directory-tile\"; \"tile-data\" = { \"file-data\" = { \"_CFURLString\" = \"file://$HOME/Downloads/\"; \"_CFURLStringType\" = 15; }; \"preferreditemsize\" = \"-1\"; \"showas\" = 1; }; }"
  ok "Dock icons reset"
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
  pref_trackpad
  pref_clock
  pref_battery
  dim "Announce the time has no reliable CLI on modern macOS — see the Finalize checklist."
}
