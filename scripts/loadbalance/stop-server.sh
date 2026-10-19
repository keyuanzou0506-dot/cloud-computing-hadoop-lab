#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
[ "$#" -eq 1 ] || { echo "Usage: bash scripts/loadbalance/stop-server.sh A|B|C"; exit 1; }
port_for "$1" >/dev/null
stop_process "server-$1" "backend.py --name $1"
