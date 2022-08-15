#!/bin/bash

# load the data for the game up
minikube ssh
sudo mkdir -p /var/mud-local-vol/mud_data
sudo chown -R 1000:1000 /var/mud-local-vol/mud_data
sudo chmod -R 755 /var/mud-local-vol/mud_data
exit

# copy the data across
minikube cp repos/mud/data/help.txt /var/mud-local-vol/mud_data/help.txt

# create required resources requring highten permission
kubectl apply -f apps/mud/mud-host-setup.yaml

# add the docker secret (required per namespace)
kubectl create secret docker-registry registry --docker-server=registry-svc.devops.svc.cluster.local:5000 --docker-username=devops --docker-password=pass123 --docker-email=a@a -n mud-dev

