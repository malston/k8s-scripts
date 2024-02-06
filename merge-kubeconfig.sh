#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

__DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

KC="${1:-$KUBECONFIG}"

date=$(date)

cp "$HOME/.kube/config" "$HOME/.kube/config.${date}"
KUBECONFIG=$HOME/.kube/config:$KC

kubectl config view --flatten > /tmp/config && mv /tmp/config "$HOME/.kube/config"