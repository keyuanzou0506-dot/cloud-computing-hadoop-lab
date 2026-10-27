#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/.devcontainer/lab-output"
mkdir -p "$OUT"
rm -f "$OUT/manifest.tsv" "$OUT"/shot*.txt

source "$HOME/.hadoop_lab_env" 2>/dev/null || true

record() {
  local id="$1"
  local title="$2"
  local command="$3"
  local output="$OUT/shot${id}.txt"
  local command_file="$OUT/shot${id}.cmd"

  printf '%s\n' "$command" > "$command_file"
  {
    printf 'Executed at %s\n\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
    bash -lc "$command"
  } > "$output" 2>&1

  printf '%s\t%s\t%s\t%s\n' "$id" "$title" "$command_file" "$output" >> "$OUT/manifest.tsv"
}

cd "$ROOT"

record 1 "截图1：Java 与 Hadoop 版本" \
  'java -version 2>&1; echo; hadoop version'

record 2 "截图2：Hadoop 进程与单 DataNode 状态" \
  'bash scripts/start-hdfs.sh; sleep 5; echo; jps; echo; hdfs dfsadmin -report | sed -n "1,55p"'

record 3 "截图3：CPU、内存和磁盘资源" \
  'echo "hostname: $(hostname)"; echo; uname -a; echo; echo "CPU count: $(nproc)"; echo; lscpu | sed -n "1,28p"; echo; free -h; echo; df -h .; echo; lsblk'

bash scripts/stop-hdfs.sh >/dev/null 2>&1 || true
bash scripts/multinode/stop-multinode.sh >/dev/null 2>&1 || true
bash scripts/multinode/setup-multinode.sh >/dev/null 2>&1 || true
bash scripts/multinode/start-multinode.sh >/dev/null 2>&1 || true
sleep 8

record 4 "截图4：三个在线 DataNode" \
  'bash scripts/multinode/status-multinode.sh | grep "Live datanodes"; echo; jps -lv | grep -E "NameNode|DataNode"'

record 5 "截图5：HDFS 三副本" \
  '. "$HOME/hadoop-multi/activate.sh"; hdfs dfs -mkdir -p /multilab/input; hdfs dfs -put -f data/hello.txt /multilab/input/; echo; hdfs dfs -ls /multilab/input; echo; hdfs dfs -cat /multilab/input/hello.txt; echo; hdfs fsck /multilab/input/hello.txt -files -blocks -locations'

bash scripts/multinode/stop-one-datanode.sh 2 >/dev/null 2>&1 || true
sleep 18

record 6 "截图6：停止 DataNode2 后仅剩两个在线节点" \
  'bash scripts/multinode/status-multinode.sh | grep "Live datanodes"; echo; jps -lv | grep DataNode'

record 7 "截图7：故障后仍可读取文件" \
  '. "$HOME/hadoop-multi/activate.sh"; hdfs dfs -cat /multilab/input/hello.txt'

bash scripts/multinode/start-one-datanode.sh 2 >/dev/null 2>&1 || true
sleep 8

record 8 "截图8：网络地址、NameNode HTTP 与 DataNode 端口" \
  'hostname -I; echo; curl -I --max-time 5 http://127.0.0.1:9870/; echo; bash scripts/multinode/status-multinode.sh | sed -n "1,35p"'

bash scripts/loadbalance/stop-lb.sh >/dev/null 2>&1 || true
bash scripts/loadbalance/start-lb.sh >/dev/null 2>&1 || true

record 9 "截图9：负载均衡器和三个后端均为 UP" \
  'bash scripts/loadbalance/status-lb.sh'

record 10 "截图10：轮询负载均衡正常" \
  'bash scripts/loadbalance/test-lb.sh normal'

bash scripts/loadbalance/stop-server.sh B >/dev/null 2>&1 || true
sleep 2

record 11 "截图11：Server B 故障后仍可服务" \
  'bash scripts/loadbalance/status-lb.sh; echo; bash scripts/loadbalance/test-lb.sh failover'

bash scripts/loadbalance/start-server.sh B >/dev/null 2>&1 || true
sleep 2

record 12 "截图12：Server B 恢复" \
  'bash scripts/loadbalance/test-lb.sh recovered; echo; bash scripts/loadbalance/status-lb.sh'

python3 "$ROOT/.devcontainer/render-lab-pages.py"

bash scripts/loadbalance/stop-lb.sh >/dev/null 2>&1 || true
bash scripts/multinode/stop-multinode.sh >/dev/null 2>&1 || true
