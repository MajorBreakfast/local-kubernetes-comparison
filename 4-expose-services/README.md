# 4 Expose services

## Load Balancer: Docker and Rancher Desktop

`kubectl apply -f podinfo-loadbalancer.yaml`

## Load Balancer: K3D

```sh
k3d cluster create --port 80:80 --k3s-arg '--disable=traefik@servers:*'
```

`kubectl apply -f podinfo-loadbalancer.yaml`

## Load Balancer: Minikube (tunnel)

## Node Port: Kind

```sh
kind create cluster --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - hostPort: 80
        containerPort: 30080
EOF
```
