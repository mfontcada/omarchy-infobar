#!/usr/bin/env bash
# Validate omarchy-infobar locally, or install this working tree into Omarchy for live
# testing. The default mode does not modify the user's configuration.

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROJECT_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)
PLUGIN_ID="omarchy-infobar"
PLUGIN_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/$PLUGIN_ID"

usage() {
  cat <<'EOF'
Usage: test-local.sh [--install|--remove]

Without an option, validate the manifest, collector, and collector output.

  --install  Link this working tree, enable the plugin, and restart the shell.
  --remove   Disable the plugin, remove the test symlink, and restart the shell.
EOF
}

validate() {
  command -v omarchy >/dev/null 2>&1 || {
    echo "error: omarchy is not available in PATH" >&2
    exit 1
  }
  command -v jq >/dev/null 2>&1 || {
    echo "error: jq is required for manifest validation" >&2
    exit 1
  }

  jq empty "$PROJECT_DIR/manifest.json"
  bash -n "$PROJECT_DIR/scripts/sysinfo.sh"
  omarchy plugin validate "$PROJECT_DIR"

  local output field_count
  output=$(bash "$PROJECT_DIR/scripts/sysinfo.sh")
  IFS='|' read -r -a fields <<< "$output"
  field_count=${#fields[@]}
  if [[ "$field_count" -ne 6 ]]; then
    echo "error: expected 6 collector fields, got $field_count" >&2
    echo "output: $output" >&2
    exit 1
  fi

  echo "OK: manifest, shell syntax, and collector output validated"
  echo "collector: $output"
}

install_local() {
  validate
  mkdir -p "$(dirname -- "$PLUGIN_DIR")"

  if [[ -e "$PLUGIN_DIR" || -L "$PLUGIN_DIR" ]]; then
    if [[ "$(readlink -f -- "$PLUGIN_DIR" 2>/dev/null || true)" != "$PROJECT_DIR" ]]; then
      echo "error: $PLUGIN_DIR already exists and is not this working tree" >&2
      echo "remove it or choose a different test directory before installing" >&2
      exit 1
    fi
  else
    ln -s "$PROJECT_DIR" "$PLUGIN_DIR"
  fi

  omarchy-shell shell rescanPlugins
  omarchy plugin enable "$PLUGIN_ID"
  omarchy restart shell
  echo "OK: local omarchy-infobar linked at $PLUGIN_DIR and enabled"
}

remove_local() {
  if [[ -L "$PLUGIN_DIR" ]] && [[ "$(readlink -f -- "$PLUGIN_DIR")" == "$PROJECT_DIR" ]]; then
    omarchy plugin disable "$PLUGIN_ID" || true
    rm "$PLUGIN_DIR"
    omarchy restart shell
    echo "OK: local omarchy-infobar test link removed"
  elif [[ -e "$PLUGIN_DIR" ]]; then
    echo "error: refusing to remove non-symlink $PLUGIN_DIR" >&2
    exit 1
  else
    echo "Nothing to remove: $PLUGIN_DIR does not exist"
  fi
}

case "${1:-}" in
  "") validate ;;
  --install) install_local ;;
  --remove) remove_local ;;
  -h|--help) usage ;;
  *) usage >&2; exit 2 ;;
esac
