#!/bin/bash

# Borg - original googles schedule monitor & machine sharing
# Kubernetes derives from Borg

# Containers have their own PID namespace, Network namespace & UTS namespace
# control groups (cgroups) set resources which it can consume

# k8s
# - automatically schedules containers for resource optimisation
# - service discovery to find other containers
# - load balancing to spread traffic - OSI layer 4 & 7
# - self healing - reschedule when a container crashes
# - horizontal scaling - automatically creates replicas of containers
# - rolling updates - swap out old containers
# - zero-downtime reversion - go back a version
# - secret data management
# - abstracts away hardware

# two types of users
# - regular - create and manage containers
# - administrators - own and manage the cluster

# high level
# - cluster - containers one or more nodes
# - master/worker architecture - host master processes which control the cluster
# - control plane - master node processes (api, scheduler, etcd cluster, control manager)
#   - scheduler - where to deploy
#   - etcd - stores cluster related management/configuration data
#   - controller manager - node controller,  replication controller
#   - api server - controls the cluster
# - workers node components
#   - kubelet - node agent
#   - kube-proxy - network communication
#   - container engine - docker runc or something

# kubectl (kubecuttle) - manages the cluster by calling the api

# get minikube going with a version
minikube start --kubernetes-version=1.23.9
minikube status
minikube dashboard --url
minikube stop
# create new cluster
minikube delete

# pods
# - holds one or more containers
# - cannot deploy containers without a pod
# - containers share resources in a pod (ip, hostname, ports, nics)
# - containers have isolated file system but can share within a pod
# - containers can communicate within a pod without NAT (via localhost, IPC)
# horizontal scaling
# - replicates the pods not the containers as to have a new network namespace
# - are ephemeral (short lived) and can be evicted from the node
# - generally most pods have one container unless tightly coupled

kubectl create -f primes-pod.yaml
# can see new pod
kubectl get pods
# only container is still minikube
docker ps

# logs
# - All container logs can be accessed by pod logs (can follow with -f)
# - Logs aren't really stored against the pod but against the container
# - Multiple containers in a pod require specifying what container with -c name
kubectl logs pod/primes
kubectl logs pod/primes -c init1

# delete pod (can delete by file with -f)
kubectl delete pod/primes

# k8 objects (resources) can be printed with get
# same values as the config file but in more detail with additional output as status for debugging
kubectl get pod/primes -o json

# restart policies (always[default], onfailure, never)
# restarts exponentially (max 5m, resets after 10m)

# terminating pods give 30 seconds to gracefully shutdown or it will forcefully shutdown
# can optionally specify
kubectl delete pod/primes --grace-period=50
# last resort
kubectl delete pod/primes --grace-period=0 --force

# more yaml conf
# - command: overrides ENTRYPOINT in a docker image
# - args: overrides CMD in a docker image
# - env: define your own environment variables for the container.
# - can reference environment variables with $(name) which are expended before command being run
# - $ is also an escape character $$ prints $

# init containers
# - Perform initialisation before starting the app containers
# - Must run to completion
# - Run in order 0,1,2..
# - If the init containers fail to complete, the pod fails to start up
# - Could be for
#   - touch sensitive data
#   - wait for other services to spin up

# names
# - create for users
# - spacially unique - one name of the same kind
# - only need to be unique at a given time
# - metadata: name:
# - uid - a unique id across space and time. retrieved from the get command

# labels
# - select a components based on characiterists
# - specified in the metadata as a kvp (key is unique)
# - metadata: labels: some: thing
# - can use labels for releases
# - don't store non identifying information
# - almost everything can be labelled (controllers, sevices, pods etc)

# querying labels
# - label selectors for querying (= == !=)
# - set based (in notin !)
# - logical and as coma (a,b) logical or can be used with in keyword

kubectl create -f example.yml

kubectl get pods --show-labels
# show a specific label on a column
kubectl get pods -L=layer -L=version
# use a selector (many commands allow selectors)
kubectl get pods -l=layer=interface
kubectl get pods -l=version=beta
# multi selectors then print the version
kubectl get pods -l='layer=interface,version!=alpha' -L=version

