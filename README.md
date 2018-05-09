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

# Use values-mini.yaml when on Minikube
helm upgrade --install nifi . -f values-minikube.yaml
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
minikube service nifi-apache-nifi-load-balancer
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
helm upgrade --install nifi . -f values-minikube.yaml --set image.repository=myrepo/nifi-node:myversion --set image.pullPolicy=IfNotPresent
```

## Todo items

* TLS setup for secure node communication
* Explicit command to run containers (NiFi)
* Liveness/readiness checks (cluster state)
* StatefulSet fine tuning
  - poddistruptionbudget
  - paralleldist
  - default antiaffinity
* Set default resource request and limit
* Log rotation
* GKE ingress with TLS
* Not all sysctl parameters are allowed to be configured currently:
  - vm.swappiness
  - net.ipv4.netfilter.ip_conntrack_tcp_timeout_time_wait
