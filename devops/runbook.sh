#!/bin/bash

## init
# Start minikube
minikube start --kubernetes-version=1.23.9
# Enable addons
minikube addons enable metrics-server
# Create namespace
kubectl create namespace devops
# Switch context to namespace
kubectl config set-context --current --namespace=devops

## Volumes
# Create the directory and modify the permissions
minikube ssh
sudo mkdir -p /var/local-vol/
sudo chown -R 1000:1000 /var/local-vol
sudo chmod -R 755 /var/local-vol
exit

## Create Agent Image
# Go to github -> Click New Runner
# Copy and replace token
# (it's easier to build it in minikube than to push it to minikube)
eval $(minikube docker-env)
docker build -t agent:v1 --build-arg RUNNER_TOKEN=<token> --build-arg RUNNER_GITHUB_URL=https://github.com/tamaw/launchk8 --build-arg RUNNER_LABELS= -f agent.Dockerfile .

## Private GitHub Repos
# Create a ssh key. Replace the email, omit the password
ssh-keygen -t ed25519 -C "<your>@<email>" -f key -P ""
# Copy the public key into your github profile
# Save the key as a secret 
kubectl create secret generic ssh-key-secret --from-file=ssh-github=secrets/key --from-file=ssh-github-pub=secrets/key.pub 

## Image Registry
# Replace host name below and create the certificate
openssl req -x509 -newkey rsa:4096 -days 365 -nodes -sha256 -keyout secrets/tls.key -out secrets/tls.crt -subj "/CN=registry-svc.devops.svc.cluster.local" -addext "subjectAltName = DNS:registry-svc.devops.svc.cluster.local"

# save the certificate as a secret
kubectl create secret tls registry-cert --cert=secrets/tls.crt --key=secrets/tls.key 
# Replace username/password & create htpasswd for login
docker run --rm --entrypoint htpasswd registry:2.6.2 -Bbn devops password > secrets/htpasswd
# Create a secret the register will use
kubectl create secret generic registry-auth --from-file=secrets/htpasswd 
# create the secret clients will use
kubectl create secret docker-registry registry --docker-server=registry-svc.devops.svc.cluster.local:5000 --docker-username=devops --docker-password=password --docker-email=a@a #-o=yaml --dry-run=client
# create service account for next step
kubectl create serviceaccount devops-sa
# tell the agent to default to the registry
kubectl patch serviceaccount devops-sa -p "{\"imagePullSecrets\": [{\"name\": \"registry\"}]}" 

# deploy everything! (may be some warnings from duplicates above)
kubectl apply -f devops.yaml

## Setup node for docker registry (could be improved)
# subsitute the IP address from the registry service
kubectl get svc 
minikube ssh
sudo su
# update IP & modify hosts to reach the registry
echo "10.102.251.105 registry-svc.devops.svc.cluster.local" >> /etc/hosts
# store the certs for auth
mkdir -p /etc/docker/registry-svc.devops.svc.cluster.local:5000/
exit
exit
minikube cp ./secrets/tls.crt /etc/docker/registry-svc.devops.svc.cluster.local:5000/tls.crt
# connect so that the node gets the docker/config.json file
minikube ssh
docker login registry-svc.devops.svc.cluster.local:5000
exit

