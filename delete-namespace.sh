#!/usr/bin/env bash

NAMESPACE=${1:?"Namespace is a required argument"}

kubectl get namespace "$NAMESPACE" -o json \
  | jq 'del(.spec.finalizers)' \
  | kubectl replace --raw "/api/v1/namespaces/$NAMESPACE/finalize" -f -