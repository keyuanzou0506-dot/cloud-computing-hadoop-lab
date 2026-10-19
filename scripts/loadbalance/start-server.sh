#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
[ "$#" -eq 1 ] || { echo "Usage: bash scripts/loadbalance/start-server.sh A|B|C"; exit 1; }
start_backend "$1"
