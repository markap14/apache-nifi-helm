#!/bin/bash

set -eou pipefail

if [[ -z ${SELECTED_ENV:-} ]]; then
    echo "Please select an environment to use or define a custom one under the env/ folder!"
    echo "Default: minikube-secure"
    ls -1 env/
    read -r SELECTED_ENV
fi

source env/${SELECTED_ENV:-"minikube-secure"}

VALUES_ARGS=$(for i in ${VALUES_FILES[*]}; do echo -n "-f $i " ; done)

echo "Checking tiller"
if ! kubectl get po -n kube-system | grep tiller; then
    echo "Initializing helm in the kube-system namespace"
    kubectl create serviceaccount --namespace kube-system tiller
    kubectl create clusterrolebinding tiller-cluster-role --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
    helm init --service-account tiller

    echo -n "Waiting for tiller to become available.."
    until kubectl get po -n kube-system | grep tiller; do
        sleep 1
        echo -n "."
    done
fi

if [[ -z ${PROXY_HOST:-} ]]; then
  echo "Please provide the domain name that will be used to access the cluster! Default: nifi"
  read -r PROXY_HOST
  export PROXY_HOST=${PROXY_HOST:-nifi}
fi

helm upgrade --install $RELEASE_NAME $CHART_PATH $VALUES_ARGS --namespace $RELEASE_NAMESPACE --set properties.webProxyHost=$PROXY_HOST
