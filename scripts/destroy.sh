#!/bin/bash

set -eou pipefail

CURRENT_DIR="$(cd `dirname $0` && pwd)"

source $CURRENT_DIR/functions.sh

argcheck $@

helm delete $RELEASE_NAME --purge
kubectl delete pvc -l release=$RELEASE_NAME