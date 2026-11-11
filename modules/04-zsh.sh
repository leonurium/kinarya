#!/usr/bin/env bash

OMZ_DIR="$HOME/.oh-my-zsh"
P10K_REPO="https://github.com/romkatv/powerlevel10k.git"

ensure_omz_init(){
  local file="$HOME/.zshrc"
  if [[ $DRY_RUN == true ]]; then dim "[dry-run] ensure Oh My Zsh init in $file"; return 0; fi
  [[ -f $file ]] || : > "$file"
  if ! grep -qF 'oh-my-zsh.sh' "$file" 2>/dev/null; then
    {
      printf '\nexport ZSH="$HOME/.oh-my-zsh"\n'
      printf 'ZSH_THEME="powerlevel10k/powerlevel10k"\n'
      printf 'plugins=(git)\n'
      printf 'source "$ZSH/oh-my-zsh.sh"\n'
    } >> "$file"
    ok "Added Oh My Zsh init to $file"
  fi
}

module_zsh(){
  if [[ $DRY_RUN != true ]]; then
    require_cmd git || { warn "git required (run the Xcode step first)"; return 1; }
    require_cmd curl || { warn "curl required"; return 1; }
  fi

  if [[ -d $OMZ_DIR ]]; then
    ok "Oh My Zsh already installed"
  else
    info "Installing Oh My Zsh"
    if [[ $DRY_RUN == true ]]; then
      dim "[dry-run] install Oh My Zsh"
    elif ! RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"; then
      err "Oh My Zsh installation failed"
      return 1
    fi
  fi

  local custom="${ZSH_CUSTOM:-$OMZ_DIR/custom}"
  local p10k="$custom/themes/powerlevel10k"

  if [[ -d $p10k/.git ]]; then
    ok "powerlevel10k already cloned"
  else
    info "Cloning powerlevel10k theme"
    ensure_dir "$(dirname "$p10k")"
    run_cmd git clone --depth=1 "$P10K_REPO" "$p10k"
  fi

  ensure_omz_init
  replace_or_append_line "$HOME/.zshrc" '^[[:space:]]*ZSH_THEME=' 'ZSH_THEME="powerlevel10k/powerlevel10k"'

  local preset="${KINARYA_P10K:-rainbow}"
  if [[ $preset == none ]]; then
    info "Powerlevel10k: leaving ~/.p10k.zsh unset so 'p10k configure' can run"
    dim "Pick the Rainbow style + ASCII character set in the wizard for a no-font rainbow prompt."
  else
    local presetfile="$p10k/config/p10k-$preset.zsh"
    if [[ -f $presetfile ]]; then
      if [[ -f $HOME/.p10k.zsh ]]; then
        if confirm "Replace existing ~/.p10k.zsh with the '$preset' preset?" y; then
          run_cmd cp "$presetfile" "$HOME/.p10k.zsh"
          ok "Powerlevel10k '$preset' config installed"
        else
          dim "kept existing ~/.p10k.zsh"
        fi
      else
        run_cmd cp "$presetfile" "$HOME/.p10k.zsh"
        ok "Powerlevel10k '$preset' config installed (~/.p10k.zsh)"
      fi
    elif [[ $DRY_RUN == true ]]; then
      dim "[dry-run] copy '$preset' preset → ~/.p10k.zsh"
    else
      warn "Preset 'p10k-$preset.zsh' not found in the theme checkout"
    fi
  fi

  info "Open a new terminal (or run 'exec zsh') to load the new prompt."
  case "$preset" in
    none|pure|robbyrussell) : ;;
    *) dim "Rainbow/Lean styles use Nerd Font icons — install MesloLGS NF (see Finalize)." ;;
  esac
}