# new (set based) label expression selectors in config files
# - spec: selector: matchExpressions: - {key: b operator: a, values: [a,c]}
# - replica sets and deployments benefit most from the new style selector field
# - matchLabels: very similar to the old style (likea buy) a map
# - matchExpressions: contains key, operator and values
#   - values: is an array
#   - operator: is In, NotIn, Exists, DoesNotExist
#   - Exists/DoesNotExist - the values array must be empty
#   - In/Not - the values array must be populated
# - either matchLabels or matchExpressions must be provided

# clean-up
kubectl delete -f example.yml

# annotations
# - kvp to store metadata on a component, similar to labels
# - used to attach non-identifying metadata. aka everything else not a label
# - eg team contact, git branch hash, cluster or user modified,
# - lesser character limitations than labels
# - can store structured and unstructured data

# namespaces
# - can create the illusion of more clusters like a virtual cluster
# - managed by the kubenetes cluser
# - parition an existing cluster into more clusters
# - used help with naming resources. components in different namespaces can share names
# - can divide up resources to share
# - pods, controllers and services reside in namespaces but nodes and namespaces do not
# - used for dev/uat environments or multi teams sharing the same server

kubectl get namespaces

# comes with kube-public and kube-system for services related to kubernetes
# and with a default namespace

# create namespaces
kubectl create namespace dev
kubectl create namespace tst

# you need to specify a namespace or else it's the default namespace
kubectl create -f example-pods.yml --namespace dev
kubectl get pods -n dev

# get all pods in all namespaces
kubectl get pods --all-namespaces

# delete pods in a namespace
kubectl delete pods --all -n dev

# delete a namespace (deletes all objects within namespace)
kubectl delete namespace dev

# config files can create namspaces within it
# kind: namespace \n metadata: name: example
# and for a pod -
# metadata: namespace: example

## Controllers
# - schedules a replacement for a pod when it goes down
# - containers are automatically rescheduled when they die by the pod
# - lots of types of controllers
# ReplicaSets - keeps a number of pods running
# - input <- template
# - count <- number to keep running
# - manages anything by the label expression matcher
# - !! dont have two relicasets manage the same pods
# - must have the restart policy set to always

kubectl create -f replica.yaml
kubectl get replicasets
# automatically generates pod names
kubectl get pods
# scale up for fun
kubectl scale --replicas=9 -f replica.yaml
kubectl get replicasets
# delete it all
kubectl delete replicasets awesomeo
# should terminate all pds
kubectl get pods

# naked pods
# - pods created without controllers e.g replicasets
# - they have no way of starting up if they shut down
# - always create pods with controllers

# avoid replicationControllers due to how they reference other pods by label only

# deployments
# - can roll out updates on the fly
# - can roll back
# - creates replicasets with randomised names
# - pod names have the replicaset name postfixed with more randomisation
# - prefer this if you need the update/rollback functionaity
# - very similar to replicaset at the template level

kubectl create -f deployment.yml
kubectl get deployments
kubectl get replicasets
kubectl get pods

# can manually scale a deployment using the underlying replicaset
kubectl scale deployment/awesomeo --replicas=1

# kubectl can hot reload edits
kubectl edit -f deployment.yml

# kubectl describe command
# - provides more detail than the get command
# - good for looking at deployments and events
kubectl describe deployment/awesomeo

# upgrade deployments (on the fly)
# - a rollout is using deployments
# - similar to scaling up and down different replicasets
# - keeps minimum number of pods running
# - total number of pods wont exceed a limit
# - all automatic
# - maxSurge - specifies how many additional replicas you can have
# - maxUnavilable - fails the pod
# - you can specify an percentage (rounded up)
# - both maxSurge andmaxUnailable default to 25%

kubectl edit -f deployment.yml
# see the change + look at events
kubectl describe deployment/awesomeo

# rollout command

# rollout status
kubectl rollout status deployment/awesomeo

# handle diagnostics
kubectl get pods
kubectl logs pod/awesomeo-5dd74bcb88-9vkr7

# rollout undo
# - failed updates
kubectl rollout undo -f deployment.yml

# rollout history
# - view history of deployments
kubectl rollout history deployment/awesomeo

