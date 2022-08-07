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
docker build -t agent:v1 --build-arg RUNNER_TOKEN=AADQVX7B4BBITUPDDMUMI6DC55F7M --build-arg RUNNER_GITHUB_URL=https://github.com/tamaw/launchk8 --build-arg RUNNER_LABELS= -f agent.Dockerfile . 

# yay working
docker run -d agent:v1
# remove for now 
docker run -it --entrypoint /bin/bash agent:v1 
./config.sh remove --token AADQVX75PVWVJYQUACL3FMLC55FUI


# export container for k0s later
docker save agent:v1 | gzip > agentv1.tar.gz
ls -la

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
# test out the connection

# use the SSH key for github 
set GIT_SSH_COMMAND 'ssh -i key -o IdentitiesOnly=yes'

# TODO: need to fix some of the file permissions up for the secrets and sockets




