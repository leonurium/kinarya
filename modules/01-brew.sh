#!/usr/bin/env bash

module_brew(){
  if ! have_cmd brew; then
    if [[ $DRY_RUN == true ]]; then
      dim "[dry-run] install Homebrew"
    else
      info "Installing Homebrew (you may be asked for your password)"
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
  else
    ok "Homebrew present: $(brew --version | head -1)"
  fi

  local prefix=""
  if [[ -x /opt/homebrew/bin/brew ]]; then prefix=/opt/homebrew
  elif [[ -x /usr/local/bin/brew ]]; then prefix=/usr/local
  fi

  if [[ -z $prefix ]]; then
    warn "brew binary not found after install; open a new terminal and re-run"
    return 0
  fi

  eval "$($prefix/bin/brew shellenv)"

  if grep -qF "$prefix/bin/brew shellenv" "$HOME/.zprofile" 2>/dev/null; then
    ok "brew shellenv already in ~/.zprofile"
  else
    append_line "$HOME/.zprofile" "eval \"\$($prefix/bin/brew shellenv)\""
    ok "Added brew shellenv to ~/.zprofile"
  fi
}
