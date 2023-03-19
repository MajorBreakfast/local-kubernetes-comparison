# First Cluster

## Docker Desktop

Kubernetes can be enabled in the settings.

## Rancher Desktop

"dockerd" is chosen in the startup screen for later (challenge 2).

## Microk8s

To create cluster:

```
microk8s install
```

Microk8s requires manually editing the kube config:

```
mkdir -p "$HOME/.kube"
microk8s config > "$HOME/.kube/config"
```

## Podman/Podman Desktop

Rootful machine is required to run container-based Kubernetes solutions like Kind.

```
podman machine init --rootful --cpus 2 --memory 4096
```

### Kind

To create cluster:

```
kind create cluster
```

To delete cluster:

```
kind delete cluster
```

### K3D

To create cluster:

```
k3d cluster create
```

To delete cluster:

```
k3d cluster delete
```

### Minikube

To create cluster:

```
minikupe start --driver docker
```

To delete cluster:

```
minikupe stop
```
