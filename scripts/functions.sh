#!/bin/bash

function argcheck {
    [[ $# -lt 2 ]] && cat <<EOF && exit 1
Usage: <profile> <context>

- profile: Predefined or custom profile that will be sourced for required env vars
- context: Kubectl context used to install the helm chart into
EOF

    SELECTED_PROFILE=${1:-}
    echo "Selected profile: $SELECTED_PROFILE"
    source $SELECTED_PROFILE

    SELECTED_CONTEXT=${2:-}
    echo "Selected context: $SELECTED_CONTEXT"
    kubectl config use-context $SELECTED_CONTEXT
}