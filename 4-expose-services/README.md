# 4 Expose services

## Docker and Rancher Desktop

Support load balancer: `kubectl apply -f podinfo-loadbalancer.yaml`

## K3D

```sh
k3d cluster create --port "80:80" --k3s-arg "--disable=traefik@servers:*"
```

`kubectl apply -f podinfo-loadbalancer.yaml`
