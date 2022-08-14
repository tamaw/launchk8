#!/bin/bash
# I'm just going to pretend this doesn't exist and not automate it
# It's here for completeness. 

# load the data for the game up
minikube ssh
mkdir -p /var/local-vol/mud_data
exit

# copy the data across 
minikube cp repos/mud/data/help.txt /var/local-vol/mud_data


