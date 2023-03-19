export IMAGE="example-service:dev-$(date +%s)"

docker build -t "$IMAGE" ./example-service

minikube image load "$IMAGE"

cat example-service.yaml | envsubst | kubectl apply -f -
