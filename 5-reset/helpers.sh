#!/usr/bin/env bash


docker_run_if_needed() {
  local container_name args=("$@")
  while [ $# -gt 0 ]; do
    case "$1" in
      --name) container_name="$2"; shift 2 ;;
      *) shift;;
    esac
  done

  if ! docker ps -aqf "name=$container_name" | grep -q .; then
    docker run -d "${args[@]}"
  fi
}

function docker_network_create_if_needed() {
  if ! docker network inspect "$1" &> /dev/null; then
    docker network create "$1"
  fi
}

function docker_network_connect_if_needed() {
  if [ "$(docker inspect -f="{{index .NetworkSettings.Networks \"$1\" | json }}" "$2")" = 'null' ]; then
    docker network connect "$1" "$2"
  fi
}

function average_benchmark_csv() {
  jq -Rsr 'split("\n") | .[0] | split(",") | .[1:] | join(",")' "$1" > "$2"
  jq -Rsr '
    split("\n")
    | .[1:]
    | map(split(",") | map(tonumber?) | select(.[0] > 0))
    | transpose | .[1:] | map(add/length) | join(",")
  ' "$1" > "$2"
}