# revisions
# - can rollback to already deployed revisions with --to-revision
# - list revisions with history
# - only keeps a max of 10 or so around
# - each revision keeps a replicaset around to scale it back up
# - if you remove the replica sets, you can't roll back
kubectl rollout undo deployment/awesomeo --to-revision=8
kubectl get replicasets

# rollout pause/resume

## daemon set (controller)
# - runs 1 pod per node
# - could be used for log aggregation
# - runs daemon processes to manage nodes
# - new node is added the daemon set will schedule a pod onto it
# - kind: DaemonSet
# - don't have a replicas field
# - deleting the daemonset will terminate all pods
# - you can create daemon sets as a part of the cluster bootup process
# - which means the daemon sets aren't deployed using the scheduler
kubectl create -f daemonset.yml

# print pods with more information
kubectl get pods -o wide

# the kubectl exec will point to a context which can be local or remote
kubectl config get-contexts
kubectl config use-context minikube

### Services
# - ip addresses cannot be reliable on a pod
# - services are an abstraction to reference the pod
# - services can be also a simple load balance to balance the pod
#   - traffic is randomly distributed at layer 4 tcp/udp
# -  kind: Service
# - uses a simple selector not an matchExpression
# - accepts traffic and forwads it to the pods

kubectl create -f service.yaml
kubectl get services # returns 10.100.100.115
# curl 10.106.94.232 -p 3000 # fails
# .. deploy daemon set with alpine to ssh
#kubectl create -f daemonset.yml
#kubectl logs pod/daemon-jmhxq
#kubectl get pods
kubectl exec -it daemon-jmhxq -- sh
# can only curl within the cluster but can hit the service or pod ip
# curl 10.100.100.115

kubectl delete -f service.yaml

# IP
# - you can specify the cluster ip by using clusterIP:
# - the valid range 10.96.0.0/12
# - You typically don't assign it yourself

# Port
# - ports: port: 80 - the port the client uses
# - ports: targetPort: 3000 - the port on the backing pods

# Expose
# - creates a new service from a pod, replicaset, deployment and
# - will need to have the deployment deployed first
# - wont except deployments/replicasets with matchexpression labels
# .. service.yaml commented out the the kind:service
kubectl expose -f service.yaml --selector=layer=four --port=80 --target-port=80
kubectl get services
# .. ssh in
#kubectl delete service/echo

## Service Discovery
# - annoying to get ip addresses
# - lookup by service name uses a dns
# - dns is optional
# - dns gives the service a predictable domain name
# - <servicename>.<namespace>
# - namespace is optional if you're in the same namespace

#.. services/echo
#.. ssh in
kubectl exec -it daemon-jmhxq -- sh
# curl echo # works

## Environment varaibles
# - scopes to the service name
# - <servicename>_<variable> eg cluster_port
# - list varaibles on pod sh# printenv
# - can use the env vars to talk to other services
# - contains cluster env vars
# - !! cluster vars are only populate if the pod is created after the service
# within cluster .. curl $ECHO_PORT_80_TCP_ADDR # created by expose


## NodePort Service
# - simplist way for external access
# - opens the same port on every node
# - is attached to a node
# - will redirect ANY node traffic to the service on the node it's attached to
# - useful for an external load balancer
# - to turn a Service into a NodePort Service
#	 - spec: type: NodePort
# - automatically get assigned a nodePort 30000-32767
# - can change with --service-node-port-range to the clusters api server
# - can change the port with nodePort: 33222

#.. change service.yaml to include Service and type: NodePort
kubectl create -f service.yaml
minikube ip
# get ip and Node Port Service
minikube service --url cluster-ip-svc
curl 192.168.49.2:32409

# browser caching
# - watch for etags and keep alives as the service will respect those values


## LoadBalancer Service
# - only on some service providers eg gcp
# - magically comes through on a public ip like node port
kubectl create -f loadbalancer.yml
minikube service --url load-svc
curl 192.168.49.2:32732

# no selector services
# - services can proxy for something outside of kubernetes
# - pods can talk to the service and not care about where it actually points
# - useful for different environments dev/prod
# - used with Endpoint Objects
#   - maps to ips and ports
#   - kind: Endpoints
# - Service and Endpoint name property - must be the same
# - create a service without a select and point it to an endpoint object

