# Private Registries

## Creating an image pull secret

```sh
kubectl create secret docker-registry regcred \
--docker-server europe-docker.pkg.dev \
--docker-username oauth2accesstoken \
--docker-password $(gcloud auth print-access-token) \
--docker-email none
```

## GCP Auth for Minikube

```sh
minikube start --addons=gcp-auth
```

Data in Minikube gcp-auth pull secrets:

<!-- prettier-ignore -->
```json
{
  "https://gcr.io": { "username": "oauth2accesstoken", "password": "...", "email": "none" },
  "https://us.gcr.io": { "username": "oauth2accesstoken", "password": "...", "email": "none" },
  "https://eu.gcr.io": { "username": "oauth2accesstoken", "password": "...", "email": "none" },
  "https://asia.gcr.io": { "username": "oauth2accesstoken", "password": "...", "email": "none" },
  "https://marketplace.gcr.io": { "username": "oauth2accesstoken", "password": "...", "email": "none" },
  "https://northamerica-northeast1-docker.pkg.dev": { "username": "oauth2accesstoken", "password": "...", "email": "none" },
  "https://us-central1-docker.pkg.dev": { "username": "oauth2accesstoken", "password": "...", "email": "none" },
  "https://us-east1-docker.pkg.dev": { "username": "oauth2accesstoken", "password": "...", "email": "none" },
  "https://us-east4-docker.pkg.dev": { "username": "oauth2accesstoken", "password": "...", "email": "none" },
  "https://us-west2-docker.pkg.dev": { "username": "oauth2accesstoken", "password": "...", "email": "none" },
  "https://us-west1-docker.pkg.dev": { "username": "oauth2accesstoken", "password": "...", "email": "none" },
  "https://us-west3-docker.pkg.dev": { "username": "oauth2accesstoken", "password": "...", "email": "none" },
  "https://us-west4-docker.pkg.dev": { "username": "oauth2accesstoken", "password": "...", "email": "none" },
  "https://southamerica-east1-docker.pkg.dev": { "username": "oauth2accesstoken", "password": "...", "email": "none" },
  "https://europe-central2-docker.pkg.dev": { "username": "oauth2accesstoken", "password": "...", "email": "none" },
  "https://europe-north1-docker.pkg.dev": { "username": "oauth2accesstoken", "password": "...", "email": "none" },
  "https://europe-west1-docker.pkg.dev": { "username": "oauth2accesstoken", "password": "...", "email": "none" },
  "https://europe-west2-docker.pkg.dev": { "username": "oauth2accesstoken", "password": "...", "email": "none" },
  "https://europe-west3-docker.pkg.dev": { "username": "oauth2accesstoken", "password": "...", "email": "none" },
  "https://europe-west4-docker.pkg.dev": { "username": "oauth2accesstoken", "password": "...", "email": "none" },
  "https://europe-west5-docker.pkg.dev": { "username": "oauth2accesstoken", "password": "...", "email": "none" },
  "https://europe-west6-docker.pkg.dev": { "username": "oauth2accesstoken", "password": "...", "email": "none" },
  "https://asia-east1-docker.pkg.dev": { "username": "oauth2accesstoken", "password": "...", "email": "none" },
  "https://asia-east2-docker.pkg.dev": { "username": "oauth2accesstoken", "password": "...", "email": "none" },
  "https://asia-northeast1-docker.pkg.dev": { "username": "oauth2accesstoken", "password": "...", "email": "none" },
  "https://asia-northeast2-docker.pkg.dev": { "username": "oauth2accesstoken", "password": "...", "email": "none" },
  "https://asia-northeast3-docker.pkg.dev": { "username": "oauth2accesstoken", "password": "...", "email": "none" },
  "https://asia-south1-docker.pkg.dev": { "username": "oauth2accesstoken", "password": "...", "email": "none" },
  "https://asia-south2-docker.pkg.dev": { "username": "oauth2accesstoken", "password": "...", "email": "none" },
  "https://asia-southeast1-docker.pkg.dev": { "username": "oauth2accesstoken", "password": "...", "email": "none" },
  "https://asia-southeast2-docker.pkg.dev": { "username": "oauth2accesstoken", "password": "...", "email": "none" },
  "https://australia-southeast1-docker.pkg.dev": { "username": "oauth2accesstoken", "password": "...", "email": "none" },
  "https://australia-southeast2-docker.pkg.dev": { "username": "oauth2accesstoken", "password": "...", "email": "none" },
  "https://asia-docker.pkg.dev": { "username": "oauth2accesstoken", "password": "...", "email": "none" },
  "https://europe-docker.pkg.dev": { "username": "oauth2accesstoken", "password": "...", "email": "none" },
  "https://us-docker.pkg.dev": { "username": "oauth2accesstoken", "password": "...", "email": "none" }
}
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
