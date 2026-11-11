#!/usr/bin/env bash

module_core(){
  if ! have_cmd brew; then
    if [[ $DRY_RUN == true ]]; then dim "[dry-run] brew not installed yet"; return 0; fi
    err "Homebrew is missing — run the Homebrew step first"
    return 1
  fi

  run_cmd brew update

  local pkg
  for pkg in mole node cocoapods; do
    if brew list --formula "$pkg" >/dev/null 2>&1; then
      ok "$pkg already installed"
    else
      info "Installing $pkg"
      run_cmd brew install "$pkg" || { err "Failed to install $pkg"; return 1; }
    fi
  done
}
