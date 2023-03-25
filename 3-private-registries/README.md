```sh
kubectl create secret docker-registry regcred \
--namespace gcp-auth \
--docker-server europe-docker.pkg.dev \
--docker-username oauth2accesstoken \
--docker-password $(gcloud auth print-access-token) \
--docker-email none
```