# session afinity
# - sessionAffinity - specify the client to hit the same pod
# - optionally sessionAffinityConfig: clientIP: timeoutSeconds: 3600
# - timeout will then change pod
# - not enabled by default

# kubectl patch
# - patch - you can pass a json patch on the command line
# - replace - requires complete schema
kubectl get deploy
bash
kubectl patch deploy/echo -p $'spec:\n replicas: 5'

# kubectl apply
# - diffs the config with the live config and applys the difference
# - selective patching
# - apply stores the config file in the annotation against the object
# - performs a three-way diff object/file/annotation
#   - this way it keeps manually added changes to the pod
# - if you use the kubectl replace command, it will blow away the annotation stored
# - you can pass --save-config when using create to make the annotation exist

# kubectl create
# - can pass in a folder with all the components in each file and -R -f
# - each folder can be named after their type services, volumns etc

# kubectl watch
# - you can pass -w to watch and see changes
kubectl get po -w

# print pods and sort by start time
kubectl get po --sort-by=status.startTime

# delete all deployments, pods and services in the default name space
kubectl delete deploy,po,svc --all

# kubectl attach
# - attach to the pods stdout
kubectl create -f daemonset.yml
kubectl get daemonset
kubectl get pods
kubectl attach daemon-jxwzg
# specify -c containername

# stdin
# - set spec: containers: stdin: true & tty: true
# - kubectl attach -it

# kubectl copy
# - copy files between from your machine to the pod
# - must have tar installed on the container
echo "thisismytestdata" > payload.txt
kubectl cp payload.txt daemon-jxwzg:/tmp/payload.txt
kubectl exec -it daemon-jxwzg -- sh
# cat /tmp/payload.txt
# echo "hereiam" > response.txt
kubectl cp daemon-jxwzg:response.txt response.txt
cat response.txt

# Port Forwarding
# - test pods directly by exposing the port outside for testing
# - useful for debugging
# - defaults to pods but can do a service as well with svc/
kubectl get po
kubectl port-forward echo-5bbc955d66-djpjr 8080:80
# curl http://localhost:8080
# for services
kubectl get service
kubectl port-forward svc/cluster-ip-svc 8080:3000

# Kubectl Top
# display resources pods are using
# - requires a metrics server
# - metric server comes with minikube
# - could also promepheuus
# - !! wont work instantly, needs time to build data
minikube addons list
minikube addons enable metrics-server
kubectl get nodes
kubectl top node minikube
# look at a pods resources
kubectl get pods --all-namespaces
kubectl top pods kube-scheduler-minikube -n kube-system

#  Probs
# - check the health/liviness on a container
# - probs run on the kubelet
# - contain some logic run as handlers
# - handlers:
#   - ExecAction - runs a command returns non-zero as failure
#   - HTTPGetAction - needs 200s for returns
#   - TCPSocketAction - checks by opening a port
# - prob types
#   - liveness prob - restarts containers on x many failures
#   - readiness prob - ready to recieve requests or temporaily unresponsive
# - failure/successThreshold - attempts before failure or success
# - timeoutSeconds - waiting for the health check, timeout = unknown

kubectl create -f pod-ready.yaml
kubectl get po
kubectl describe pod/ready
kubectl exec -it ready -- sh
# rm /tmp/file
# health check fails
kubectl describe pod/ready

kubectl delete -f pod-ready.yaml

## lifecycles
# - containers have lifecycles
# - PostStart - runs after container has started
# - PreStop - executes before a container terminates.
# - handlers
#   - exec - runs a command
#   - http - makes a get request to containers host pod
#   - must finish running hooks or else it stays in "running" or "terminating"
#   - you must fix the stuck prestart, it will terminate the stuck prestop in 30s
#   - handlers dont log, check the event logs with event or describe
#   - !! handlers may be called multiple times

