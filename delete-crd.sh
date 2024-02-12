#!/usr/bin/env bash

CRD=${1:?"CustomResourceDefinition is a required argument"}

# remove the CRD finalizer blocking on custom resource cleanup
kubectl patch crd/"$CRD" -p '{"metadata":{"finalizers":[]}}' --type=merge

# now the CRD can be deleted (orphaning custom resources in etcd)
kubectl delete crd/"$CRD"
