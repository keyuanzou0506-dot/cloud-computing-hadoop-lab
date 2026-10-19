#!/usr/bin/env bash
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LB_RUNTIME="$HOME/.cloud-lab-loadbalance"
mkdir -p "$LB_RUNTIME"
port_for() { case "$1" in A) echo 8101;; B) echo 8102;; C) echo 8103;; *) echo "Use A, B or C" >&2; return 1;; esac; }
running_pid() {
 local name="$1" marker="$2" pid=""
 [ -f "$LB_RUNTIME/$name.pid" ] || return 1
 pid="$(cat "$LB_RUNTIME/$name.pid")"
 [[ "$pid" =~ ^[0-9]+$ ]] || return 1
 kill -0 "$pid" 2>/dev/null || return 1
 ps -p "$pid" -o args= 2>/dev/null | grep -Fq "$marker" || return 1
 echo "$pid"
}
wait_http() {
 local url="$1"
 for i in $(seq 1 20); do
  if curl -fsS --max-time 2 -o /dev/null "$url" 2>/dev/null; then return 0; fi
  sleep 0.3
 done
 echo "ERROR: service did not respond at $url" >&2; return 1
}
start_backend() {
 local name="$1" port pid
 port="$(port_for "$name")"
 if pid="$(running_pid "server-$name" "backend.py --name $name")"; then
  echo "Server $name already running ($pid)"
 else
  nohup python3 -u "$ROOT/scripts/loadbalance/backend.py" --name "$name" --port "$port" > "$LB_RUNTIME/server-$name.log" 2>&1 < /dev/null &
  echo "$!" > "$LB_RUNTIME/server-$name.pid"
 fi
 wait_http "http://127.0.0.1:$port/health"
 echo "Server $name ready on $port"
}
stop_process() {
 local name="$1" marker="$2" pid
 if pid="$(running_pid "$name" "$marker")"; then
  kill "$pid" 2>/dev/null || true
  echo "Stopped $name"
 else echo "$name not running"; fi
 rm -f "$LB_RUNTIME/$name.pid"
}
