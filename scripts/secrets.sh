#!/bin/bash

set -euo pipefail

CURRENT_DIR="$(cd `dirname $0` && pwd)"

source $CURRENT_DIR/functions.sh

argcheck $@

if [[ ! $(kubectl get secret ca-mitm-token -n $RELEASE_NAMESPACE ) ]]; then
    echo "Creating ca-mitm-token..."
    cat <<EOF | kubectl replace -n $RELEASE_NAMESPACE -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ca-token-generator
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: ca-token-generator
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["create"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: ca-token-generator
subjects:
- kind: ServiceAccount
  name: ca-token-generator
roleRef:
  kind: Role
  name: ca-token-generator
  apiGroup: rbac.authorization.k8s.io
EOF
    kubectl delete job ca-token-generator || true
    cat <<EOF | kubectl create -n $RELEASE_NAMESPACE -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: ca-token-generator
  labels:
    release: $RELEASE_NAME
spec:
  template:
    spec:
      serviceAccountName: ca-token-generator
      containers:
      - name: ca-token-generator
        image: pepov/ca-token-generator
        command:
        - /ca-token-generator
        - $RELEASE_NAME
        - $RELEASE_NAMESPACE
        - ca-mitm-token
        - token
      restartPolicy: Never
  backoffLimit: 0
EOF

    echo -n "Waiting for the ca-mitm-token to get created.."
    while :; do
        if kubectl get secret ca-mitm-token -n $RELEASE_NAMESPACE 2>/dev/null; then
            break
        fi
        sleep 2
        echo -n "."
    done

    kubectl delete rolebinding -n $RELEASE_NAMESPACE ca-token-generator
    kubectl delete role -n $RELEASE_NAMESPACE ca-token-generator
    kubectl delete serviceaccount -n $RELEASE_NAMESPACE ca-token-generator

else
    echo "Secret ca-mitm-token is already created"
fi