#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
stop_process balancer "balancer.py"
for name in A B C; do stop_process "server-$name" "backend.py --name $name"; done