### Volumes
# - containers have their own isolated file system. volitle for the life of the container
# - seperate object entity & seperate to container storage
# - can be mounted on multiple containers at once
# - there are lots of volume types to use which need to be configured
# - abstracts away suppling storage to consuming storage
# - types
#   - emptyDir - attaches to pod while it exists
#     - medium: memory can create a ramdisk
#   - gcePersistentDisk - google cloud storage
#     - need to setup disk in gcp
#     - subpath - is the path on the disk previously setup
#   - hostPath - only for dev (single node!). mounts files directly from the host node
# - readonly: true set on containers ensures it cannot write to the volume
kubectl create -f storage.yaml
kubectl get po
kubectl exec -it volpod -- sh
# ls /vol1
kubectl delete -f storage.yaml


## Persistent Volumes (PV)
# - usually not provisioned by a developer but an admin
# - has a different lifecycle
#    - 1 provision - admin creates (can be dynamic)
#    - 2 claim - dev creates claim, claim binds if request succeeds or remains unbound
#    - 3 use - like another volume
#    - 4 reclaim - (retain, recycle[deprecated], delete)
# - claim (PVC)
#   - user requests storage
#   - pods use PVC
#   - has it's own lifecycle
# - capacity can be in SI or 2^ suffiex K and Ki respectfully
# - accessModes
#   - ReadWriteOnce - means only one node can mount rw
#   - ReadWriteMany - many nodes can read/write
#   - ReadOnlyMany - many nodes can read
# - PVs have labels, PVCs have label selectors
kubectl create -f pv.yaml
kubectl get pv
kubectl create -f pclaim-pod.yml
kubectl get pvc,pv
kubectl create -f vol-pod.yml
kubectl get po
kubectl exec -it web-server -- sh
# cd /shared; touch willisurvive
kubectl delete -f pvclaim-pod.yml
kubectl create -f pvclaim-pod.yml
kubectl exec -it web-server -- sh
# ls /shared

## dynamic storage provisioning
# - cluster automatically creates PVs to fill PVCs
# - uses the StorageClass object
# - 1. setup storage provisioners
# - 2. setup storageClass
# - 3. dev creates claim
# - 4. k8s creates PV
# - 5. can use the claim as a volume
# - storageClass cannot have labels
# - if the storage class name is an empty string it wont dynamically allocate storage
# - without the storage class name it will attempt to use a default storage class

kubectl get sc
# minikube comes with a default storage class named standard
# kubernetes can dynamically provision the pv to fill a pvc off of the default storageClass
# unless specified, to use a storageClass by name

## Job (controller)
# - a controller which ensures successful completion before being removed
# - a normal pod can be evicted before finishing the job
# - types of jobs
#   - nonparallel
#   - parallel jobs with fixed compleition count
#   - parallel jobs with a task queue
# - jobs create labels and selectors for you
# - restartPolicy can either be onFailure or Never
# - always will never let the pod terminate
# - default of 6 retries
# - fixed compleition
#   - add parallelism field to config
#   - determine how it is compelted is the number of compelted tasks
# - with a task queue
#   - complete when the queue is empty
#   - each pod must know when to terminate  - typically when the queue is empty
#   - when the completion is nil, the success of one pod is the success off all pods
#   - deployments only need a single replica for parallel jobs to run
# - you can use kubectl scale to increase or decrease the number of running jobs
# - the pods stick around when the jobs complete

## job fixed
#commds for container
mkdir -p tmp/1 tmp/2 tmp/3 tmp/4 tmp/5
rmdir $(ls -1 | head -n 1)

kubectl create -f local-storage.yaml # used for example
#kubectl get pvc
kubectl create -f job-fixed.yaml # create our jobs

# check to see its completed
kubectl get po
kubectl describe job folderjob
kubectl logs job.batch/folderjob

# check the volume out to see the directories
minikube ssh
ls /var/local-vol0/demo

# cleanup
kubectl delete -f job-fixed.yaml

## job queues
# commands for containers
# create folders
for i in {1..100}; do mkdir $i; done && mkdir "done"
# test until folders are created
until test -e "done"; do sleep 1; done
# delete folders until all are done
while ls -1 | grep -E "[0-9]+"; do sleep 1 && rmdir $(ls -1 | grep -E "[0-9]+" | head -n 1); done

