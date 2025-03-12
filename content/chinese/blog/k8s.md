---
title: "Kubernetes学习手册"
date: 2024-12-19T10:40:31+08:00
draft: true  # Is this a draft? true/false！！！
author: ["Yeelight"]
math: false
toc: true
comments: true
---

> From Docs
> [Docs](https://k8s-tutorials.pages.dev/)

# **Kubernetes‘s Overview**

Kubernetes is a portable, extensible, open source platform for managing containerized workloads and services, that facilitates both declarative configuration and automation.
  <!--more-->
[Overview](https://kubernetes.io/docs/concepts/overview/#why-you-need-kubernetes-and-what-can-it-do)

# 基础知识

## **1. 容器**

- Kubernetes 管理容器化应用。容器是一种轻量级的虚拟化技术，它将应用程序及其依赖项打包到一个可移植的单元中。容器使得应用程序可以在不同的环境中一致地运行，而无需担心底层操作系统的差异。
- 常见的容器技术有 Docker，它提供了一种创建、运行和分发容器的方式。

## **2. Pod**

- 在 Kubernetes 中，最小的部署单元是 Pod。一个 Pod 可以包含一个或多个紧密相关的容器，这些容器共享存储、网络和其他资源。
- Pod 中的容器通常是为了共同完成一个特定的任务而组合在一起的。例如，一个 Web 应用程序可能由一个 Web 服务器容器和一个数据库容器组成，它们可以部署在同一个 Pod 中。

## **3. 节点（Node）**

- 节点是 Kubernetes 集群中的工作机器，可以是物理机或虚拟机。每个节点上运行着 Kubernetes 的代理程序（kubelet），负责管理该节点上的容器。
- 节点可以加入或离开集群，Kubernetes 会自动重新调度容器到其他可用的节点上，以确保应用程序的高可用性。

## **4. 服务（Service）**

- 服务是一种抽象，用于定义一组 Pod 的访问方式。它提供了一个稳定的 IP 地址和端口，使得客户端可以通过这个地址访问到一组 Pod，而无需关心 Pod 的具体位置。
- 服务可以实现负载均衡，将请求分发到多个 Pod 上，提高应用程序的性能和可靠性。

## **5. 命名空间（Namespace）**

- 命名空间用于在一个 Kubernetes 集群中划分不同的环境或项目。它可以将资源（如 Pod、服务、配置等）隔离在不同的命名空间中，以便进行多租户管理或资源隔离。
- 不同的命名空间可以有不同的访问控制策略，确保资源的安全性。

# 使用`minikube`部署单机集群

[minikube](https://minikube.sigs.k8s.io/docs/)

**minikube 命令速查**

`minikube stop` 不会删除任何数据，只是停止 VM 和 k8s 集群。

`minikube delete` 删除所有 minikube 启动后的数据。

`minikube ip` 查看集群和 docker enginer 运行的 IP 地址。

`minikube pause` 暂停当前的资源和 k8s 集群

`minikube status` 查看当前集群状态

`minikube service list` 查看当前服务列表

`minikube service ingress-nginx-controller -n ingress-nginx --url`来公开服务

# 使用Kubernetes

如果在生产环境中运行的都是独立的单体服务，那么 Container (容器) 也就够用了，但是在实际的生产环境中，维护着大规模的集群和各种不同的服务，服务之间往往存在着各种各样的关系。而这些关系的处理，才是手动管理最困难的地方。

## Pod

`Pob` 是在 Kubernetes 中创建和管理的、最小的可部署的计算单元。

在k8s中使用 `YAML` 配置文件来创建Pob

如：

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

`deployment`，是用来帮助我们管理 pod。

如：

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hellok8s-deployment # 名字需要是唯一的
spec:
  replicas: 1 # 表示的是部署的 pod 副本数量
  selector: # 用来定义 label 选择器
    matchLabels:
      app: hellok8s # 会管理 (selector) 所有 labels=hellok8s 的 pod
  template: # 用来定义 pod 资源的
    metadata:
      labels:
        app: hellok8s
    spec:
      containers:
        - image: yeelight612/hellok8s:v1
          name: hellok8s-container
```

当自己手动删除一个 `pod` 资源后，deployment 会自动创建一个新的 `pod`，这和我们之前手动创建 pod 资源有本质的区别！这意味着当生产环境管理着成千上万个 pod 时，我们不需要关心每个Pods具体的情况，只需要维护好这份 `deployment.yaml` 文件的资源定义即可。

在升级部署的时候使用 deployment 的确很方便，但是也会带来一个问题，就是所有的副本在同一时间更新，这会导致我们 `hellok8s` 服务在短时间内是不可用的，因为所有 pod 都在升级到 `v2` 版本的过程中，需要等待某个 pod 升级完成后才能提供服务。

这个时候我们就需要滚动更新 (rolling update)，在保证新版本 `v2` 的 pod 还没有 `ready` 之前，先不删除 `v1` 版本的 pod。

rolling update的两个参数：

- [**maxSurge:**](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#max-surge) 最大峰值，用来指定可以创建的超出期望 Pod 个数的 Pod 数量。
- [**maxUnavailable:**](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#max-unavailable,) 最大不可用，用来指定更新过程中不可用的 Pod 的个数上限。

```yaml
# ...
spec:
  strategy:
    rollingUpdate:
    maxSurge: 1
    maxUnavailable: 1
# ...
```

这个参数配置意味着最大可能会创建 4 个 hellok8s pod (replicas + maxSurge)，最小会有 2 个 hellok8s pod 存活 (replicas - maxUnavailable)。

> 如图，很详细的
>

![image.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/07ddfaeb-f1ea-4b98-ad30-66734fc233fd/7064ef9f-a634-4a9b-b8d6-d553fed1e343/image.png)

### **存活探针 (livenessProb)**

```yaml
# ...
    spec:
    containers:
    # ...
          livenessProbe:
            httpGet:
              path: /healthz
              port: 3000
            initialDelaySeconds: 3 # 容器启动后多久开始探测
            periodSeconds: 3 # 探测周期
# ...
```

- `initialDelaySeconds`：容器启动后要等待多少秒后才启动存活和就绪探测器， 默认是 0 秒，最小值是 0。
- `periodSeconds`：执行探测的时间间隔（单位是秒）。默认是 10 秒。最小值是 1。
- `timeoutSeconds`：探测的超时后等待多少秒。默认值是 1 秒。最小值是 1。
- `successThreshold`：探测器在失败后，被视为成功的最小连续成功数。默认值是 1。 存活和启动探测的这个值必须是 1。最小值是 1。
- `failureThreshold`：当探测失败时，Kubernetes 的重试次数。 对存活探测而言，放弃就意味着重新启动容器。 对就绪探测而言，放弃意味着 Pod 会被打上未就绪的标签。默认值是 3。最小值是 1。

## **Service**

`kubernetes` 提供了一种名叫 `Service` 的资源帮助解决这些问题，它为 pod 提供一个稳定的 Endpoint。Service 位于 pod 的前面，负责接收请求并将它们传递给它后面的所有pod。一旦服务中的 Pod 集合发生更改，Endpoints 就会被更新，请求的重定向自然也会导向最新的 pod。

Kubernetes `ServiceTypes` 允许指定你所需要的 Service 类型，默认是 `ClusterIP`。`Type` 的值包括如下：

- [`ClusterIP`](https://kubernetes.io/docs/concepts/services-networking/service/#type-clusterip)：通过集群的内部 IP 暴露服务，选择该值时服务只能够在集群内部访问。 这也是默认的 `ServiceType`。
- [**`NodePort`**](https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport)：通过每个节点上的 IP 和静态端口（`NodePort`）暴露服务。 `NodePort` 服务会路由到自动创建的 `ClusterIP` 服务。 通过请求 `<节点 IP>:<节点端口>`，你可以从集群的外部访问一个 `NodePort` 服务。

    ![image.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/07ddfaeb-f1ea-4b98-ad30-66734fc233fd/e8285db0-e554-4d23-9e92-6b48b191960b/image.png)

- [**`LoadBalancer`**](https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer)：使用云提供商的负载均衡器向外部暴露服务。 外部负载均衡器可以将流量路由到自动创建的 `NodePort` 服务和 `ClusterIP` 服务上。
- [**`ExternalName`**](https://kubernetes.io/docs/concepts/services-networking/service/#externalname)：通过返回 `CNAME` 和对应值，可以将服务映射到 `externalName` 字段的内容（例如，`foo.bar.example.com`）。 无需创建任何类型代理。

相关`service-hellok8s-clusterip.yaml`：

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

被 selector 选中的 Pod，就称为 Service 的 Endpoints。它维护着 Pod 的 IP 地址，只要服务中的 Pod 集合发生更改，Endpoints 就会被更新。

## Ingress

[**Ingress**](https://kubernetes.io/docs/concepts/services-networking/ingress/) 公开从集群外部到集群内[**服务**](https://kubernetes.io/docs/concepts/services-networking/service/)的 HTTP 和 HTTPS 路由。 流量路由由 Ingress 资源上定义的规则控制。Ingress 可为 Service 提供外部可访问的 URL、负载均衡流量、 SSL/TLS，以及基于名称的虚拟托管。

![image.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/07ddfaeb-f1ea-4b98-ad30-66734fc233fd/5a7ee6a2-d9ca-40ce-b439-8bd79be5686d/image.png)

## **Namespace**

k8s 提供了名为 Namespace 的资源来帮助隔离不同环境中的不同资源。同一名字空间内的资源名称要唯一，但跨名字空间时没有这个要求。

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

使用 `kubectl` 应用和查看 `namespace`

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

## Kubectl 的基础使用

[基础使用](https://kubernetes.io/docs/reference/kubectl/quick-reference)

### 1. 集群信息

查看集群信息

```bash
kubectl cluster-info
```

查看信息

```bash
kubectl get nodes

kubectl get pods
# kubectl get pod -o wide # 获取 Pod 更多的信息

kubectl get deployments

kubectl get endpoints

kubectl get service
```

### 2. 资源管理

创建资源

```bash
kubectl create -f <yaml文件>
```

应用资源配置

```bash
kubectl apply -f <yaml文件>
```

查看资源

```bash
kubectl get <资源类型>

kubectl get nodes  # 检查节点状态
kubectl get pods --all-namespaces  # 检查所有命名空间中的 pods
kubectl get pods
kubectl get services
kubectl get deployments
```

查看资源详细信息

```bash
kubectl describe <资源类型> <资源名称>

kubectl describe pod hellok8s-deployment-7ccb84d746-685r5
```

删除资源

```bash
kubectl delete <资源类型> <资源名称>

kubectl delete deployment,service --all
```

### 3. Pod 操作

查看 Pod 日志

```bash
kubectl logs <pod名称>

# kubectl logs --follow nginx-pod
```

进入 Pod 内部

```bash
kubectl exec  -it <pod名称> -- /bin/bash

# **kubectl exec -it nginx-pod -- /bin/bash

# kubectl exec [POD] [COMMAND] is DEPRECATED and will be removed in a future version. Use kubectl exec [POD] -- [COMMAND] instead.
# This command has expired**
```

端口转发

```bash
kubectl port-forward <pod名称> <本地端口>:<pod端口>

# kubectl port-forward nginx-pod 4000:80
```

### 4. 部署管理

扩缩容

```bash
kubectl scale deployment <部署名称> --replicas=<副本数>
```

查看部署状态

```bash
kubectl rollout status deployment/<部署名称>
```

回滚部署

```bash
# 查看历史版本
kubectl rollout history deployment <部署名称>
# 回滚到指定版本
kubectl rollout undo deployment <部署名称>
```

其他

```bash
kubectl rollout history deployment <部署名称>

kubectl rollout undo deployment/hellok8s-deployment --to-revision=2
```

### 5. 命名空间操作

创建命名空间

```bash
kubectl create namespace <命名空间名称>
```

切换命名空间

```bash
kubectl config set-context --current --namespace=<命名空间名称>
```

### 6. 配置管理

查看 Kubectl 配置

```bash
kubectl config view
```

切换集群上下文

```bash
kubectl config use-context <上下文名称>
```

### 7. 帮助和调试

获取命令帮助

```bash
kubectl --help
kubectl <命令> --help
```

查看 API 资源

```bash
kubectl api-resources
```

解释资源字段

```bash
kubectl explain <资源类型>
```

# 问题集锦

1. docker 的网络问题

    [1](https://neucrack.com/p/286)
    [2](https://gist.github.com/y0ngb1n/7e8f16af3242c7815e7ca2f0833d3ea6)
    [3](https://singee.atlassian.net/wiki/spaces/MAIN/pages/5079084/Cloudflare+Workers+Docker)

2. 注意需要提前启动minikube

    使用的是 Minikube，请尝试以下步骤：

    ```bash
    minikube status
    ```

    如果 Minikube 未运行，请启动它：

    ```bash
    minikube start --vm-driver docker --container-runtime=docker
    ```

3. **Pod 与 Container 的不同**

    在最内层是我们的服务 `nginx`，运行在 `container` 容器当中， `container` (容器) 的本质是进程，而 `pod` 是管理这一组进程的资源。

    ![image.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/07ddfaeb-f1ea-4b98-ad30-66734fc233fd/f0643f1b-4ef5-4da8-8a41-55b8d0654a1b/image.png)

    所以自然 `pod` 可以管理多个 `container`，在某些场景例如服务之间需要文件交换(日志收集)，本地网络通信需求(使用 localhost 或者 Socket 文件进行本地通信)，在这些场景中使用 `pod` 管理多个 `container` 就非常的推荐。

4. 在deployment中，所创造的pods和自己用pods的yaml创建的pods有什么区别

    ![image.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/07ddfaeb-f1ea-4b98-ad30-66734fc233fd/410f4c5e-afbf-4e5b-8cbb-aed4f1be610a/image.png)

5. 无法通过`minikube ip`获取到的ip地址来请求

    如果本地使用 Docker Desktop（minikube start --driver=docker）的话，那你大概率无法通过`minikube ip`获取到的ip地址来请求,因为 docker 部分网络限制导致无法通过 ip 直连 docker container，这代表 NodePort 类型的 Service、Ingress 组件都无法通过 minikube ip 提供的 ip 地址来访问。无法直接访问Node IP。你可以通过`minikube service service-hellok8s-nodeport --url`来公开服务，然后通过`curl`或者浏览器访问。

6. 利用affinity来控制实例的pod分布

    [Affinity Demo](https://www.notion.so/Affinity-Demo-123a4c97565c8083a586c8c3b00d6a02?pvs=21)
