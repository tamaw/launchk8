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
kubectl apply -f devops.yaml

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
# !! in minikube docker
docker build -t agent:v1 --build-arg RUNNER_TOKEN=AADQVX2L4LHS7IZ5RVWHVLTC6ITI6 --build-arg RUNNER_GITHUB_URL=https://github.com/tamaw/launchk8 --build-arg RUNNER_LABELS= -f agent.Dockerfile . 

# yay working
docker run -d agent:v1
# remove for now 
docker run -it --entrypoint /bin/bash agent:v1 
./config.sh remove --token AADQVX75PVWVJYQUACL3FMLC55FUI


# export container for k0s later
#docker save agent:v1 | gzip > agentv1.tar.gz
#ls -la

# new deployment with stateful services

# register the dind docker as a repo, create a secret pointing to it and pull image
kubectl create secret docker-registry docker-dind --docker-server=unix:///var/local-vol0/socket/docker.sock --docker-username=a --docker-password=a --docker-email=a 
kubectl delete secret docker-dind
kubectl delete po/test-dind
kubectl create -f test-pod.yaml
kubectl get po
kubectl describe po/test-dind
kubectl exec -it test-dind -- /bin/bash 
# save yaml
kubectl create secret docker-registry docker-dind --docker-server=unix:///var/local-vol0/socket/docker.sock --docker-username=a --docker-password=a --docker-email=a -o=yaml --dry-run=client

# put secret into the yaml

# can the agent deploy from dind ?
kubectl exec -it agent-ss-0 -- /bin/bash 
cd /var/socket # test.yaml is here
kubectl create -f test.yaml
kubectl get po

# back to local machine for permission to read events
kubectl descibe po/test 
kubectl get events
kubectl create -f test.yaml

# can then try assign the secret to the service account for the deployment role
kubectl patch serviceaccount internal-kubectl -p "{\"imagePullSecrets\": [{\"name\": \"docker-dind\"}]}"  

# think about deployment permissions

# ssh key for private repo
ssh-keygen -t ed25519 -C "me@tama.id.au" -f key -P ""
kubectl create secret generic ssh-key-secret --from-file=ssh-github=key --from-file=ssh-github-pub=key.pub
# !! upload .pub to github
kubectl delete -f devops.yaml
kubectl create -f devops.yaml
kubectl exec -it agent-ss-0 -- /bin/bash 
# check if the keys appear
ls /etc/ssh_keys

## test out the connection
# use the SSH key for github 
set GIT_SSH_COMMAND 'ssh -i key -o IdentitiesOnly=yes'

# TODO: need to fix some of the file permissions up for the secrets and sockets

## Deploy the built container from dind into the cluster

# needs permission for deployments in the app api group
kubectl api-resources -o wide
kubectl apply -f devops.yaml

# created mud-deployment.yaml - should source it via the service account patch
kubectl cp ../apps/mud-deployment.yaml agent-ss-0:/var/_work
kubectl exec -it agent-ss-0 -- /bin/bash 
cd /var/_work
kubectl create -f mud-deployment.yaml

# can docker even run the image itself?

kubectl get deployments
kubectl get po
kubectl describe po/mud-deploy-d8c7df779-bb5k2

kubectl delete deploy/mud-deploy
kubectl delete svc/mud-svc

kubectl get po
kubectl get events
# nope...

## setup registry
# - So its apparent i've made a mistake at this point
# we cant tell the node to use the pods unix socket to deploy to k8s
# or else we're just deploying to the other pod lol
# - the docker images are only sharable via a registry
# so we'll have to tell the nodes docker to pull from another registry
# this will probably help with k0s later anyhow

## new registry running in a pod
# new self signed certificate
openssl req -x509 -newkey rsa:4096 -days 365 -nodes -sha256 -keyout secrets/tls.key -out secrets/tls.crt -subj "/CN=registry-ss-0" -addext "subjectAltName = DNS:registry-ss-0"
kubectl create secret tls registry-cert --cert=secrets/tls.crt --key=secrets/tls.key