kubectl create -f job-queue.yaml
#kubectl delete -f job-queue.yaml
# watch the jobs run
kubectl get po -w

kubectl get events
kubectl logs job/rmjob
kubectl describe job mkjob
kubectl describe job rmjob

# check out the directory - should see done folder
minikube ssh

# cleanup
kubectl delete job mkjob
kubectl delete job rmjob

## cronjobs
# - very similar to unix cron jobs - in the same format
# - spec: schedule: "*/1 * * * *"
# - works like the other jobs
# - if a cron job is still running when it is scheduled again it can be controlled with policies
#   - allow, run the job again (default)
#   - forbid, wont run
#   - replace, stops the old job and starts a new job
# - startingdeadlineseconds - if the job hasn't started succesful, it will be considered failed

## stateful/stateless pods
# stateless
# - interchangable, don't maintain any information
# - can be replaced with a new pod
# stateful
# - not interchangable
# - maintains their storage when replaced
# - used with the stateful set controller
# - e.g. databases

## statuful set pod
# - stable identity
# - always deployed and deleted in order
# - own stable storage
# - they are numbered in order statefulpod-0 statefulpod-1
# - they are created in incrementing order and deleted in reverse order
# - if they need to be recreated they will fill the gaps
# - you can rely on these hostnames in applications
# headless service
# - a service without a cluster ip address
# - spec: clusterIP: None
# - provides no loadblanace or proxy
# - maintains a stateless pods dns record turning the dns to stateful
# - headless services get stateful pods their identity
# - can address the pod via service with statefulset.ordinal#.namspace
# - label selector must match the pod labels
# statuful volumes
# - each pod has it's own persistant volume
# - rescheduling a pod will mount the same volume
# - deleting a stateful set wont delete the volume, must be manually done
# creating stateful set
# - spec: serviceName: <same as set label>
# - include a volumeclaimtemplate
#   - list of pvc as mounted as volumes
#   - can specify storageclassname to provision
#   - can omit and use the default storage class
# - can use host to get the # of the stateful pods
# lifecycle
# - spec: containers: lifecycle: postStart
#   - can run a script prior to starting in the pods lifecycle

kubectl create -f stateful-pod.yaml
kubectl delete -f stateful-pod.yaml

kubectl get pods
kubectl get events

## secrets
# types of secrets
# - generic - text
#   - you can pass in files --from-file=secret.txt making key=filename value=filecontents
#   - you can pass literal values --from-literal=key=value
# - tls - certificate
#   - tls --cert=a.cert --key=secret.key
# - config fie
#   - must be base64 encoded
# ways to access
# - by volume
#   - You can mount secerts as a volume and access the keys as files
#   - mounted in ramfs
# - k8s only sends a secret to a node if a pod on that node requires it, reducing some risk
# - secrets are stored in ram and in etcd on disk
# - newer version of k8s can encrypt secrets at rest
# - from there secrets are communicated to kublets/users encrypted (in most distributions)
# - for lots of secerts you can use secretref

# add secrets
kubectl create secret generic --from-literal=thekey=thevalue
echo -n "user1" | base64
# base64 -w 0 # remove any line wrapping
kubectl create -f secret.yaml
kubectl get secret/super-secret
# display the secret values
kubectl get secret/super-secret -o yaml

# use secrets as files
kubectl create -f secret-pod.yaml
kubectl exec -it secret-vol -- sh
ls /secrets
cat /secrets/username

# use secrets as environment variables
kubectl create -f secret-pod.yaml
kubectl exec -it secret-vol -- sh
# look for USERNAME
printenv

# Container registries
# - you can provide a docker register secret with 'create secret docker-registry'

#--- maybe switch to minikube docker and go into the mounted docker socket?
kubectl create secret docker-registry dind --docker-server=unix:///var/local-vol0/socket/docker.sock

# Service Accounts
# - Cluster Accounts are either User accounts or Service Accounts
# - must be authenticated to use the API server
# - container processes can interact with the API with a service account
# - without specified it will have a default service account
# - A service account can have a secret and all pods with tha t
# there's a different default service account for each namspace

kubectl patch serviceaccount/default -p '{"imagePullSecrets": [{"name": "thesecret"}]}'

