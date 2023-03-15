#!/usr/bin/env bash
set -Eeuo pipefail

iterations="${1:-5}"
k3d_cluster_name="k3s-default"
ports=("80:30080")
proxied_registries=("docker.io" "ghcr.io" "k8s.gcr.io")

source $(dirname $0)/helpers.sh

if k3d cluster get "${k3d_cluster_name}" &> /dev/null; then
  echo "Error: Cluster ${k3d_cluster_name} already exists"
  exit 1
fi

if [ -f benchmark-k3d-result.csv ]; then
  echo "File benchmark-k3d-result.csv already exists."
  exit 1
fi

echo "iteration,duration_deleted_old_cluster,duration_created_new_cluster,duration_workload_responding" >> benchmark-k3d-result.csv

for ((i=0; i<=$iterations; i++)); do

timestamp_start=$(date +%s)
duration_deleted_old_cluster=""
duration_created_new_cluster=""
duration_workload_responding=""

# =================================================================
# Delete old cluster
# =================================================================

if k3d cluster get "${k3d_cluster_name}" &> /dev/null; then
  k3d cluster delete "${k3d_cluster_name}"

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
# Network connnection between registries and cluster
# =================================================================

# Create network with registries before cluster because k3d uses it to configure CoreDNS
docker_network_create_if_needed "k3d-${k3d_cluster_name}"

for registry in "${proxied_registries[@]}"; do
  docker_network_connect_if_needed  "k3d-${k3d_cluster_name}" "registry-proxy-${registry}"
done

# =================================================================
# Create k3d Cluster
# =================================================================

k3d cluster create --config - <<EOF
apiVersion: k3d.io/v1alpha4
kind: Simple
metadata:
  name: ${k3d_cluster_name}
ports:
  $(for port in "${ports[@]}"; do echo "
  - port: ${port}
    nodeFilters: [server:0:direct]
  "; done;)
registries:
  config: |
    mirrors:
      $(for registry in "${proxied_registries[@]}"; do echo "
      '${registry}': { endpoint: ['http://registry-proxy-${registry}:5000'] }
      "; done;)
options:
  k3d:
    disableLoadbalancer: true
  k3s:
    extraArgs:
      - { arg: '--disable=traefik,metrics-server', nodeFilters: [server:*] }
EOF

duration_created_new_cluster="$(($(date +%s) - timestamp_start))"
echo "🕐 Cluster created after ${duration_created_new_cluster} seconds"

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

echo "$i,$duration_deleted_old_cluster,$duration_created_new_cluster,$duration_workload_responding" >> benchmark-k3d-result.csv

done

k3d cluster delete "${k3d_cluster_name}"
average_benchmark_csv benchmark-k3d-result.csv benchmark-k3d-result-averaged.csv
