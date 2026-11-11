#!/usr/bin/env bash

git_identity(){
  if ! have_cmd git; then
    warn "git not found (run the Xcode / Command Line Tools step first)"
    return 0
  fi

  local cur_name cur_email def_name def_email name email
  cur_name=$(git config --global user.name 2>/dev/null || true)
  cur_email=$(git config --global user.email 2>/dev/null || true)
  def_name="$cur_name"
  def_email="$cur_email"

  if have_cmd gh && gh auth status >/dev/null 2>&1; then
    if [[ -z $def_name ]]; then def_name=$(gh api user --jq '.name // .login // empty' 2>/dev/null || true); fi
    if [[ -z $def_email ]]; then def_email=$(gh api user --jq '.email // empty' 2>/dev/null || true); fi
  fi

  info "Git global identity"
  if [[ -n $cur_name ]]; then dim "current user.name  = $cur_name"; fi
  if [[ -n $cur_email ]]; then dim "current user.email = $cur_email"; fi

  printf 'user.name'
  if [[ -n $def_name ]]; then printf ' [%s]' "$def_name"; fi
  printf ': '
  read -r name || true
  name=${name:-$def_name}

  printf 'user.email'
  if [[ -n $def_email ]]; then printf ' [%s]' "$def_email"; fi
  printf ': '
  read -r email || true
  email=${email:-$def_email}

  if [[ -z $name || -z $email ]]; then
    warn "Skipped git identity (both a name and an email are required)"
    return 0
  fi

  if [[ $name == "$cur_name" && $email == "$cur_email" ]]; then
    ok "git identity unchanged ($name <$email>)"
    return 0
  fi

  if [[ -n $cur_name || -n $cur_email ]]; then
    if ! confirm "Overwrite git global identity with $name <$email>?" y; then
      dim "kept existing git identity"
      return 0
    fi
  fi

  run_cmd git config --global user.name "$name"
  run_cmd git config --global user.email "$email"
  ok "git global identity set: $name <$email>"
}

module_gh(){
  if ! have_cmd gh; then
    if [[ $DRY_RUN == true ]]; then
      dim "[dry-run] brew install gh"
    else
      require_cmd brew || return 1
      info "Installing GitHub CLI"
      run_cmd brew install gh || return 1
    fi
  else
    ok "gh already installed"
  fi

  if have_cmd gh && gh auth status >/dev/null 2>&1; then
    ok "Already signed in to GitHub"
  else
    require_cmd gh || return 1
    info "Starting GitHub browser login…"
    run_cmd gh auth login --hostname github.com --git-protocol https --web
  fi

  git_identity
}
