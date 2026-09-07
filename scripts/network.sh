#!/usr/bin/env bash
set -euo pipefail

if ! command -v nmcli >/dev/null 2>&1 || ! command -v ip >/dev/null 2>&1; then
  printf '|--|--\n'
  exit 0
fi

device=$(nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null \
  | awk -F: '$2 == "wifi" && $3 == "connected" { print $1; exit }')

if [[ -z "$device" ]]; then
  printf '|--|--\n'
  exit 0
fi

ssid=$(nmcli -t -g GENERAL.CONNECTION device show "$device" 2>/dev/null | head -n 1)
signal=$(nmcli -t -f IN-USE,SIGNAL device wifi 2>/dev/null \
  | awk -F: '$1 == "*" { print $2; exit }')
address=$(ip -4 -o addr show dev "$device" scope global 2>/dev/null \
  | awk '{ sub(/\/.*/, "", $4); print $4; exit }')

printf '%s|%s|%s\n' "${ssid:-}" "${signal:---}" "${address:---}"
