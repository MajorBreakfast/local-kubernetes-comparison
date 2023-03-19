export IMAGE="example-service:dev-$(date +%s)"

docker build -t "$IMAGE" ./example-service

docker save "$IMAGE" | multipass transfer - microk8s-vm:/tmp/image.tar
microk8s ctr image import /tmp/image.tar

cat example-service.yaml | envsubst | kubectl apply -f -
