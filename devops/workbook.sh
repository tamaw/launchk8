## Project

# architecture 
# - docker in docker - runs builds in docker and hosts images
# - agent - github connection
# - Separate docker build with

# worth checking out as alternatives
# - buildah, podman

## create the docker within kubernetes  with (docker in docker)

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

### Create the agent (github runner)

# deploying this to minikube before the real stuff
eval $(minikube docker-env)
docker info

# create our github runner docker image
docker build -t agent:dev -f agent.Dockerfile . 
# just a quick repo build for now 
docker image ls
docker container ls
# install manually to build script and see dependecies we need 
docker run -it agent:latest /bin/bash
# build the docker file up to run
docker run agent:dev

# build again with token - tokens expire in 1 hour
docker build -t agent:v1 --build-arg RUNNER_TOKEN=AADQVX2E4KGTBKRBAKMUXXTC5IUCY --build-arg RUNNER_GITHUB_URL=https://github.com/tamaw/launchk8 --build-arg RUNNER_LABELS= -f agent.Dockerfile . 

# yay working
docker run -d agent:v1
# remove for now 
docker run -it --entrypoint /bin/bash agent:v1 
./config.sh remove --token AADQVX2E4KGTBKRBAKMUXXTC5IUCY
# export container for k0s later
docker save agent:v1 | gzip > agentv1.tar.gz
ls -la



