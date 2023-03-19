#!/bin/bash

export IMAGE="example-service:dev-$(date +%s)"

eval $(minikube docker-env)
export DOCKER_BUILDKIT=1

docker build -t "$IMAGE" ./example-service

cat example-service.yaml | envsubst | kubectl apply -f -
