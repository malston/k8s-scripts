#!/usr/bin/env bash

set -o errexit
set -o pipefail


usage() {
  printf "Usage: \n  %s\n" \
    "$0 [service_account_name] [namespace]"
  printf "Examples: \n  %s\n" \
    "$0 astra kube-system"
  exit 1
}

SA=$1
NAMESPACE=$2

[ "$#" -lt 2 ] && usage

kubectl -n "$NAMESPACE" create serviceaccount "$SA"

kubectl create clusterrolebinding "${SA}-cluster-admin" \
  --clusterrole=cluster-admin \
  --serviceaccount="$NAMESPACE:$SA"

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: $SA-sa-token
  namespace: $NAMESPACE
  annotations:
    kubernetes.io/service-account.name: $SA
type: kubernetes.io/service-account-token
EOF


CLUSTER=$(kubectl config view -o jsonpath="{.contexts[?(@.name == \"$(kubectl config current-context)\")].context.cluster}")

mkdir -p "$HOME/.kube/$CLUSTER"
trap '{ rm -rf "$HOME/.kube/$CLUSTER"; exit ${EXIT:-1}; }' EXIT

SERVER=$(kubectl config view -o jsonpath="{.clusters[?(@.name == \"$CLUSTER\")].cluster.server}")
cat > "$HOME/.kube/$CLUSTER/kubernetes.ca.crt" <<EOF
$(kubectl -n "$NAMESPACE" get secret "$SA-sa-token" -o=jsonpath='{.data.ca\.crt}' | base64 --decode)
EOF
TOKEN=$(kubectl -n "$NAMESPACE" get secret "$SA-sa-token" -o jsonpath='{.data.token}' | base64 --decode)

export KUBECONFIG=$HOME/.kube/$CLUSTER/confiig
kubectl config set-cluster "$CLUSTER" --server="$SERVER"  --embed-certs --certificate-authority="$HOME/.kube/$CLUSTER/kubernetes.ca.crt"
kubectl config set-credentials "$SA" --token="$TOKEN"
kubectl config set-context "$CLUSTER" --cluster="$CLUSTER" --user="$SA"
kubectl config use-context "$CLUSTER"
kubectl get pods -n "$NAMESPACE"
kubectl config view --raw
