#!/usr/bin/env bash
set -Eeuo pipefail

$(dirname $0)/benchmark-rancher-desktop.sh $1 docker-desktop