# new htaccess file
docker run --rm --entrypoint htpasswd registry:2.6.2 -Bbn tama bigdoglol > secrets/htpasswd
kubectl create secret generic registry-auth --from-file=secrets/htpasswd

# redeploy
kubectl delete -f devops.yaml
kubectl create -f devops.yaml
kubectl get po -o wide
kubectl describe po/registry-ss-0

# is the registry deployed successfull - should see some json
kubectl exec -it registry-ss-0 -- sh
wget --no-check-certificate --header "Authorization: Basic $(echo -n 'tama:bigdoglol' | base64)" https://registry-ss-0:5000/v2/_catalog
cat _catalog
rm _catalog

## setup the node (this part is ugly)
# - minikube has it's own docker namespace with it's own docker certs
# and you have to dump them all for your own unless you go insecure
# - the node doesn't have coredns to resolve the stateless service name
# removed clusterIP for now

# get the registry ip
kubectl get svc
# registry is 10.106.80.7:5000
minikube ssh
# change node docker to use the new registry from the pod
export REGISTRY_NAME="registry-ss-0"
export REGISTRY_IP="10.106.80.7"
# modify hosts to match the hostname of the cert
echo "10.106.80.7 registry-ss-0" >> /etc/hosts
# test it we can connect without certificate
wget --no-check-certificate --header "Authorization: Basic $(echo -n 'tama:bigdoglol' | base64)" https://registry-ss-0:5000/v2/_catalog
cat _catalog
rm _catalog
# now put our certs on there
minikube ssh
sudo su
mkdir -p /etc/docker/certs.d/registry-ss-0:5000
# copy file to the node (host)
minikube cp ./secrets/tls.crt /home/docker/tls.cert
# logging in will create a ~/.docker/config.json which the node will use
minikube ssh
#>docker login registry-ss-0:5000 -u tama -p bigdoglol

# secret from docker file copied over
kubectl create secret docker-registry docker-dind --docker-server=unix:///var/local-vol0/socket/docker.sock --docker-username=a --docker-password=a --docker-email=a -o=yaml --dry-run=client
# you could create the secret like the one above 
kubectl create secret generic docker-registry --from-file=.dockerconfigjson=secrets/dockerconfig.json --type=kubernetes.io/dockerconfigjson

# patch service account for new secret
kubectl patch serviceaccount internal-kubectl -p "{\"imagePullSecrets\": [{\"name\": \"docker-registry\"}]}"  

# test it out
kubectl exec -it agent-ss-0 -- /bin/bash
kubectl exec -it registry-ss-0 -- sh
docker pull nginx
docker tag nginx:latest registry-ss-0:5000/mynginx:v1
docker push registry-ss-0:5000/mynginx:v1

## nuke it, trying with pods
minikube delete
minikube start --kubernetes-version=1.23.9

# trying with new hostname
kubectl apply -f devops.yaml

# the node cannot read the fqdn :( needs manual assignment
# pods can connect however, going to need a short name for the cert 
nslookup registry-svc.default.svc.cluster.local
nslookup 10.110.49.138.default.pod.cluster.local

minikube ssh
sudo su
# modify hosts to match the hostname of the cert
echo "10.110.49.138 registry" >> /etc/hosts
# change node docker to use the new registry from the pod
export REGISTRY_NAME="registry"
export REGISTRY_IP="10.110.49.138"
# store the certs for auth
mkdir -p /etc/docker/registry:5000/
#^D
minikube cp ./secrets/tls.crt /etc/docker/registry:5000/tls.crt
minikube ssh
docker login registry:5000 

# TODO maybe mount the secret dockerconfig onto the agent
# this is needed because it will need to use docker push
# TODO modify agent with docker env and certificate test login
# TODO could just mount the certs into the docker cert path




