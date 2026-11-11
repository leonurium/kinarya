#!/usr/bin/env bash

copy_tree_if(){
  local label=$1 src=$2 dst=$3
  if [[ -z $src || ! -d $src ]]; then
    warn "$label source not found: ${src:-<unset>}"
    return 0
  fi
  if ! confirm "Copy $label → $dst ?" y; then
    dim "skipped $label"
    return 0
  fi
  ensure_dir "$(dirname "$dst")"
  run_cmd ditto "$src" "$dst"
  ok "$label copied to $dst"
}

module_workspaces(){
  resolve_paths
  copy_tree_if "Archive" "$ARCHIVE_SRC" "$ARCHIVE_DEST"
  copy_tree_if "Document" "$DOCUMENT_SRC" "$DOCUMENT_DEST"
  copy_tree_if "project" "$PROJECT_SRC" "$PROJECT_DEST"
  info "Finder sidebar: add $PROJECT_DEST below Downloads manually (see the Finalize step)."
}