# Config Map
# - very similar to secrets
# - use for configuration which can change on different clusters
# - you can use them as environment variables env: name: blah valueFrom: configMapKeyRef:
# - for lots of env vars there's a short hand. envFrom: - configMapRef: name: key
# - values are cached when mounted as a volume, can take time to propagate
kubectl create configmap myconfig1 --from-file=properties.conf
kubectl get cm/myconfig1 -o yaml

## Ingress
# - cluster ip service - not accessible outside
# - nodeport and loadbalances are exposed to the outside network
# - ingress also exposed outside the network with more flexibility
#   - ingress object - created from a config file
#   - ingress controller - daemon process to implement the rules
#      - same as replica controllers etc
#      - ingress controllers are not installed by default with an object
# - route incoming connections on http request path
# - TLS termination - https to http internally
# - name-based virtual hosting
# - lots of ingress controller implementations
#   - for example minikube uses nginx which should be deployed on a pod
# - fanout - different paths go to different pods
# - rewrite-target - changes the path to what the backend service expects
# - often deployed in a different namespace and can see all ingress rules
# - cannot define ingress port (80,443 only)
# - hostname only takes domain names, hostname omitted is a wildcard
# - nginx can reroute to https by default
# - can specify backend: for a default backend
# - name based virtual hosting with tls requires server name indication
# - you can point to a secret to assign a certificate with tls:


# build ingress
minikube addons enable ingress
kubectl get po -n ingress-nginx
kubectl create -f ingress-demo.yaml
kubectl apply -f ingress-demo.yaml

# test to see if its deployed
kubectl get ingress
kubectl get service
kubectl describe ing/demo-ingress

minikube ip
sudo echo "$(minikube ip) demo.example" >> /etc/hosts

## Network policy
# - restrict who can communicate with a pod
# - secure multi-tenant clusters by limiting namespaces
# - pod level firewall
# - egress - network traffic leaving the cluster
# - ingress - network traffic originating from the pods
# - create a NetworkPolicy kind
#   - rules apply to the pods selected by the podSelector
# - you can select pods by; podSelector, NamespaceSelector & ipBlock
# - many network policies which are unioned together in the cluster
# - you can select all pods with podSelector: {}
#   - this way you deny by default
# - missing ingress/egress rules will block all traffic
# - you can supply ingress/egress with an empty rule {} to allow traffic
# - if you omit policy type, ingress is default supplied
# - policies aren't enabled by default,
# - big increase in memory footprint, avoid with small cloud plans
# - there are lots of different network plugins
#   - not enabled by default on minikube


## Security Context
# pods:
# - optional field, but should apply anyway
# - you can specify the user to run securityContext: runAsUser: <id>
# - must specify the user id not the name
# - to avoid running as root you can use the runAsNonRoot
# containers:
# - also has the same runasuser fields for just the container
# - priviledged mode gives access to some kernel functionality
# - you can set kernel capaibilities under the securtity context
#   - print capaibilities with capsh
#   - you can add or drop these capabilities
#   - you drop cap_ when specifying
#   - can drop: -all & add what you want
#   - only applys to root users
# - good idea to set the root folder in containers to read only
#   - mounted volumes can still be mounted to be writable
#   - readOnlyRootFilesystem: true
# - can individually request more priviledges than pod configuration
kubectl exec -it ubuntu -- bash
# create user with a group
groupadd app
useradd -g app admin
su admin
id # uid=1001 guid=1001
exit
# modified securtyContext
kubectl create -f ../devops/test-pod.yaml
kubectl exec -it ubuntu -- bash
# show capabilities
capsh --print

