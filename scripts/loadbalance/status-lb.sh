#!/usr/bin/env bash
set -euo pipefail
for item in "balancer:8080" "server-A:8101" "server-B:8102" "server-C:8103"; do
 name="${item%%:*}"; port="${item##*:}"
 if curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/health" 2>/dev/null; then echo "$name ($port): UP"; else echo "$name ($port): DOWN"; fi
done
