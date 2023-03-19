export IMAGE="example-service:dev-$(date +%s)"

docker build -t "$IMAGE" ./example-service

kind load docker-image "$IMAGE"

cat example-service.yaml | envsubst | kubectl apply -f -
