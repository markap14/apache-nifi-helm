#!/bin/bash

set -eou pipefail

if [[ -z ${SELECTED_ENV:-} ]]; then
    echo "Please select an existing environment to use (or define a custom one under ./env)!"
    echo -n "Available envs: "
    ls env/
    echo "Default: minikube-secure"
    read -r SELECTED_ENV
    export SELECTED_ENV=${SELECTED_ENV:-"minikube-secure"}
else
    echo "Selected env: $SELECTED_ENV"
fi
source env/$SELECTED_ENV

if [[ -z ${SELECTED_CONTEXT:-} ]]; then
    echo -n "Available contexts: "
    echo $CONTEXTS

    DEFAULT_CONTEXT=$(echo $CONTEXTS | head -n1)
    echo "Please select preferred context, or use first one as default: $DEFAULT_CONTEXT"

    read -r SELECTED_CONTEXT
    export SELECTED_CONTEXT=${SELECTED_CONTEXT:-$DEFAULT_CONTEXT}
else
    echo "Selected context: $SELECTED_CONTEXT"
fi
kubectl config use-context $SELECTED_CONTEXT

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

VALUES_ARGS=$(for i in ${VALUES_FILES[*]}; do echo -n "-f $i " ; done)

helm upgrade --install $RELEASE_NAME $CHART_PATH\
 $VALUES_ARGS\
 --namespace $RELEASE_NAMESPACE\
 --set properties.webProxyHost=$PROXY_HOST\
 --kube-context $SELECTED_CONTEXT

echo "
Please export the following variables to stay with the currently selected environment for the session:
  export SELECTED_ENV=$SELECTED_ENV SELECTED_CONTEXT=$SELECTED_CONTEXT
"