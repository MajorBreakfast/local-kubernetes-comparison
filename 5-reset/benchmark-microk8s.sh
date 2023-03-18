#!/usr/bin/env bash
set -Eeuo pipefail

iterations="${1:-5}"

source $(dirname $0)/helpers.sh

if microk8s status | grep -q "microk8s is running"; then
  echo "Error: Cluster already exists"
  exit 1
fi

if [ -f benchmark-microk8s-result.csv ]; then
  echo "File benchmark-microk8s-result.csv already exists."
  exit 1
fi

echo "iteration,duration_deleted_old_cluster,duration_created_new_cluster,duration_workload_responding" >> benchmark-microk8s-result.csv

for ((i=0; i<=$iterations; i++)); do

timestamp_start=$(date +%s)
duration_deleted_old_cluster=""
duration_created_new_cluster=""
duration_workload_responding=""

# =================================================================
# Delete old cluster
# =================================================================

if microk8s status | grep -q "microk8s is running"; then
  microk8s uninstall

  duration_deleted_old_cluster="$(($(date +%s) - timestamp_start))"
  echo "🕐 Old cluster deleted after ${duration_deleted_old_cluster} seconds"
fi

# =================================================================
# Create microk8s Cluster
# =================================================================

microk8s install

duration_created_new_cluster="$(($(date +%s) - timestamp_start))"
echo "🕐 Cluster created after ${duration_created_new_cluster} seconds"

# =================================================================
# Deploy Workload
# =================================================================

microk8s kubectl apply -f $(dirname "$0")/podinfo-nodeport.yaml

# =================================================================
# Wait for service to be reachable
# =================================================================

VM_IP="$(microk8s config | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')"

while true; do
  http_code=$(curl "$VM_IP:30080" --max-time 1 -s -o /dev/null -w "%{http_code}" || true)
  if [ "$http_code" = "200" ]; then
    duration_workload_responding="$(($(date +%s) - timestamp_start))"
    echo "🕐 Service reachable after ${duration_workload_responding} seconds"
    break
  fi
  sleep 1
done

echo "$i,$duration_deleted_old_cluster,$duration_created_new_cluster,$duration_workload_responding" >> benchmark-microk8s-result.csv

done

microk8s cluster delete "${microk8s_cluster_name}"
average_benchmark_csv benchmark-microk8s-result.csv benchmark-microk8s-result-averaged.csv
