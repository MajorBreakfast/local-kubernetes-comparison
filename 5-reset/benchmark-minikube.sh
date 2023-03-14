#!/usr/bin/env bash
set -Eeuo pipefail

iterations="${1:-5}"
minikube_cluster_name="minikube"
ports=("80:30080")
proxied_registries=("docker.io" "ghcr.io" "k8s.gcr.io")

source $(dirname $0)/docker-helpers.sh

if minikube status -p "${minikube_cluster_name}" | grep -q "Running"; then
  echo "Error: Cluster ${minikube_cluster_name} already exists"
fi

echo "iteration,duration_deleted_old_cluster,duration_created_new_cluster,duration_workload_responding" >> benchmark-minikube-result.csv

for ((i=0; i<=$iterations; i++)); do

timestamp_start=$(date +%s)
duration_deleted_old_cluster=""
duration_created_new_cluster=""
duration_workload_responding=""

# =================================================================
# Delete old cluster
# =================================================================

if minikube status -p "${minikube_cluster_name}" | grep -q "Running"; then
  minikube delete -p "${minikube_cluster_name}"

  duration_deleted_old_cluster="$(($(date +%s) - timestamp_start))"
  echo "🕐 Old cluster deleted after ${duration_deleted_old_cluster} seconds"
fi

# =================================================================
# Create Local Registry and Registry Proxies
# =================================================================

docker_run_if_needed -d --name "registry-proxy-docker.io" --restart=always -e REGISTRY_PROXY_REMOTEURL="https://registry-1.docker.io" registry:2

# =================================================================
# Create Minikube Cluster
# =================================================================

minikube start -p "${minikube_cluster_name}" --driver=docker \
    --addons="metrics-server" \
    --registry-mirror="http://registry-proxy-docker.io:5000" \
    --ports="$(IFS=,; echo "${ports[*]}")"

duration_created_new_cluster="$(($(date +%s) - timestamp_start))"
echo "🕐 Cluster created after ${duration_created_new_cluster} seconds"

# =================================================================
# Network connnection between registries and cluster
# =================================================================

docker_network_connect_if_needed "${minikube_cluster_name}" "registry-proxy-docker.io"

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

echo "$i,$duration_deleted_old_cluster,$duration_created_new_cluster,$duration_workload_responding" >> benchmark-minikube-result.csv

done

minikube delete -p "${minikube_cluster_name}"
