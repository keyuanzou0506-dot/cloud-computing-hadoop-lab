#!/usr/bin/env bash
set -euo pipefail
mode="${1:-normal}"
case "$mode" in normal|failover|recovered) ;; *) echo "Usage: bash scripts/loadbalance/test-lb.sh [normal|failover|recovered]"; exit 1;; esac
result=""
for i in 1 2 3 4 5 6; do
 response="$(curl -fsS --max-time 3 http://127.0.0.1:8080/)"
 echo "Request $i: $response"
 result="$result $response"
done
case "$mode" in
 normal|recovered)
  for name in A B C; do [[ "$result" == *"Server $name"* ]] || { echo "FAIL: missing $name"; exit 1; }; done ;;
 failover)
  [[ "$result" != *"Server B"* ]] || { echo "FAIL: server B still served"; exit 1; }
  for name in A C; do [[ "$result" == *"Server $name"* ]] || { echo "FAIL: missing $name"; exit 1; }; done ;;
esac
echo "PASS: $mode"
