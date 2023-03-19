export IMAGE="example-service:dev-$(date +%s)"

docker build -t "$IMAGE" ./example-service

k3d image import "$IMAGE"

cat example-service.yaml | envsubst | kubectl apply -f -