## Resource Limits
# - by default uses as much as it can
# - you can set a lower & upper bound
# - cpu resources
#   -> cores 1 / 0.5
#   -> milicpus 500m (thousandths of a core. 50% of 1 core)
# - memory
#   -> bytes
#   -> SI units (powers of 10) K,M,G,T
#   -> power of 2 units Ki,Mi,Gi,Ti
# - upper bounds are specified with limits:
# - lower bounds are specified with requests:
# - nodes can oversubscribe leaving unrequest resources used
# - a pods resource request is the sum of all of it's containers requests
# - node will be scheduled on a node with available resources
#   - if it doesn't have the resources, it will wait until it's free
# - these arent hard limits and containers can be cpu throttled or killed
#   - however, out of memory will kill it with OOM killer
# - Quality of Service - specifies which is least important to be killed
# - QoS are assigned by what resource it requests
#   - is either guarantee, burstable or best effort
#   - can be seen with the describe
#   - guarantee - request = limit or limit=request is specified
#   - burstable - has different limit and guarantee
#   - best effort - does not specify any requests or limits
# - global default
# - used with kind limitRange (min, max and default)
#  - you can also specify a min and max for the namespace
#  - if you go above, the container wont schedule on the namespace
kubectl create -f limit-range.yaml
kubectl get namespaces
kubectl get po -n gogogadget
kubectl describe -n gogogadget po/ubuntu
# should see default and qos as burstable
kubectl delete namespace/gogogadget

# get the resources you can schedule on a node
# look at capacity
kubectl describe nodes

## autoscaling
# - can manually do it with setting the sscale
# - HPA (Horizontal Pod Autoscaler)
#   - object - defines behaviour via metrics which the controller uses
#     - metrics: average cpu utilisation or value
#   - controller - scales the # pods in replica set
#   - targets deployments, replicasets and controllers
# - HPAs can get data from the metrics api
# - custom metrics - come from a more advance metric server
# - scales it up or down to reach an average of the utilisation metric
# - you can target a percentage of resources instead

minikube addons enable metrics-server
kubectl top nodes

# lets scale a fork bomb lol
kubectl create -f hpa.yaml

kubectl exec -it -n gogogadget go-deploy-564b49fc98-jtpdm -- /bin/bash
# :(){ :|:& };:
# check it out
kubectl get po -n gogogadget -w
kubectl get po -n gogogadget
# it scaled lol
kubectl get events -n gogogadget
# the forkbombs get killed eventually from running out of memory OOM

# you can use a command
kubectl autoscale deployment go-deploy --min=1 --max=5 --cpu-percent=50

kubectl delete namespace/gogogadget
# watch out for "thrashing"
# - scaling up and down too soon,  overshooting requirements
# - comes with a scale down delay (default 5m)
# - you can change the downscale delay

# Control which pods get scheduled on which nodes
# - the node could have different capabilities such as SSD or more memory
# - you can use Affinity
#   - node affinity - scheduled on nodes with specific labels
#   - pod affinity - schedule pods where other pods are schedueled
#   - anti-affinity - don't put two pods on the same node
# - two varients:
#   - requiredDuringSchedulingIgnoredDuringExecution
#   - preferredDuringSchedulingIgnoredDuringExecution
#   - pods wont unschedule if the node no longer meets the requirements
#   - preferred may not meet all requirements when scheduling to a node
# - weight: each requirement can have a weight. weight: 1
#   - k8s will try find a node which matches the height weight
# - topology - required. what consisutes colocation
#   - could be the same machine, cloud provider, region etc
#   - could have different keys for different providers
#   - kuberentes.io/hostname - is the same node
# - namespaces, can also schedule on different namespaces.
#  - omitted, it will go from whats in the config

# taints and tolerances
# taint - similar to a label
#   - makes other pods avoid it
# tolerances - how much a pod can take
# three types of effects(noschedule, prefernoschedule, noexecute)
# noexcute will evict intolerant pods

# add label to node
kubectl label node minikube speed=fast
# add taint to node
# node = target type, target label, taint = key, value, effect
kubectl taint node -l speed=fast reservation=store:noschedule
#or
kubectl taint node minikube key=val:PreferNoSchedule
# to remove the taint (minus sign at the end)
kubectl taint node minikube key=val:PreferNoSchedule-

# tolerationSeconds - pod will remain no the node once tainted

## Best Practises
# - avoid using the latest tag on images
# - direct application log messages to STDOUT or STDERROR
# - setup cluster logging
# - avoid adding fields with default values to minimise the complexity
# - container should have one purpose
# - always use a controller to create/manage pods
# - beware of 3rd party images, you can also run security scans
# - avoid being root on the container
# - make the filesystem read only if you can


