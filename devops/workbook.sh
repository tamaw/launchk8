## Project


# architecture 
# - docker in docker - runs builds in docker
# - agent - github connection
# - Separate docker build with

# worth checking out as alternatives
# - buildah, podman


## local machine (minikube)

# create directories for local volumes (node only storage)
minikube ssh
#$ sudo mkdir -p /var/local-vol
#$ sudo chown -R 1000:1000 /var/local-vol
#$ sudo chmod -R 755 /var/local-vol

# setup local minikube to test
minikube start --kubernetes-version=1.23

# deploy 
kubectl delete -f devops.yaml
kubectl create -f devops.yaml

# check to see if it's running correctly
kubectl get sc,pv,pvc
kubectl get po
kubectl describe po/docker
kubectl logs po/docker

kubectl logs po/agent

minikube ssh
#$sudo curl --unix-socket /var/local-vol/socket/docker.sock http://localhost/images/json

# test connectivity from agent
kubectl exec -it agent -- /bin/sh
#$curl --unix-socket /var/socket/docker.sock http://localhost/images/json








