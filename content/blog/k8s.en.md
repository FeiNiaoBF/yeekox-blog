---
title: "Kubernetes Preliminary Learning Guide"
date: 2024-12-19T10:40:31+08:00
draft: false
authors:
  - name: "Yeelight"
    link: https://github.com/FeiNiaoBF
    image: https://github.com/FeiNiaoBF.png

math: false
toc: true
comments: true
tags:
  - Kubernetes
  - Container Orchestration
  - Cloud Native
---

> From Docs
> [Docs](https://k8s-tutorials.pages.dev/)

## **Kubernetes's Overview**

Kubernetes is a portable, extensible, open source platform for managing containerized workloads and services, that facilitates both declarative configuration and automation.
  <!--more-->
[Overview](https://kubernetes.io/docs/concepts/overview/#why-you-need-kubernetes-and-what-can-it-do)

## **Basic Concepts**

### **Containers**

- Kubernetes manages containerized applications. A container is a lightweight virtualization technology that packages an application and its dependencies into a portable unit. Containers enable applications to run consistently across different environments without worrying about underlying OS differences.
- A common container technology is Docker, which provides a way to create, run, and distribute containers.

### **Pod**

- In Kubernetes, the smallest deployment unit is a Pod. A Pod can contain one or more closely related containers that share storage, network, and other resources.
- Containers in a Pod are typically grouped together to accomplish a specific task. For example, a web application might consist of a web server container and a database container deployed in the same Pod.

### **Node**

- A node is a worker machine in a Kubernetes cluster, which can be a physical machine or a virtual machine. Each node runs the Kubernetes agent (kubelet), responsible for managing containers on that node.
- Nodes can join or leave the cluster, and Kubernetes automatically reschedules containers to other available nodes to ensure high availability of applications.

### **Service**

- A Service is an abstraction that defines how to access a set of Pods. It provides a stable IP address and port, allowing clients to access a group of Pods without worrying about the specific location of individual Pods.
- Services enable load balancing, distributing requests across multiple Pods to improve application performance and reliability.

### **Namespace**

- Namespaces are used to partition different environments or projects within a Kubernetes cluster. They can isolate resources (such as Pods, Services, configurations) into different namespaces for multi-tenant management or resource isolation.
- Different namespaces can have different access control policies to ensure resource security.

## **Deploying a Single-Node Cluster with `minikube`**

[minikube](https://minikube.sigs.k8s.io/docs/)

minikube command quick reference:

`minikube stop` does not delete any data, only stops the VM and k8s cluster.

`minikube delete` removes all data created after minikube startup.

`minikube ip` checks the IP address of the cluster and docker engine.

`minikube pause` pauses the current resources and k8s cluster.

`minikube status` checks the current cluster status.

`minikube service list` lists current services.

`minikube service ingress-nginx-controller -n ingress-nginx --url` to expose a service.

## Using Kubernetes

If you're running independent monolithic services in a production environment, containers alone might suffice. But in real production environments, you're maintaining large-scale clusters with various services, and there are often complex relationships between services. Handling these relationships is the hardest part of manual management.

### Pod

`Pod` is the smallest deployable computing unit that can be created and managed in Kubernetes.

In k8s, you use `YAML` configuration files to create Pods.

For example:

```yaml
# nginx.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
spec:
  containers:
    - name: nginx-container
      image: nginx
```

## Deployment

[Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment)

`deployment` helps us manage pods.

For example:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hellok8s-deployment # name must be unique
spec:
  replicas: 1 # number of pod replicas to deploy
  selector: # defines label selector
    matchLabels:
      app: hellok8s # manages all pods with labels=hellok8s
  template: # defines pod resource
    metadata:
      labels:
        app: hellok8s
    spec:
      containers:
        - image: yeelight612/hellok8s:v1
          name: hellok8s-container
```

When you manually delete a `pod` resource, the deployment automatically creates a new `pod` — this is fundamentally different from manually creating pod resources earlier! This means when a production environment manages thousands of pods, you don't need to worry about the specifics of each Pod — you just need to maintain this `deployment.yaml` resource definition.

While using deployment for upgrades is convenient, it introduces a problem: all replicas update simultaneously, causing your `hellok8s` service to be briefly unavailable since all pods are upgrading to `v2` and need to complete the upgrade before serving traffic.

This is when we need rolling updates — ensuring `v1` pods aren't deleted before `v2` pods become `ready`.

Two parameters for rolling update:

- [**maxSurge:**](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#max-surge) Maximum surge, specifies the number of Pods that can be created beyond the desired count.
- [**maxUnavailable:**](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#max-unavailable,) Maximum unavailable, specifies the upper limit of Pods that can be unavailable during the update.

```yaml
# ...
spec:
  strategy:
    rollingUpdate:
    maxSurge: 1
    maxUnavailable: 1
# ...
```

This parameter configuration means at most 4 hellok8s pods may be created (replicas + maxSurge), and at minimum 2 hellok8s pods will remain alive (replicas - maxUnavailable).

> See the diagram below — very detailed
>

![image.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/07ddfaeb-f1ea-4b98-ad30-66734fc233fd/7064ef9f-a634-4a9b-b8d6-d553fed1e343/image.png)

### **Liveness Probe (livenessProbe)**

```yaml
# ...
    spec:
    containers:
    # ...
          livenessProbe:
            httpGet:
              path: /healthz
              port: 3000
            initialDelaySeconds: 3 # seconds to wait before starting probes after container starts
            periodSeconds: 3 # probe interval
# ...
```

- `initialDelaySeconds`: seconds to wait after container starts before starting liveness and readiness probes. Default 0, minimum 0.
- `periodSeconds`: interval between probes (in seconds). Default 10, minimum 1.
- `timeoutSeconds`: timeout after which the probe is considered failed. Default 1, minimum 1.
- `successThreshold`: minimum consecutive successes for a probe to be considered successful after failure. Default 1. For liveness and startup probes, this must be 1. Minimum 1.
- `failureThreshold`: number of retries for Kubernetes when a probe fails. For liveness probes, giving up means restarting the container. For readiness probes, giving up means the Pod is marked as not ready. Default 3, minimum 1.

## **Service**

`Kubernetes` provides a resource called `Service` to help solve these problems — it provides a stable Endpoint for pods. Service sits in front of pods, receiving requests and passing them to all pods behind it. When the set of Pods in a Service changes, Endpoints are updated, and request redirection naturally points to the latest pods.

Kubernetes `ServiceTypes` allow you to specify the type of Service you need, defaulting to `ClusterIP`. `Type` values include:

- [`ClusterIP`](https://kubernetes.io/docs/concepts/services-networking/service/#type-clusterip): Exposes the Service on a cluster-internal IP. Choosing this value makes the Service only reachable from within the cluster. This is the default `ServiceType`.
- [**`NodePort`**](https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport): Exposes the Service on each Node's IP at a static port (`NodePort`). A `NodePort` service routes to an automatically created `ClusterIP` service. By requesting `<Node IP>:<NodePort>`, you can access a `NodePort` service from outside the cluster.

    ![image.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/07ddfaeb-f1ea-4b98-ad30-66734fc233fd/e8285db0-e554-4d23-9e92-6b48b191960b/image.png)

- [**`LoadBalancer`**](https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer): Exposes the Service externally using a cloud provider's load balancer. External load balancers route traffic to automatically created `NodePort` and `ClusterIP` services.
- [**`ExternalName`**](https://kubernetes.io/docs/concepts/services-networking/service/#externalname): Maps the Service to the contents of the `externalName` field (e.g., `foo.bar.example.com`) by returning a `CNAME` with its value. No proxying of any kind is set up.

Related `service-hellok8s-clusterip.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: service-hellok8s-clusterip
spec:
  type: ClusterIP
  selector:
    app: hellok8s
  ports:
  - port: 3000
    targetPort: 3000
```

### Endpoint

Pods selected by the selector are called the Service's Endpoints. They maintain the IP addresses of Pods — whenever the set of Pods in the Service changes, Endpoints are updated.

## Ingress

[**Ingress**](https://kubernetes.io/docs/concepts/services-networking/ingress/) exposes HTTP and HTTPS routes from outside the cluster to [**services**](https://kubernetes.io/docs/concepts/services-networking/service/) within the cluster. Traffic routing is controlled by rules defined on the Ingress resource. Ingress can provide Services with externally reachable URLs, load balance traffic, terminate SSL/TLS, and offer name-based virtual hosting.

![image.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/07ddfaeb-f1ea-4b98-ad30-66734fc233fd/5a7ee6a2-d9ca-40ce-b439-8bd79be5686d/image.png)

## **Namespace**

k8s provides a resource called Namespace to help isolate different resources across different environments. Resource names must be unique within the same namespace, but this requirement doesn't apply across namespaces.

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: dev

---

apiVersion: v1
kind: Namespace
metadata:
  name: test
```

Apply and view `namespace` using `kubectl`:

```powershell
PS E:\User\work\gowork\k8s\k8s> kubectl apply -f .\namespace.yaml
namespace/dev created
namespace/test created
PS E:\User\work\gowork\k8s\k8s> kubectl get namespaces
NAME              STATUS   AGE
default           Active   13d
dev               Active   14s
ingress-nginx     Active   5d22h
kube-node-lease   Active   13d
kube-public       Active   13d
kube-system       Active   13d
test              Active   14s
```

## Basic Kubectl Usage

[Basic Usage](https://kubernetes.io/docs/reference/kubectl/quick-reference)

### 1. Cluster Information

View cluster information:

```bash
kubectl cluster-info
```

View information:

```bash
kubectl get nodes

kubectl get pods
# kubectl get pod -o wide # get more Pod information

kubectl get deployments

kubectl get endpoints

kubectl get service
```

### 2. Resource Management

Create resources:

```bash
kubectl create -f <yaml file>
```

Apply resource configuration:

```bash
kubectl apply -f <yaml file>
```

View resources:

```bash
kubectl get <resource type>

kubectl get nodes  # check node status
kubectl get pods --all-namespaces  # check pods in all namespaces
kubectl get pods
kubectl get services
kubectl get deployments
```

View resource details:

```bash
kubectl describe <resource type> <resource name>

kubectl describe pod hellok8s-deployment-7ccb84d746-685r5
```

Delete resources:

```bash
kubectl delete <resource type> <resource name>

kubectl delete deployment,service --all
```

### 3. Pod Operations

View Pod logs:

```bash
kubectl logs <pod name>

# kubectl logs --follow nginx-pod
```

Enter a Pod:

```bash
kubectl exec  -it <pod name> -- /bin/bash

# **kubectl exec -it nginx-pod -- /bin/bash

# kubectl exec [POD] [COMMAND] is DEPRECATED and will be removed in a future version. Use kubectl exec [POD] -- [COMMAND] instead.
# This command has expired**
```

Port forwarding:

```bash
kubectl port-forward <pod name> <local port>:<pod port>

# kubectl port-forward nginx-pod 4000:80
```

### 4. Deployment Management

Scale up/down:

```bash
kubectl scale deployment <deployment name> --replicas=<replica count>
```

Check deployment status:

```bash
kubectl rollout status deployment/<deployment name>
```

Rollback deployment:

```bash
# View rollout history
kubectl rollout history deployment <deployment name>
# Rollback to a specific revision
kubectl rollout undo deployment <deployment name>
```

Other:

```bash
kubectl rollout history deployment <deployment name>

kubectl rollout undo deployment/hellok8s-deployment --to-revision=2
```

### 5. Namespace Operations

Create a namespace:

```bash
kubectl create namespace <namespace name>
```

Switch namespace:

```bash
kubectl config set-context --current --namespace=<namespace name>
```

### 6. Configuration Management

View kubectl configuration:

```bash
kubectl config view
```

View current context:

```bash
kubectl config current-context
```

### 7. Troubleshooting

View events:

```bash
kubectl get events
# kubectl get events --watch
```

View resource usage:

```bash
kubectl top nodes
kubectl top pods
```

Check API resources:

```bash
kubectl api-resources
```

Explain resources:

```bash
kubectl explain pods
kubectl explain deployment.spec
```

### 8. Common Operations Summary

| Command | Description |
|---------|-------------|
| `kubectl get all` | Get all resources |
| `kubectl get pods -w` | Watch pod status changes |
| `kubectl apply -f <file>` | Apply configuration file |
| `kubectl delete -f <file>` | Delete resources defined in file |
| `kubectl logs <pod> -c <container>` | View specific container logs |
| `kubectl exec <pod> -- <command>` | Execute command in pod |
| `kubectl port-forward <pod> <local>:<remote>` | Port forwarding |
| `kubectl describe <resource> <name>` | Resource details |
| `kubectl explain <resource>` | Resource field documentation |

Using `--help` is always a good idea:

```bash
kubectl --help
kubectl get --help
kubectl run --help
```