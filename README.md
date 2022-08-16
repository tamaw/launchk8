# launchk8

## About

- Learning Kubernetes from the [true kubernetes](true-kubernetes.com) course
- Custom examples demonstrating the learnings
- A project to run GitHub Actions, build Docker images and deploy images into pods
- Two GitHub builds, one for a MUD game, the other for a TUI app
- Kubernetes deployment for the the MUD game

## Highlights

![](https://raw.githubusercontent.com/tamaw/launchk8/main/diagrams/devops.png)
![](https://raw.githubusercontent.com/tamaw/launchk8/main/diagrams/mud-working.png)

## Approach

- Workbooks - `workbooks.sh` show the journey I took to make the product. Including, some of the mistakes I made along the way.
- Runbooks - `runbook.sh` are the simplified set of commands to recreate the project from scratch. The commands are to be run individually and not in a batch.

## Learnings

[Workbook](https://github.com/tamaw/launchk8/blob/main/learnings/truekubes.sh) Includes lecture notes and commands to run examples

- [Pods](https://github.com/tamaw/launchk8/blob/main/learnings/examples/example-pods.yaml)
  - Names, Labels, Querying with labels
  - Namespaces, creating with namespaces
- Controllers
  - [ReplicaSet](https://github.com/tamaw/launchk8/blob/main/learnings/examples/replica.yaml)
    - Scaling up, Naked pods
  - [Deployment](https://github.com/tamaw/launchk8/blob/main/learnings/examples/deployment.yaml)
    - Rollouts, Diagnostics & Revisions
  - [Daemon Set](https://github.com/tamaw/launchk8/blob/main/learnings/examples/daemonset.yaml)
- Services
  - [Service](https://github.com/tamaw/launchk8/blob/main/learnings/examples/service.yaml)
    - Expose, Service Discovery, NodePort
  - [LoadBalancer](https://github.com/tamaw/launchk8/blob/main/learnings/examples/loadbalancer.yaml)
    - No selector, Session affinity
- Additional Kubectl commands
  - patch, apply, attach, copy, port-forward, top
- [Liveness Probes](https://github.com/tamaw/launchk8/blob/main/learnings/examples/liveness-pod.yaml)
  - Handlers, Probe types
  - Lifecycle
    - PostStart, PreStop
    - handlers
- Volumes
  - [Empty Dir](https://github.com/tamaw/launchk8/blob/main/learnings/examples/vol-pod.yaml)
    - types, hostPath, dynamic volumes
  - [Persistent Volumes](https://github.com/tamaw/launchk8/blob/main/learnings/examples/pv.yaml)
    - lifecycle, access modes, storage classes
  - [Persistent Volume Claim](https://github.com/tamaw/launchk8/blob/main/learnings/examples/pvclaim.yaml)
  - [Pod Claim](https://github.com/tamaw/launchk8/blob/main/learnings/examples/pvclaim-pod.yaml)
  - [Local Storage](https://github.com/tamaw/launchk8/blob/main/learnings/examples/local-storage.yaml)
- Jobs
  - [Fixed](https://github.com/tamaw/launchk8/blob/main/learnings/examples/job-fixed.yaml)
    - parallel / nonparallel
    - fixed completions
    - restart policies
  - [Queued](https://github.com/tamaw/launchk8/blob/main/learnings/examples/job-queue.yaml)
    - termination, scaling
  - CronJobs
    - schedule, handle overruns
- [Stateful Pods](https://github.com/tamaw/launchk8/blob/main/learnings/examples/stateful-pod.yaml)
  - DNS, ClusterIP, Rescheduling Order, number names
- [Secrets](https://github.com/tamaw/launchk8/blob/main/learnings/examples/secret.yaml)
  - [Assigned Secret](https://github.com/tamaw/launchk8/blob/main/learnings/examples/secret-pod.yaml)
  - files, certificates or generic values
  - access by volume, env vars
  - Config Maps
- [Ingress](https://github.com/tamaw/launchk8/blob/main/learnings/examples/ingress-demo.yaml)
  - for http, tls termination, name-based virtual hosting
- [NetworkPolicy](https://github.com/tamaw/launchk8/blob/main/learnings/examples/network-policy.yaml)
  - egress, ingress, rules w/ ip tables
- Security Context
  - read only root, kernel capabilities, runAsUser
- [Resource Limits](https://github.com/tamaw/launchk8/blob/main/learnings/examples/limit-range.yaml)
  - unit types, upper/lower bounds, node requests
  - quality of service types
  - limits & requests
  - pod eviction
- [Horizontal AutoScaling](https://github.com/tamaw/launchk8/blob/main/learnings/examples/hpa.yaml)
  - object, metrics, controllers, custom metrics
- Affinity
  - [Pod](https://github.com/tamaw/launchk8/blob/main/learnings/examples/pod-affinity.yaml)
  - [Node](https://github.com/tamaw/launchk8/blob/main/learnings/examples/affinity.yaml)
  - node, pod & and anti
  - weight, topology
- Taints & Tolerances
  - types of effects
  - add labels to nodes

## DevOps Project

A mini project which creates a GitHub build isolated inside of Kubernetes.

### Architecture

- Docker in Docker
  - builds docker images
  - publishes them to the repo
- GitHub agent
  - runs workflow commands triggered by GitHub
  - can trigger builds on docker
  - can make deployments to the node
- Registry
  - Stores the built images
  - Accessible by the node to deploy

![](https://raw.githubusercontent.com/tamaw/launchk8/main/diagrams/infra%20layout.png)

![](https://raw.githubusercontent.com/tamaw/launchk8/main/diagrams/stack.png)

## TODO

- Improve resource allocation
- Add liveliness
- Central logging would be good
