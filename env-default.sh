export RELEASE_NAME=nifi
export RELEASE_NAMESPACE=default
export CHART_PATH=.

if [[ -z $PROXY_HOST ]]; then
  echo "Please provide the domain name of the proxy you will use to access the cluster! Default: nifi"
  read -r PROXY_HOST
  export PROXY_HOST=${PROXY_HOST:-nifi}
fi

  
