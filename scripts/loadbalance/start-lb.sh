#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
command -v python3 >/dev/null
command -v curl >/dev/null
start_backend A
start_backend B
start_backend C
pid=""
if pid="$(running_pid balancer "balancer.py")"; then
 echo "Balancer already running ($pid)"
else
 nohup python3 -u "$ROOT/scripts/loadbalance/balancer.py" > "$LB_RUNTIME/balancer.log" 2>&1 < /dev/null &
 echo "$!" > "$LB_RUNTIME/balancer.pid"
fi
wait_http "http://127.0.0.1:8080/health"
echo "Balancer ready on 8080"
