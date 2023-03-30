#!/usr/bin/env bash
set -Eeuo pipefail

iterations="${1:-5}"
kind_cluster_name="kind"
proxied_registries=("docker.io" "ghcr.io" "k8s.gcr.io")

source $(dirname $0)/helpers.sh

if kind get clusters | grep -w "${kind_cluster_name}" &>/dev/null; then
  echo "Error: Cluster ${kind_cluster_name} already exists"
  exit 1
fi

if [ -f benchmark-kind-result.csv ]; then
  echo "File benchmark-kind-result.csv already exists."
  exit 1
fi

echo "iteration,duration_deleted_old_cluster,duration_created_new_cluster,duration_workload_responding" >> benchmark-kind-result.csv

for ((i=0; i<=$iterations; i++)); do

timestamp_start=$(date +%s)
duration_deleted_old_cluster=""
duration_created_new_cluster=""
duration_workload_responding=""

# =================================================================
# Delete old cluster
# =================================================================

if kind get clusters | grep -w "${kind_cluster_name}" &>/dev/null; then
  kind delete cluster --name "${kind_cluster_name}"

  duration_deleted_old_cluster="$(($(date +%s) - timestamp_start))"
  echo "🕐 Old cluster deleted after ${duration_deleted_old_cluster} seconds"
fi

# =================================================================
# Create Local Registry and Registry Proxies
# =================================================================

for registry in "${proxied_registries[@]}"; do
  docker_run_if_needed -d --name "registry-proxy-${registry}" --restart=always -e REGISTRY_PROXY_REMOTEURL="https://${registry/docker.io/registry-1.docker.io}" registry:2
done

# =================================================================
# Create Kind Cluster
# =================================================================

kind create cluster --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ${kind_cluster_name}
nodes:
  - role: control-plane
    extraPortMappings:
      - hostPort: 80
        containerPort: 30080
containerdConfigPatches:
  $(for registry in "${proxied_registries[@]}"; do echo "
  - |-
    [plugins.'io.containerd.grpc.v1.cri'.registry.mirrors.'${registry}']
      endpoint = ['http://registry-proxy-${registry}:5000']
  "; done;)
EOF

duration_created_new_cluster="$(($(date +%s) - timestamp_start))"
echo "🕐 Cluster created after ${duration_created_new_cluster} seconds"

# =================================================================
# Network connnection between registries and cluster
# =================================================================

for registry in "${proxied_registries[@]}"; do
  docker_network_connect_if_needed  "kind" "registry-proxy-${registry}"
done

# =================================================================
# Deploy Workload
# =================================================================

kubectl apply -f $(dirname "$0")/podinfo-nodeport.yaml

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

echo "$i,$duration_deleted_old_cluster,$duration_created_new_cluster,$duration_workload_responding" >> benchmark-kind-result.csv

done

kind delete cluster --name "${kind_cluster_name}"
average_benchmark_csv benchmark-kind-result.csv benchmark-kind-result-averaged.csv
