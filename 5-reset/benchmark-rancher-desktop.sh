#!/usr/bin/env bash
set -Eeuo pipefail

iterations="${1:-5}"
kube_context="${2:-rancher-desktop}"

source $(dirname $0)/helpers.sh

kubectl config use-context "${kube_context}"

if [ -f benchmark-${kube_context}-result.csv ]; then
  echo "File benchmark-${kube_context}-result.csv already exists."
  exit 1
fi

echo "iteration,duration_deleted_old_cluster,duration_created_new_cluster,duration_workload_responding" >> benchmark-${kube_context}-result.csv

for ((i=0; i<=$iterations; i++)); do

echo '
 ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄    ▄▄▄▄▄▄   ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄  ▄▄   ▄▄
█       █       █       █  █   ▄  █ █       █       █      ██  █ █  █
█   ▄▄▄▄█    ▄▄▄█▄     ▄█  █  █ █ █ █    ▄▄▄█   ▄   █  ▄    █  █▄█  █
█  █  ▄▄█   █▄▄▄  █   █    █   █▄▄█▄█   █▄▄▄█  █▄█  █ █ █   █       █
█  █ █  █    ▄▄▄█ █   █    █    ▄▄  █    ▄▄▄█       █ █▄█   █▄     ▄█
█  █▄▄█ █   █▄▄▄  █   █    █   █  █ █   █▄▄▄█   ▄   █       █ █   █
█▄▄▄▄▄▄▄█▄▄▄▄▄▄▄█ █▄▄▄█    █▄▄▄█  █▄█▄▄▄▄▄▄▄█▄▄█ █▄▄█▄▄▄▄▄▄█  █▄▄▄█
'
sleep 3
echo '
 ▄▄▄▄▄▄▄
█       █
█▄▄▄    █
 ▄▄▄█   █
█▄▄▄    █
 ▄▄▄█   █
█▄▄▄▄▄▄▄█
'
sleep 1
echo '
 ▄▄▄▄▄▄▄
█       █
█▄▄▄▄   █
 ▄▄▄▄█  █
█ ▄▄▄▄▄▄█
█ █▄▄▄▄▄
█▄▄▄▄▄▄▄█
'
sleep 1
echo '
 ▄▄▄▄
█    █
 █   █
 █   █
 █   █
 █   █
 █▄▄▄█
'
sleep 1
echo '
 ▄▄▄▄▄▄   ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄
█   ▄  █ █       █       █       █       █  █
█  █ █ █ █    ▄▄▄█  ▄▄▄▄▄█    ▄▄▄█▄     ▄█  █
█   █▄▄█▄█   █▄▄▄█ █▄▄▄▄▄█   █▄▄▄  █   █ █  █
█    ▄▄  █    ▄▄▄█▄▄▄▄▄  █    ▄▄▄█ █   █ █▄▄█
█   █  █ █   █▄▄▄ ▄▄▄▄▄█ █   █▄▄▄  █   █  ▄▄
█▄▄▄█  █▄█▄▄▄▄▄▄▄█▄▄▄▄▄▄▄█▄▄▄▄▄▄▄█ █▄▄▄█ █▄▄█
'

timestamp_start=$(date +%s)
duration_deleted_old_cluster="0"
duration_created_new_cluster=""
duration_workload_responding=""

# =================================================================
# Awaiting cluster readiness
# =================================================================

sleep 10
echo "Waiting for cluster to be ready"
while ! kubectl get namespaces 2> /dev/null; do sleep 1; done

duration_created_new_cluster="$(($(date +%s) - timestamp_start))"
echo "🕐 Cluster created after ${duration_created_new_cluster} seconds"

# =================================================================
# Deploy Workload
# =================================================================

kubectl apply -f $(dirname "$0")/podinfo-loadbalancer.yaml

# =================================================================
# Wait for service to be reachable
# =================================================================

while true; do
  http_code=$(curl localhost --max-time 1 -s -o /dev/null -w "%{http_code}" || true)
  if [ "$http_code" = "200" ]; then
    duration_workload_responding="$(($(date +%s) - timestamp_start))"
    echo "🕐 Service reachable after ${duration_workload_responding} seconds"
    break
  fi
  sleep 1
done

echo "$i,$duration_deleted_old_cluster,$duration_created_new_cluster,$duration_workload_responding" >> benchmark-${kube_context}-result.csv

done

average_benchmark_csv benchmark-${kube_context}-result.csv benchmark-${kube_context}-result-averaged.csv
