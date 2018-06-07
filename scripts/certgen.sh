#!/bin/bash

set -euo pipefail

CURRENT_DIR="$(cd `dirname $0` && pwd)"

source $CURRENT_DIR/functions.sh

argcheck $@

cat <<EOF | kubectl replace --force=true -n $RELEASE_NAMESPACE -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: secret-creator
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: secret-creator
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["create"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: secret-creator
subjects:
- kind: ServiceAccount
  name: secret-creator
roleRef:
  kind: Role
  name: secret-creator
  apiGroup: rbac.authorization.k8s.io
EOF

cat <<EOF | kubectl create -n $RELEASE_NAMESPACE -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: ca-cert-generator
  labels:
    release: $RELEASE_NAME
spec:
  template:
    spec:
      serviceAccountName: secret-creator
      containers:
      - name: ca-cert-generator
        image: pepov/ca-cert-generator
        command:
        - sh
        - -c
        - |
          #!/bin/sh

          set -exuo pipefail

          mkdir -p /tmp/ca-cert-generator
          cd /tmp/ca-cert-generator

          \${NIFI_TOOLKIT_HOME}/bin/tls-toolkit.sh client\
              -c "${RELEASE_NAME}-apache-nifi-ca"\
              -p "${CA_PORT:-8443}"\
              -t "\$(cat /ca-mitm-token/token)"\
              -D "${DN:-CN=admin,OU=NIFI}"\
              -T "${TYPE:-pkcs12}"

          \${NIFI_TOOLKIT_BASE_DIR}/kubectl create secret generic ca-cert-"${ID:-admin}" --from-file /tmp/ca-cert-generator

        volumeMounts:
          - name: ca-mitm-token
            mountPath: /ca-mitm-token
      restartPolicy: Never
      volumes:
        - name: ca-mitm-token
          secret:
            secretName: ca-mitm-token
  backoffLimit: 0
EOF