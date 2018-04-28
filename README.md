Minikube directions (for a MAC v0.26.1)

minikube start --memory 8192 --cpus 4 --vm-driver=xhyve
minikube addons enable ingress
minikube dashboard
eval $(minikube docker-env)
docker build .
docer tag <id> apache/apache-nifi-k8s:1.6.0
helm install --name test-nifi --namespace nifi ./apache-nifi-helm
browse to ingress address found in k8s dashboard
