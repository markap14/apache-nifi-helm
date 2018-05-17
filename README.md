## Installation instructions

### Initialize Helm with a serviceaccount for tiller
```
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller

helm init --service-account tiller
```

### Install or upgrade
```
# Update dependencies
helm dep up

# The name and namespace to use for the release is configurable
export RELEASE_NAME=nifi
export RELEASE_NAMESPACE=default

export CHART_PATH=.

# Minikube default unsecured install with one node
helm upgrade --install $RELEASE_NAME $CHART_PATH -f values-minikube.yaml -f values-unsecure.yaml --set replicaCount=1 --namespace $RELEASE_NAMESPACE
```

### Decommission
Helm does not delete the PVCs created, so they have to be removed manually, after deleting the chart
```
helm delete $RELEASE_NAME --purge
kubectl delete pvc -l release=$RELEASE_NAME
```

## Minikube setup instructions and tips

### Setup hyperkit on a Mac
```
# The default driver for minikube is VirtualBox but on a Mac hyperkit is the preferred
# Install the hyperkit driver https://github.com/kubernetes/minikube/blob/master/docs/drivers.md#hyperkit-driver
curl -LO https://storage.googleapis.com/minikube/releases/latest/docker-machine-driver-hyperkit \
&& chmod +x docker-machine-driver-hyperkit \
&& sudo mv docker-machine-driver-hyperkit /usr/local/bin/ \
&& sudo chown root:wheel /usr/local/bin/docker-machine-driver-hyperkit \
&& sudo chmod u+s /usr/local/bin/docker-machine-driver-hyperkit
```

### Start minikube with enough resources
```
minikube start --memory 8192 --cpus 4 --vm-driver=hyperkit
```

### Once the cluster is up the kubernetes dashboard is available
```
minikube dashboard
```

### Access NiFi cluster through the LoadBalancer
```
minikube service $RELEASE_NAME-apache-nifi-load-balancer
```

### Switch to the docker environment running in the VM
```
eval $(minikube docker-env)
```

After that it is possible to use a locally built image instead of the default one. Example:
```
# build image
docker build -t myrepo/nifi-node:myversion docker/

# and use it in minikube
helm upgrade $RELEASE_NAME $CHART_PATH --reuse-values --namespace $RELEASE_NAMESPACE
 --set image.repository=myrepo --set image.tag=mytag --set image.pullPolicy=IfNotPresent
```

## Todo items

* TLS setup for secure node communication
  - Put generated admin/user certs in secret store
* Ingress (with public TLS)
* Liveness/readiness checks (cluster state)
* Graceful shutdown
* StatefulSet fine tuning
  - poddistruptionbudget
  - default antiaffinity
* Set default resource request and limit
* Log rotation
* MITM token generation
* Relevant NOTES.txt
* Not all sysctl parameters are allowed to be configured currently:
  - vm.swappiness
  - net.ipv4.netfilter.ip_conntrack_tcp_timeout_time_wait
