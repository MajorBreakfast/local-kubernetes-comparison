# Private Registries

## Creating an image pull secret

```sh
kubectl create secret docker-registry regcred \
--namespace gcp-auth \
--docker-server europe-docker.pkg.dev \
--docker-username oauth2accesstoken \
--docker-password $(gcloud auth print-access-token) \
--docker-email none
```

## GCP Auth for Minikube

```sh
minikube start --addons=gcp-auth
```

## GCP Auth for Docker/Rancher Desktop

Run `install-gcp-auth.sh`.

## K3D

```sh
k3d cluster create --config - <<EOF
apiVersion: k3d.io/v1alpha4
kind: Simple
registries:
  config: |
    configs:
      europe-docker.pkg.dev:
        auth:
          username: oauth2accesstoken
          password: $(gcloud auth print-access-token)
EOF
```
