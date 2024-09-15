把service 想象成一个独立的负载均衡主机，当用户请求命中这条规则，内核中的IPVS规则只记录 Service 的Cluster IP，然后会把请求转发至这台独立的负载均衡主机 也就是Service，但service 返回的地址可能不在你放问的这台主机上
service 调度器算法可以修改




# Kubernetes

## 基础概念

什么是kubernetes

### 什么是Kubernetes集群？

Master：控制平面

Worker：工作平面

有效的Kubernetes部署称为集群，也就是一组运行Linux容器的主机

可以将 Kubernetes 集群可视化为两个部分：控制平面与计算设备（或称为工作节点）

控制平面负责维护集群的预期状态，例如运行哪个应用以及使用哪个容器镜像，工作节点则负责应用和工作

负载的实际运行

 控制平面接受来自管理员（或 DevOps 团队）的命令，并将这些指令转发给工作节点



### Kubernetes系统组件

注意：Pod是K8s中最小的调度单位，因此Pod中多个容器都是统一调度

用户通过调用 api-server 来执行某些操作(创建、删除等)，创建请求之后由 Scheduler 负责在众多Node节点（工作节点）通过一系列调度策略和调度算法，把Pod 调度至工作节点，之后由该节点的Kubelet负责管理该节点上的容器和 Pod。它监视节点上的容器运行时状态，并与主控制平面（通常是 API 服务器）通信以获取分配给该节点的任务并报告节点和容器的状态。如Pod挂了Kubelet会重启此Pod，但是如果节点因为某种原因变得不可用，比如节点故障、网络故障等，那么该节点上的 Kubelet 也会停止工作，无法继续监视和管理该节点上的 Pod。在这种情况下，Kubernetes 控制平面通常会通过其他机制（例如控制器）检测到节点的不可用，并且会采取措施，例如重新调度 Pod 到其他可用节点上，以确保应用程序的高可用性和可靠性。controller manager 来确保我们创建的Pod健康性，如果Pod少了一个，他会自动请求Api-server 重新创建一个出来。



Etcd负责存储 raft协议确保数据一致性（分布式，自带集群），etcd底层存储引擎他没有固定格式，因此我们要通过Api server 往etcd中存取数据，Api-server的数据格式是有要求的，必须满足要求才可以存

在 Kubernetes API 中，用于判断请求的格式是否正确的关键组件是 Admission Controller。

Admission Controller 在 API 请求到达 API 服务器之后对其进行拦截，并对请求中的对象进行验证。它可以执行各种操作，例如检查对象的格式、应用默认值、强制执行安全策略等。Admission Controller 可以确保在对象被持久化到 etcd 之前，对其进行必要的验证和修改。

Kubernetes 中有许多内置的 Admission Controller，例如 NamespaceLifecycle、ResourceQuota、PodSecurityPolicy 等。此外，还可以编写自定义的 Admission Controller，以满足特定的需求或实现自定义的验证逻辑。



对于每个节点我们要运行容器/Pod，不论是api-server还是controller manager，他们只是发出运行Pod/容器的指令，而真正运行容器负责管理节点上的容器和Pod的 kubelet，由它负责执行由 API 服务器下发的指令，比如创建、删除、修改 Pod 等。Kubelet 通过与 Docker、containerd 或其他符合容器运行时接口（CRI）的容器运行时进行交互，来管理容器的生命周期，并监视 Pod 的运行状态，并将状态报告回 API 服务器。



![image-20240325195537708](../images/image-20240325195537708.png)



REST ful ：类似于面向对象，把类抽象成资源对象，然后遵循类的规范，像字段赋值/类赋值，创建出的对象

资源对象被看作是面向对象编程中的类，而创建出来的实例则类似于类的实例。每个资源对象都具有一组属性和状态，并且可以通过 RESTful API 来对其进行 CRUD 操作（创建、读取、更新、删除）。

例子：

1. **房屋设计图纸（Resource Class）**：假设我们有一套房屋设计图纸，定义了房屋的结构、大小、布局等属性，这可以看作是房屋类（类似于 Kubernetes 中的资源类）。
2. **按设计图纸建造房屋（Resource Instance）**：基于设计图纸，我们可以建造出一栋具体的房屋，每栋房屋都是该设计图纸的一个实例（类似于 Kubernetes 中的资源实例）。每栋房屋都有自己的地址、外观、内部装修等属性。我们可以修改图纸上的值，或者给他赋值创建出不同的房子
3. **建造工程（API）**：建造房屋的过程需要进行一系列操作，比如打地基、搭建框架、安装管道等。这些操作可以看作是建造房屋的 API，您可以通过这些操作来管理房屋的建造过程。（管理，控制，查看等）
4. **施工队伍（Kubelet）**：施工队伍是实际负责房屋建造工作的人员，他们按照设计图纸和施工计划来完成房屋的建造。在 Kubernetes 中，Kubelet 类似于施工队伍，负责管理节点上的容器和 Pod。
5. **监理（Controller Manager）**：监理负责确保房屋按照设计要求进行建造，如果出现问题，会及时采取措施进行调整。在 Kubernetes 中，Controller Manager 类似于监理，负责确保集群中的资源状态符合用户定义的预期。

kubelet 负责管理节点上的容器和 Pod 的运行状态，而 controller manager 则负责管理集群中各种资源的状态

Controller Manager  == 包含多种不同的Controlller 他们都用来管理不同的资源对象

Kube-Proxy 用于把每个节点扩展为可编程的负载均衡器，

iptables 因为iptables规则是线性检查的。当规则数量增加时，iptables 需要逐条检查每个规则，这可能导致性能下降，特别是在规则数量非常大的情况下。 ipvs 



### Service

服务发现，服务注册 

为了应对后端 Pod 不稳定的 IP 地址或者扩缩容的情况，我们需要负载均衡器自动将新的 Pod 加入到负载均衡中。

我们给每个创建或即将创建的Pod 打上标签，随后Service 配置过滤标签，就是只要Pod满足我的标签，但凡能匹配到的Pod 都会被我

如果我们定义了一组Pod用来接收用户请求，因此我们需要负载均衡器来满足我们后端Pod 不断变化的需求，

Service 为每一组 Pod 提供了一个虚拟的服务入口点，这组 Pod 可以位于集群中的不同节点上。为了实现负载均衡，需要在每个节点上都配置相同的负载均衡规则，以确保无论请求到达哪个节点，都可以正确地转发到后端的 Pod。



##### **Pod请求pod**

首先，一个 Pod 发出请求，请求可能是发送到另一个 Pod，请求到达内核的 IPVS 规则：请求首先到达发送请求的 Pod 所在节点的内核，那么请求会被 IPVS 规则拦截，根据 IPVS 规则的解析，请求最终被转发到相应的 Service IP。

##### 用户请求Pod

我们事先创建了Service，并且把Pod 80 端口映射到Node节点的32000端口

客户端请求首先到达节点的指定端口（例如 10.0.0.200:32000），求先到达此Node 内核空间的 input链前 然后由节点的 iptables 规则进行匹配，（如果你访问32000 就对应某个Service 的 Cluster IP ）当请求匹配到相应的 Service 时，iptables 会将请求转发到 Service 的 Cluster IP。Service 接收到请求后，根据其负载均衡策略选择一个后端 Pod，并将请求转发给该 Pod。如果选择的后端 Pod 正好位于请求所在的节点上，请求将直接在节点内部被转发到该 Pod；如果后端 Pod 不在同一节点，请求将通过网络被路由到对应节点，并在那里被进一步转发给目标 Pod。



当用户请求的 Pod 不在当前节点时，当前节点的 kube-proxy 会执行以下步骤来确定目标 Pod 在哪个节点，并对请求进行 VXLAN 封装：

IPVS 规则本身不会记录后端 Pod 的具体地址，它只会将请求转发到 Service 的 IP 地址上。一旦请求到达 Service 的 IP 地址，实际的后续转发是由 kube-proxy 和 Service 实现的。

当用户请求到达当前节点时，IPVS 规则会将请求转发到 Service 的 Cluster IP 地址上，根据负载均衡策略选择一个后端 Pod，并将请求转发给该 Pod，如果选择的后端 Pod 不在当前节点上，那么当前节点的 kube-proxy， 会查询 Endpoints API，该 API 包含了与 Service 相关联的后端 Pod 的信息，包括它们所在的节点。一旦获取到目标 Pod 所在的节点信息，就会通过网络插件转发到对方主机

通常情况下，Flannel 会通过 etcd（或其他 key-value 存储）来存储节点之间的网络拓扑信息，包括节点的 IP 地址和 VTEP 接口的 MAC 地址。当一个节点需要发送数据到另一个节点时，它会查询 etcd 来获取目标节点的 VTEP 接口的 MAC 地址。



### kubernetes集群架构

Kubernetes属于典型的Server-Client形式的二层架构

Master主要由API Server、Controller-Manager和Scheduler三个组件，以及一个用于集群状态存储的Etcd存储服务组成，它们构成整个集群的控制平面。

而每个Node节点则主要包含Kubelet、Kube Proxy及容器运行时（docker是最为常用的实现）三个组件，它们承载运行各类应用容器。

![image-20240325222807403](../images/image-20240325222807403.png)





**Pod中容器常用的共享资源**

Pod是共享Network、IPC和UTS名称空间以及存储资源的**容器集**

各容器共享网络协议栈、网络设备、路由、IP地址和端口等，但Mount、PID和USER仍隔离

每个Pod上还可附加一个“存储卷（Volume）”作为该“主机”的外部存储，独立于Pod的生命周期，可由Pod内的各容器共享



Pod具有动态性，其IP地址也会在基于配置清单重构后重新进行分配，因而需要服务发现机制的支撑

#### Kubernetes网络模型

##### Kubernetes网络模型

kubernetes集群上会存在三个分别用于节点、Pod和Service的网络，于worker上完成交汇，由节点内核中的路由模块，以及iptables/netfilter和ipvs等完成网络间的流量转发



**节点网络**

集群节点间的通信网络，并负责打通与集群外部端点间的通信

网络及各节点地址需要于Kubernetes部署前完成配置，非由Kubernetes管理，因而，需要由管理员手动进行，或借助于主机虚拟化管理程序进行

**Pod网络**

为集群上的Pod对象提供的网络

虚拟网络，**需要经由CNI网络插件实现**，例如Flannel、Calico、Cilium等

**Service网络**

在部署Kubernetes集群时指定，各Service对象使用的地址将从该网络中分配

 Service对象的IP地址存在于其相关的iptables或ipvs规则中，由Kubernetes集群自行管理

#### Kubernetes集群中的通信流量

Kubernetes网络中主要存在4种类型的通信流量

同一Pod内的容器间通信、Pod间的通信、Pod与Service间的通信、集群外部流量与Service间的通信

Pod网络需要借助于第三方兼容CNI规范的网络插件完成，这些插件需要满足以下功能要求

所有Pod间均可不经NAT机制而直接通信，所有节点均可不经NAT机制直接与所有Pod通信，所有Pod对象都位于同一平面网络中



#### Kubernetes集群组件运行模式

部署集群：

​	Master：3，5，7，

​	Worker：取决于业务规模



**独立组件模式**

除Add-ons以外，各关键组件以二进制方式部署于节点上，并运行于守护进程，各Add-ons以Pod形式运行。





**静态Pod模式**

控制平面各组件以静态Pod对象运行于Master主机之上

kubelet和 CRI 以二进制部署，运行为守护进程，kube-proxy等则以Pod形式运行

集群启动之前需要依赖的组件以静态Pod方式部署







### Kubeasz方式部署

```
apt update && apt install ansible -y
```

配置要部署节点免密登录

```shell
ssh-keygen -t rsa-sha2-512 -b 4096
apt install sshpass #安装sshpass命令⽤于同步公钥到各k8s服务器

vim key-scp.sh
#!/bin/bash
#
#********************************************************************
#Author:            lixijun
#QQ:                505697096
#Date:              2024-03-26
#FileName:          key-scp.sh
#*

IP=" #⽬标主机列表
10.0.0.201
10.0.0.202
"

REMOTE_PORT="22"
REMOTE_USER="root"
REMOTE_PASS="123456"

for REMOTE_HOST in ${IP};do
	REMOTE_CMD="echo ${REMOTE_HOST} is successfully!"
    #添加⽬标远程主机的公钥(连接对方 并输入YES)
	ssh-keyscan -p "${REMOTE_PORT}" "${REMOTE_HOST}" >> ~/.ssh/known_hosts
	#通过sshpass配置免秘钥登录、并创建python3软连接
	sshpass -p "${REMOTE_PASS}" ssh-copy-id "${REMOTE_USER}@${REMOTE_HOST}"
	ssh ${REMOTE_HOST} ln -sv /usr/bin/python3 /usr/bin/python #必须v都要做包括本机
	echo ${REMOTE_HOST} 免秘钥配置完成!
done
```





按照官方要求下载按照脚本

```bash
#详情要查看官方文档
wget https://github.com/easzlab/kubeasz/releases/download/3.6.3/ezdown
chmod +x ./ezdown
./ezdown -D

#运行这个脚本会自动按照Docker，然后去Dcoker仓库下载镜像，运行镜像，然后再镜像中下载二进制文件，再把二进制文件拷贝到宿主机
tree  /etc/kubeasz/
他的逻辑就是，创建好service文件，把二进制和service 文件 CP到目标主机 运行
```



创建集群

```bash
cd /etc/kubeasz/
./ezctl  --help

#创建集群模板
[root@ubuntu2204 kubeasz]#./ezctl new k8s-cluster1
2024-03-26 10:08:44 DEBUG generate custom cluster files in /etc/kubeasz/clusters/k8s-cluster1
2024-03-26 10:08:44 DEBUG set versions
2024-03-26 10:08:44 DEBUG cluster k8s-cluster1: files successfully created.
2024-03-26 10:08:44 INFO next steps 1: to config '/etc/kubeasz/clusters/k8s-cluster1/hosts'
2024-03-26 10:08:44 INFO next steps 2: to config '/etc/kubeasz/clusters/k8s-cluster1/config.yml'
创建多个或不同的集群会生成不同的集群模板，用来管理不同的集群部署

#生成的这两个文件非常重要，按照自己实际需要修改
vim /etc/kubeasz/clusters/k8s-cluster1/hosts
主要修改集群地址，名字，ip范围 等等

vim /etc/kubeasz/clusters/k8s-cluster1/config.yml
你想通过那个IP 或 域名访问 maaster节点都要给他们签发证书


vim roles/containerd/templates/config.toml.j2 
coontainerd的配置文件模板，可以修改一些自定义配置

```



![image-20240326115844340](../images/image-20240326115844340.png)



```
禁止Pod调度到此节点的命令
kubectl cordon <node-name>

驱逐200上的Pod ，但是要设置好忽略Daemon set ，因为Pod驱逐到别的节点，Daemon set 只能运行一个

kubectl drain 10.0.0.200 --ignore-daemonsets


然后把要升级的服务停止,把二进制文件替换调

#要恢复节点的可调度状态
kubectl uncordon <node-name>或者IP

#批量升级
把二进制文件包拷贝到 /etc/Kubeasz/bin 下，因为这是ansible 调用的二进制文件，这里面放着之前安装的旧二进制
./ezctl upgrade k8s-cluster1
```







回顾总结



## 核心资源

推荐：声明式 具有幂等性 





### 资源类型

集群级别：

命名空间级别的资源，在创建时必须指定命名空间



#### Namespace

命名空间（Namespace）是一种用于对集群资源进行逻辑分组和隔离的机制。命名空间为用户提供了一种将不同类型的资源（如 Pod、Service、Deployment 等）进行逻辑分组的方式，以便更好地管理和组织这些资源。

```
逻辑分组：命名空间允许用户将集群中的资源按照逻辑关系进行分组
授权和权限控制：通过授权机制，可以限制用户或服务账号对特定命名空间中资源的访问权限，从而提高集群的安全性。
资源配额： Kubernetes 支持在命名空间级别设置资源配额，以限制命名空间中资源的使用量。这可以防止某个命名空间中的资源耗尽集群资源，保证集群的稳定性和可用性。
提高集群性能:进行资源搜索时，名称空间有利于Kubernetes API缩小查找范围，从而对减少搜索延迟和提升性能有一定的帮助
```

 资源对象名称隔离，跨命名空间可以同名

##### Kubernetes的名称空间可以划分为两种类型

系统级名称空间：由Kubernetes集群默认创建，主要用来隔离系统级的资源对象

自定义名称空间：由用户按需创建

**系统级名称空间**

```
default：默认的名称空间，为任何名称空间级别的资源提供的默认设定

kube-system：Kubernetes集群自身组件及其它系统级组件使用的名称空间，Kubernetes自身的关键组件均部署

在该名称空间中

kube-public：公众开放的名称空间，所有用户（包括Anonymous）都可以读取内部的资源

kube-node-lease：节点租约资源所用的名称空间

​ 分布式系统通常使用“租约（Lease）”机制来锁定共享资源并协调集群成员之间的活动

​ Kubernetes上的租约概念由API群组coordination.k8s.io群组下的Lease资源所承载，以支撑系统级别的功能需求，例如节点心跳（node heartbeats）和组件级的领导选举等	

​ Kubernetes集群的每个节点，在该名称空间下都有一个与节点名称同名的Lease资源对象
```

**所有的系统级名称空间均不能进行删除操作，而且除default外，其它三个也不应该用作业务应用的部署目标**







#### Pod

一个或多个容器的集合，因而也可称为容器集，但却是Kubernetes调度、部署和运行应用的最小原子单元

另外封装的内容：可被该组容器共享的存储资源、网络协议栈及容器的运行控制策略等

依赖于**pause**容器事先创建出可被各应用容器共享的基础环境，它默认共享Network、IPC和UTS名称空间给各

容器，PID名称空间也可以共享，但需要用户显式定义

Pod的组成形式有两种

 单容器Pod：仅含有单个容器

 多容器Pod：含有多个具有“超亲密”关系的容器

​		同一Pod内的所有容器都将运行于由Scheduler选定的同一个节点上

一个Pod中可能有多个容器，多个容器共享net，ipc,uts,

 pasue 容器其实也是main容器运行前做初始化的，创建net，ipc,uts,命名空间，挂载卷，完成这些操作后就暂停





    镜像下载策略：
    imagePullPolicy： Always、IfNotPresent、Never 
    例外：Image Tag为latest时，在Always或IfNotPresent策略下，都会重新下载；因为Kubelet无法确定Latest是不是当前最新的。 



Pod相位 

当前阶段，如果Pod（pending）,意味着调度失败，没有任何一个节点，可以满足该Pod的创建条件。一旦满足此pod创建的条件，那么pod的状态将会转变位runging（Pod自身是runnig但其中的容器并不一定），如果是job类应用，运行成功 succeeded ，如果作业类应用失败了，falied状态，

api 接收不到 kubelet汇报的POD状态



​	![image-20240327195755387](../images/image-20240327195755387.png)



容器的状态

![image-20240327200436284](../images/image-20240327200436284.png)

Pod的重启策略：决定了容器终止后是否应该重启

Always：无论何种exit code，都要重启容器

OnFailure：仅在exit code为非0值（即错误退出）时才重启容器

Never：无论何种exit code，都不重启容器



##### 通过环境变量向容器传递参数

环境变量是容器化应用的常用配置方式之一

```yaml
kubectl run mysql --image=mysql:8.0 --dry-run=client -o yaml

apiVersion: v1
kind: Pod
  metadata:
  name: mydb
  namespace: default
spec:
  containers:
  - name: mysql
    image: mysql:8.0
    env:
    - name: MYSQL_RANDOM_ROOT_PASSWORD
	  value: 1
	- name: MYSQL_DATABASE
	  value: wpdb
	- name: MYSQL_USER
      value: wpuser
	- name: MYSQL_PASSWORD
	  value: magedu.com
	 ports:	
	 - name: tcp
	   containerdPort: 80
	   hostPort: 8080
#可以直接在创建Pod是 容器中的字段定义宿主机和POD的端口映射，会生成DP nat策略
主机端口：
   	将Pod所在的主机的某个端口与容器的端口建立映射关系
 	External Client --> hostIP:hostPort --> podIP:containerPort
```



 

#### Pod的健康状态监测机制

1. **Startup Probe**（启动探针）： 阻塞其他探针
   - **作用**：用于检查容器是否已经启动并且是否可以开始接受请求。与 Liveness 和 Readiness 探针不同，Startup 探针只在容器首次启动时执行，并且不会在容器重启时再次执行。
   - **场景**：适用于需要一些额外的初始化时间的容器，例如在启动过程中需要加载大量数据或配置文件的情况。
2. **Liveness Probe**（存活性探针）：
   - **作用**：用于检查容器是否正在运行。如果 Liveness 探针失败（即容器未响应），Kubernetes 将尝试重新启动容器。
   - **场景**：用于检测容器是否出现了某种无法自行修复的问题，例如死锁或无限循环。当容器出现这些问题时，Liveness 探针会将容器标记为不健康，并尝试重新启动。
3. **Readiness Probe**（就绪性探针）：
   - **作用**：用于检查容器是否已经准备好接受流量。只有当 Readiness 探针成功后，Kubernetes 才会将该容器的 IP 地址添加到服务的负载均衡池中，从而开始向该容器转发流量。如果探测失败会从Service后端real server列表摘下来，并不会重启容器。
   - **场景**：适用于需要在容器完全启动并且应用程序已准备好处理流量之前，避免将流量发送到容器的情况。例如，当应用程序需要加载大量数据或与其他服务建立连接时，可以使用 Readiness 探针来确保容器已经准备好接收流量

探测机制

Exec Action：根据指定命令的结果状态码判定

TcpSocket Action：根据相应TCP套接字连接建立状态判定

HTTPGet Action：根据指定https/http服务URL的响应结果判定

配置参数

 initialDelaySeconds：容器启动后多久开始执行探测，默认为 0。（容器中的程序可能非常大，启动很慢，如果不给他一个足够的时间启动，那么会造成死循环，在他没起来的时候探测都是失败的，然后一直重启）

 periodSeconds：探测之间的间隔时间。

 timeoutSeconds：单次探测的超时时长 

 successThreshold：成功阈值

 failureThreshold：失败阈值，连续失败多少次后标记为失败，默认为 3

```apl
Container Probe (探测): 周期性向容器发起探测请求
            StartupProbe
            LivenessProbe：存活状态，用于判定容器进程是否健康运行；
                影响：判定为不健康的Pod，会被kubelet根据重启策略进行处理，重启；
            ReadinessProbe：就绪状态，用于判定容器进程是否已经初始化完成，并可向用户提供服务；
                影响：判定为未就绪的Pod，以该Pod为后端端点的Service，不予调度流量给该Pod；

            成功阈值：1
                failure状态下，满足连续success的次数之后，即被判定为成功；
            失败阈值：3

            探测的方式：
                tcpSocket
                httpGet
                exec：运行此处自定义的命令，根据命令的退出码，来判定其健康状态；


Startup Probe 主要用于确定容器是否已经准备好接收请求，并且只会在容器首次启动时执行。如果容器在启动时 Startup Probe 失败，则 Kubernetes 将认为容器启动失败，但它不会触发 Pod 的重启。

Liveness Probe 用于检查容器是否处于运行状态，如果 Liveness Probe 失败，则 kublet 将尝试重新启动容器。而 Readiness Probe 用于检查容器是否准备好接收流量，如果 Readiness Probe 失败，则容器将被从服务负载均衡中移除，但它并不会触发 Pod 的重启。
```

![image-20240327210014279](../images/image-20240327210014279.png)



实例：

```bash
apiVersion: v1
kind: Pod
metadata:
  name: startup-exec-demo
  namespace: default
spec:
  containers:
  - name: demo
    image: ikubernetes/demoapp:v1.0
    imagePullPolicy: IfNotPresent
    startupProbe:
      exec:
        command: ["/bin/sh", "-c", "[ \"$(/usr/bin/curl -s http://127.0.0.1/livez)\" == \"OK\" ]"]
      initialDelaySeconds: 0
      failureThreshold: 3
      periodSeconds: 5

```





#### Security Context 安全上下文









#### 资源限制

建议设置成相同，方式内存不够重复申请造成，内存不连续、还会降低QoS

requests 的优先级低，如果定义 requests 2G   limts 5G，但这个Pod1 运行到了  3G，

这时候启动新的Pod2，如果节点资源不够， Pod1 的资源会被回收到 2G , 给Pod2使用





**常用命令**

```
kubectl api-resources
kubectl api-version

kubectl get 
kubectl get TYPE [name, ...] 
	 -o {json|yaml|wide|jsonpath|name}
 
kubectl get TYPE1,TYPE2,...  all：代表所有类型

kubectl get TYPE1/NAME TYPE2/NAME2 ...

TYPE: namespaces, namespace, ns
kubectl get -f /PATH/TO/MANIFEST_FILE


命令： kubectl create 
方法一：指令式命令
	kubectl create TYPE NAME OPTIONS
方法二：指令式对象配置	
	kubectl create -f /PATH/TO/MANIFEST_FILE
	
	-f选项可重复使用多次；
	-f /PATH/TO/DIR/：加载目录下的所有以.yaml, .yml, .json结尾的文件；
	-f URL: 加载URL位置上的配置文件

命令： kubectl delete 
        命令格式类似于kubectl get，删除某类型下的所有资源对象时，要使用“--all”选项；

    命令：kubectl edit 
        kubectl edit TYPE NAME 

    命令：kubectl explain 
        TYPE NAME
        显示指定资源类型的内建文档

        --api-version=GROUP_NAME/VERSION 

    命令：kubectl api-versions
        打印k8s上的所有的资源群组及其版本号

    命令： kubectl describe
        kubectl describe TYPE NAME 

    命令：kubectl logs 
        kubectl logs [-f] [-p] (POD | TYPE/NAME) [-c CONTAINER]

        --all-containers
        --tail=N 

    命令：kubectl exec 
        kubectl exec (POD | TYPE/NAME) [-c CONTAINER] [flags] -- COMMAND [args...] [options]

        -it：打开交互式接口时使用

--dry-run=true
```





要想在Pod上使用卷，要定义卷，引用卷，这就意味着用户必须了解后端的存储的配置等

k8s用pc pvc解决  



自动选择满足存储需求的PVC 也可以使用 LabelSercor匹配某个PV，同时也可以使用stargClass分组





不满足需求，访问模式不匹配





环境变量是 创建Pod时候引用的，如果以configmap提供，然后修改congifmap是没用的







## PV和PVC



#### 在Pod级别定义存储卷有两个弊端

1.卷的生命周期无法独立于Pod

2.用户必须要足够熟悉可用的存储及其详情才能在Pod上配置和使用卷

**注解：**

一旦Pod被删除，那么我们定义的卷会被删除，而且卷中的数据也可能被删除（取决于卷的类型）

要想在Pod上使用卷：用户必须要定义卷，因此用户必须要了解后端存储的配置和使用（违背了K8S的设计理念）

k8s把底层的硬件抽象成资源池，让用户关注引用本身即可，需要什么资源只需要告诉K8S需要啥，k8s会去做，不用用户自身



#### Persistent Volume和Persistent Volume Claim可用于降低这种耦合关系

 PV（Persistent Volume）是集群级别的资源，负责将存储空间引入到集群中，通常由管理员定义

 PVC（Persistent Volume Claim）是名称空间级别的资源，由用户定义，用于在空闲的PV中申请使用符合过滤条件的PV之一，与选定的PV是“一对一”的关系

 用户在Pod上通过pvc插件请求绑定使用定义好的PVC资源

StorageClass资源支持PV的动态预配（Provision）



**注解**：

我们有一个RDB Cpeh存储，如果Pod现在要使用这个RDB，创建此Pod的用户必须要知道：服务器地址、连接Ceph的凭据、Ceph上那些存储为我所用。因此用户必须要了解这些存储细节，才能使用该持久卷。

K8s用Persistent Volume 解决这一问题，把n多种存储细节/存储类型都交由集群管理员/存储管理员来定义PV,由他们创建出不同类型的PV，比如NFS，Ceph，块类型，文件系统，可用的空间大小。

当用户需要使用持久卷时，定义PVC请求去绑定某一个PV，可以使用选择器直接选择某个PV, 不指定的话 pv  control  会根据存储空间，类型，读写模式，去众多PV中匹配某个匹配度最高的PV。用户再创建Pod时只需要调用PVC即可，不用很麻烦的了解后端存储



但是由于用户使用和定义的不是同一个人，就是定义和使用 PVC 和 PV 不是同一组的人，那么PV的定义者就得联系PVC的使用者了解需求后定义出pv开会讨论等等，很麻烦，因此K8s由StorageClass 解决这一问题。
StorageClass通过API 管理我们的存储服务，并在上面创建用户需要的存储空间，不同以往的是，用户定义PVC，由StorageClass按照PVC的要求，按需创建对应要求的存储空间，并自动把按要求创建的存储空间创建成PV，再把PVC和PV绑定。因此我们的存储细节就要定义再StorageClass，因为要他去管理存储服务，并在上面创建存储空间，并把它定义成k8s上的PV



    PV置备（provision）方式:
       静态置备：也可以使用StorageClass，分组，亦可作为筛选条件之一，可选项；
       		分组筛选时： PV和pvc要属于同一个存储类，就是要选择的pv隶属于StorageClass，pvc要指定同一个StorageClass
       动态置备：依赖于StorageClass（模板），必选项





#### PV和PVC(2)

PV资源

PV是标准的资源类型，除了负责关联至后端存储系统外，它通常还需要定义支持的存储特性

Volume Mode：当前PV卷提供的存储空间模型，分为块设备和文件系统两种

StorageClassName：当前PV隶属的存储类；

AccessMode：支持的访问模型，分为单路读写、多路读写和多路只读三种

```
RWO、RWX、ROX、PRWO
文件系统一般支持多路读写、块设备一般单路读写
```

Size：当前PV允许使用的空间上限/大小

 在对象元数据上，还能够根据需要定义标签

 一般需要定义回收策略：Retain、Recycle和Delete

```
Retain：表示当 PersistentVolume 上的 PersistentVolumeClaim 被删除时，保留 PersistentVolume 上的数据。换句话说，数据不会被删除，而是保留在持久存储中，需要手动进行清理。

Delete：表示当 PersistentVolume 上的 PersistentVolumeClaim 被删除时，同时删除 PersistentVolume 上的数据。这意味着一旦 PersistentVolumeClaim 被删除，数据将被永久删除，无法恢复。（删除PV并不代表删除PV上的数据）

Recycle：它会简单地将 PersistentVolume 上的数据清空，以便后续可以重新使用该 PersistentVolume。但是，由于这种方式存在安全和隐私方面的问题，
```

PVC资源

 PVC也是标准的资源类型，它允许用户按需指定期望的存储特性，并以之为条件，按特定的条件顺序进行PV过滤

VolumeMode → LabelSelector → StorageClassName → AccessMode → Size

 支持动态预配的存储类，还可以根据PVC的条件按需完成PV创建

![image-20240330201316977](../images/image-20240330201316977.png)



#### 使用静态PV和PVC的步骤

![image-20240330201454256](../images/image-20240330201454256.png)

**定义实例**

![image-20240330201622504](../images/image-20240330201622504.png)





### StorageClass

StorageClass资源

 Kubernetes支持的标准资源类型之一

 为管理PV资源之便而按需创建的存储资源类别（逻辑组）

 是PVC筛选PV时的过滤条件之一

 为动态创建PV提供“模板”

​		需要存储服务提供管理API

​		StorageClass资源上配置接入API的各种参数

​				 定义在parameters字段中，还需要使用provisioner字段指明存储服务类型

 一般由集群管理员定义，隶属集群级别

![image-20240330202508770](../images/image-20240330202508770.png)



```ABAP
VolumeBindingMode: immediate/

立即绑定/延迟绑定
立即绑定：创建PVC并由PVC调用StorageClass创建出PV后立即绑定，无论是否有Pod引用此PVC
延迟绑定:创建PVC并由PVC调用StorageClass创建出PV后延迟绑定，等待Pod引用 消费 此PVC才会绑定

如果存储类关联的是local（立即绑定），就意味着存储类要在某个节点创建持久化存储空间并在k8s上定义为PV，比如存储类在node1上创建的存储目录并定义为PV，后来我们创建了Pod把它调度到node2就导致无法使用。
```



#### PVC和动态PV示例

有些存储类型默认并不支持动态PV机制，如右图所示

多数CSI存储都支持动态PV，且支持卷扩展和卷快照等功能

![image-20240330202819509](../images/image-20240330202819509.png)

![image-20240330202759648](../images/image-20240330202759648.png)



#### 节点本地持久卷

**local持久卷**

local卷插件用于将本地存储设备（如磁盘、分区或目录）配置为卷

```
基于网络存储的PV通常性能损耗较大
直接使用节点本地的SSD磁盘可获取较好的IO性能，更适用于存储类的服务，例如MongoDB、Ceph等
```

hostPath卷在Pod被重建后可能被调度至其它节点而无法再次使用此前的数据，而基于local卷，调度器能自行完成调度绑定

hostPath卷允许Pod访问节点上的任意路径，也存在一定程度的安全风险



基于local的PV，需要管理员通过nodeAffinity声明其定义在的节点

```
用户可通过PVC关联至local类型的PV，然后在Pod上配置使用该PVC即可，调度器将基于nodeAffinity将执行Pod调度

通过nodeAffinity匹配某个节点在上面创建存储空间并定位为PV,而且会影响Pod调度
```

![image-20240330205955951](../images/image-20240330205955951.png)

**注意：**PV上的节点亲和力/节点选择器 调度器会结合PV control 调度Pod，hostpath不会使用 PV control 所以它不存在这样的逻辑

#### 节点本地持久卷（2）

PVC迟延绑定

 配置PVC绑定local PV时，通常要创建一个StorageClass

provisioner字段的值“no-provisioner”表示不使用动态置备PV，因为local插件不支持

volumeBindingMode字段的值“WaitForFirstConsumer”表示等待消费者（Pod）申请使用PVC时（即第一次被调度时）再进行PV绑定，即“延迟绑定”

延迟绑定机制，提供了基于消费者的需求来判定将PVC绑定至哪个PV的可能性

![image-20240330214515742](../images/image-20240330214515742.png)



![image-20240330214454784](../images/image-20240330214454784.png)

![image-20240330214504362](../images/image-20240330214504362.png)

### Kubernetes存储架构

存储卷的具体的管理操作由相关的控制器向卷插件发起调用请求来完成

AD控制器：负责存储设备的Attach/Detach操作

```
Attach：将设备附加到目标节点
Detach：将设备从目标节点上拆除
```

存储卷管理器：负责完成卷的Mount/Umount操作，以及设备的格式化操作等

PV控制器：负责PV/PVC的绑定、生命周期管理，以及存储卷的Provision/Delete操作

```
创建和销毁 PV： PV 控制器根据管理员定义的 PersistentVolume 对象的规格，负责创建新的持久卷，并在需要时进行销毁。

动态供给持久卷： 在动态存储供给的场景下，PV 控制器可以自动地根据 PersistentVolumeClaim 对象的需求来创建相应的持久卷，并将其绑定到对应的 PVC。

持久卷与 PVC 的绑定和解绑： PV 控制器负责将持久卷绑定到 PersistentVolumeClaim，并在持久卷不再被使用时解绑。

处理 PV 和 PVC 的回收策略： PV 控制器根据管理员配置的回收策略，负责在持久卷和 PersistentVolumeClaim 不再被使用时进行回收操作，以释放资源或执行相应的清理操作。
```

**Scheduler：特定存储插件的调度决策会受到目标节点上的存储卷的影响**



**注解：**

每个 Kubernetes 节点上的 Kubelet 都包含一个内置的 Volume Manager，负责管理节点上的卷（Volume），包括持久卷（PersistentVolume）的挂载、卸载和格式化等操作。Kubelet 会监视 Pod 的 VolumeClaim，并根据需要在节点上动态地创建、挂载和管理卷。它还负责监控节点上的卷的状态，并在需要时处理卷的故障或重新连接。



AD（Attach/Detach）控制器负责将云提供商的块存储卷（如 AWS EBS、Azure Disk）或本地存储卷挂载到节点上。它的主要工作是确保节点上的持久卷正确地与底层存储系统关联，并在需要时执行挂载和卸载操作。

然后，Kubelet 中的 Volume Manager 会监视挂载在节点上的持久卷，并根据 Pod 的需求将这些卷挂载到 Pod 中。Volume Manager 负责与容器运行时协调，确保 Pod 中的容器可以访问到正确的存储资源。

![image-20240330222138647](../images/image-20240330222138647.png)



#### Out-of-Tree存储

容器存储接口规范，与平台无关   驱动程序组件

```
CSI Controller：负责与存储服务的API通信从而完成后端存储的管理操作

Node Plugin：也称为CSI Node，负责在节点级别完成存储卷的管理
```



因为Kubelet内置的Volume manager 要完成卷的挂载等操作，但它通常只支持一些默认的卷类型，例如空白目录卷、主机路径卷等。所以要在每个节点用 DaemonSet 以Pod方式在每个节点部署一个 CSI 插件，此Pod通常还承担着与存储后端通信、卷管理、权限控制、监控日志等功能。

```
当我们用pvc向存储类申请 卷，存储类会去调用 ad 控制器 和 PV控制器，由ad 控制器 和 PV控制器去调用CSI 插件的 Pod 去后端存储创建卷并 定义为pv，但默认 ad 控制器 和 PV控制器无法直接管理 CSI 插件Pod，因此要部署一个 CSI controller
```

**节点驱动器与控制器驱动器**

**节点驱动器（Node Driver）**

是指负责与存储介质直接交互的软件模块，它是CSI存储机制中的一个重要组件。

节点驱动器的主要职责包括：

将CSI存储机制中的标准接口翻译成与底层存储介质交互的命令和操作。这些操作包括读取、写入、删除数据等。
处理与存储介质的连接和通信，确保数据的传输和交互的正确性。
处理存储介质的故障处理，包括错误恢复、数据恢复等。
节点驱动器与具体的存储介质有关，不同的存储介质对应不同的节点驱动器。

因此，当CSI存储机制与不同的存储介质交互时，需要加载相应的节点驱动器。

**控制器驱动器（Controller Driver）**

是CSI存储机制中的另一个重要组件，它负责管理存储资源和协调节点驱动器的操作。

控制器驱动器的主要职责包括：

管理存储资源的分配和释放，包括卷管理、快照管理等。
协调节点驱动器的操作，根据节点驱动器发送的请求进行调度和处理。
处理存储资源的访问控制和权限管理。
控制器驱动器与节点驱动器通过CSI存储机制的标准接口进行通信。

节点驱动器通过CSI接口向控制器驱动器发送请求，控制器驱动器根据请求的类型和参数进行处理，并返回相应的结果给节点驱动器。

在协作方式上，节点驱动器和控制器驱动器通过CSI接口进行交互，实现了标准的存储接口和功能。

节点驱动器负责与存储介质直接交互，控制器驱动器负责管理存储资源和协调节点驱动器的操作。

其合作方式使得CSI存储机制能够统一管理和访问不同类型的存储介质，提供统一的接口和功能给上层应用和系统使用。

**CSI Controller 通常由两个主要组件组成**：

**CSI Driver Registrar**：负责将 CSI 插件注册到 Kubernetes 中，使得 Kubernetes 能够发现和使用这些插件。它会创建相应的 CustomResourceDefinitions（CRDs），并确保 Kubernetes 能够正确地识别和管理 CSI 插件的相关资源。

**CSI Node Driver Manager**：负责在每个节点上启动并管理 CSI 插件的 Pod 实例。它会根据集群中节点的变化（例如节点的添加或删除）自动调整 CSI 插件 Pod 的部署，并确保每个节点都能够运行所需的 CSI 插件实例。

**注解：**

**用户创建 PVC**：用户通过创建 PersistentVolumeClaim（PVC）向 Kubernetes 请求持久卷，并指定存储类为扩展了 CSI 插件的存储类。

**存储类选择**：Kubernetes 根据 PVC 中指定的存储类来确定如何满足 PVC 的请求。这个存储类与扩展了 CSI 插件的存储类相关联。

**Admission 控制器审批**：Admission 控制器负责验证 PVC 请求的合法性，并根据定义的策略对其进行审批。

**PVC 审批通过**：一旦 PVC 审批通过，Kubernetes 将开始处理 PVC 请求。

**CSI 控制器动态 Provisioning**：PV 控制器检测到 PVC 请求，并将其发送到 CSI 控制器。CSI 控制器负责根据存储类中定义的信息（包括 CSI 驱动信息）来决定如何创建持久卷。

**CSI 控制器调用 CSI 插件**：CSI 控制器根据存储类中定义的 CSI 驱动信息，调用相应的 CSI 插件。

**CSI 插件创建卷**：CSI 插件在与存储后端通信后，执行创建卷的操作。这可能涉及与存储后端的交互、卷的创建、格式化等，**CSI 插件创建 PV**：一旦卷成功创建，CSI 插件将向 Kubernetes API 发送 PV 对象的创建请求。

**PV 控制器创建 PV**：PV 控制器接收到来自 CSI 插件的 PV 创建请求，并根据请求信息创建 PV 对象。

![image-20240331094944926](../images/image-20240331094944926.png)





#### 部署及使用kubernetes-csi/**csi-driver-nfs**

csi-driver-nfs 
        负责为现有NFS Server提供PV的动态置备能力，它依赖于一个现有的NFS Server； 

```bash
测试环境中，部署NFS Server的方法
在Kubernetes集群上部署一个NFS Server；
kubectl create namespace nfs 
kubectl create -f https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/deploy/example/nfs-provisioner/nfs-server.yaml -n nfs

#访问nfs服务的入口：nfs-server.nfs.svc.cluster.local 

自行在Kubernetes集群外部准备一个NFS Server
  导出目录时要使用的导出选项： (rw,fsid=0,async,no_subtree_check,no_auth_nlm,insecure,no_root_squash) 

```



 **部署csi-driver-nfs：** 

```bash
#网络安装
curl -skSL https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/v4.6.0/deploy/install-driver.sh | bash -s v4.6.0 --

#本地安装
git clone https://github.com/kubernetes-csi/csi-driver-nfs.git
cd csi-driver-nfs
./deploy/install-driver.sh v4.6.0 local


#个人方法(默认部署在kube-system名称空间，各Image的仓库地址是registry.k8s.io)
cd /root/csi-driver-nfs/deploy
kubectl apply -f v4.6.0/

#检查
kubectl get pods -n kube-system
kubectl -n kube-system get pod -o wide -l app=csi-nfs-controller
kubectl -n kube-system get pod -o wide -l app=csi-nfs-node



#NFS-server 导出共享
mkdir /nfsdd
vim /etc/exports
...
/nfsdd      10.0.0.0/24(rw,fsid=0,async,no_subtree_check,no_auth_nlm,insecure,no_root_squash)
...
exportfs -arv
```

![image-20240331101700721](../images/image-20240331101700721.png)

![image-20240331101718741](../images/image-20240331101718741.png)

#### 准备存储类给PVC使用

```bash
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-csi
provisioner: nfs.csi.k8s.io
parameters:
 #server: nfs-server.default.svc.cluster.local
  server: 10.0.0.203
  share: /nfsdd
  # csi.storage.k8s.io/provisioner-secret is only needed for providing mountOptions in DeleteVolume
  # csi.storage.k8s.io/provisioner-secret-name: "mount-options"
  # csi.storage.k8s.io/provisioner-secret-namespace: "default"
reclaimPolicy: Delete
volumeBindingMode: Immediate
mountOptions: #建议去掉
  - nfsvers=4.1
  
---
#pvc
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-nfs-dynamic
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
  storageClassName: nfs-csi
```

1. **用户创建 PVC**：用户创建了一个 PVC，并指定了存储类为 `nfs-csi`，这意味着他想要使用 `nfs-csi` 存储类来创建一个持久卷。
2. **PV 控制器选择存储类**：PersistentVolume（PV）控制器检测到 PVC 的创建请求，并根据 PVC 中指定的存储类 `nfs-csi` 来选择相应的存储类定义。
3. **CSI 控制器处理存储类请求**：PV 控制器将存储类请求传递给 CSI 控制器。CSI 控制器根据存储类 `nfs-csi` 的定义信息，决定使用哪个 CSI 插件来满足该请求。
4. **CSI 插件创建存储空间**：CSI 控制器调用相应的 CSI 插件，通知它要创建存储空间。CSI 插件根据存储类的定义信息（例如后端存储地址、卷大小等），与后端存储系统进行通信，并创建相应的存储空间。
5. **CSI 插件创建 PV**：一旦存储空间创建成功，CSI 插件将向 Kubernetes API 发送 PV 对象的创建请求，描述这个新创建的存储空间。
6. **PV 控制器创建 PV**：PV 控制器接收到来自 CSI 插件的 PV 创建请求，并根据请求信息创建 PV 对象。
7. **PV 与 PVC 绑定**：创建的 PV 与 PVC 绑定，以满足 PVC 的请求

因此存储类只是定义了后端存储的信息和配置，真实的调用过程并不会直接调用存储类本身，而是通过存储类来选择合适的 provisioner，并由 PV 控制器和 CSI 控制器来实际完成 PV 的创建工作

```ABAP
用户在创建 PVC 时通过指定存储类来表达对 PV 的需求。存储类定义了如何动态地创建 PV。
PV 控制器根据 PVC 的请求和存储类的定义来决定如何创建 PV。它会根据存储类的参数和属性，以及 PVC 的要求来选择合适的 provisioner。

PV 控制器会根据存储类的定义和 PVC 的要求，为 PV 分配一个 volumeHandle（通常是一个唯一标识符），然后将这个 volumeHandle 传递给 Kubernetes API。在这之后，CSI 控制器会观察到这个 PV 对象的创建，并且它根据 PV 的 volumeHandle 以及其他参数，来决定如何调用特定的 CSI 插件去创建并管理底层的存储资源。

用户通过 PVC 和存储类来描述他们的存储需求，PV 控制器根据这些信息创建 PV，并将 PV 对象的描述传递给 Kubernetes API。然后，CSI 控制器观察到这个 PV 的创建，并根据 PV 对象的信息来决定如何使用特定的 CSI 插件来创建和管理底层的存储资源。
```





CAS（Container Attached Storage）**简介**

容器附加存储（Container Attached Storage）

Kubernetes的卷通常是基于外部文件系统或块存储实现，这种存储方案称为共享存储（Shared Storage）

CAS则是将存储系统自身部署为Kubernetes集群上的一种较新的存储解决方案

```
存储系统自身（包括存储控制器）在Kubernetes上以容器化微服务的方式运行
使得工作负载更易于移植，且更容易根据应用程序的需求改动使用的存储
通常基于工作负载或者按集群部署，因此消除了共享存储的跨工作负载甚至是跨集群的爆炸半径
```

存储在 CAS 中的数据可以直接从集群内的容器访问，从而能显著减少读/写时间

 OpenEBS是CAS存储机制的著名实现之一，由CNCF孵化





基于CAS的存储解决方案，通常包含两类组件

控制平面

```
负责配置卷以及其他同存储相关任务
由存储控制器、存储策略以及如何配置数据平面的指令组成
```

 数据平面

```
接收并执行来自控制平面的有关如何保存和访问容器信息的指令
主要组件是实现池化存储的存储引擎，这类引擎本质上负责输入/输出卷路径
OpenEBS支持存储引擎包括Mayastor、cStor、Jiva和OpenEBS LocalPV等
```

![image-20240331142146218](../images/image-20240331142146218.png)



#### Openebs

卷类型：本地卷和分布式复制卷
        本地卷：磁盘、分区、文件系统目录(local Volume)、ZFS、LVM
        复制卷：
            iSCSI: cStor和Jiva
            NVMEoF: MayaStor

![image-20240331143524748](../images/image-20240331143524748.png)





```
数据引擎的功能
 数据引擎类似于存储控制器，也可将其比作是一种SDS的实现
 OpenEBS提供了一系列的数据引擎，所有引擎都支持PV的动态置备和数据的强一致性
 数据引擎的分类
 本地引擎
本地引擎可以从本地磁盘设备（依赖于NDM）或主机路径创建PV，也可基于集群节点上的LVM或ZFS创建PV
适合内置可用性和可扩展性功能的应用程序，或者作业类的有状态工作负载
基于节点上支持的存储机制，可选的动态Local PV包括 Local PV hostpath、Local PV device、ZFS Local PV、LVM Local 
PV 和 Rawfile Local PV 这五种
 复制引擎
复制卷，顾名思义，就是那些可以将数据同步复制到多个节点的卷
复制引擎允许从复制节点范围内的任一节点上进行数据访问，并支持跨可用区进行复制
复制卷通常还支持快照、克隆、扩展等功能
基于节点上支持的存储机制，可选的复制引擎包括Mayastor、cStor和Jiva
```



```
如何选择数据引擎
 应用程序处于生产状态且不需要存储级复制，则首选 LocalPV
 应用程序处于生产状态并且需要存储级复制，则首选 cStor
 应用程序较小、需要存储级复制但不需要快照或克隆，则首选 Jiva
 应用程序需要低延迟和接近磁盘的吞吐量，需要存储级复制，并且工作节点具有性能较高的CPU、RAM和
NVME，那么 Mayastor 是首选如何选择数据引擎
 应用程序处于生产状态且不需要存储级复制，则首选 LocalPV
 应用程序处于生产状态并且需要存储级复制，则首选 cStor
 应用程序较小、需要存储级复制但不需要快照或克隆，则首选 Jiva
 应用程序需要低延迟和接近磁盘的吞吐量，需要存储级复制，并且工作节点具有性能较高的CPU、RAM和
NVME，那么 Mayastor 是首选
```



```
NDM（Node Disk Manager）
 部署OpenEBS的过程中，NDM由专用DaemonSet编排运行于每个节点上
负责发现裸设备并过滤掉不支持使用的设备，例如已经带有文件系统的磁盘
需要特权模式，访问/dev、/proc和/sys目录来监视连接的设备，并使用各种探测器获取这些设备的详细信息
 根据过滤器（filters）检测附加到节点上的裸磁盘设备，并将它们识别为“块设备CRD”
NDM支持使用include filters或exclude filters
filter的配置保存于ConfigMap中
 基于节点上的裸磁盘设备提供PV的存储引擎，会依赖于NDM实现其功能，这包括Local PV device 和 cStor
```

部署使用OpenEBS的基本流程

在各节点上部署iSCSI client（不用Csage 和jiva 不用部署）

在Kubernetes集群上部署OpenEBS

选择要使用的数据引擎

为选择的数据引擎准备StorageClass





```bash
#安装openebs
kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml
kubectl delete -f https://openebs.github.io/charts/openebs-operator.yaml

#部署完默认支持一下两种存储类
openebs-device     openebs.io/local   Delete          WaitForFirstConsumer   false                  105m
openebs-hostpath   openebs.io/local   Delete          WaitForFirstConsumer   false                  105m
#查看默认loacl卷存放在哪里
kubectl get sc openebs-hostpath -o yaml
#在对应Pod所在的节点创建PV
ll /var/openebs/local/pvc-949f7ff3-6284-45ba-a75e-be60a3ff89c7/

我们可以直接使用 openebs-hostpath类 创建PV，NDM会帮我们找到每个节点可用的空间，先在某个节点创建存储空间，然后提交pv创建申请，然后再把Pod调度至该节点

openebs会拉一个Pod，去某个节点创建local存储空间，并申请创建pv，等pod一旦消费pvc就吧pod调度在此节点上

---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: openebs-local-hostpath-pvc
spec:
  storageClassName: openebs-hostpath
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5G


#修改存储类的默认存储路径  把之前的删了重新创建
#Sample storage classes for OpenEBS Local PV
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
name: openebs-hostpath
annotations:
 openebs.io/cas-type: local
 cas.openebs.io/config: |
   # hostpath type will create a PV by 
   # creating a sub-directory under the
   # BASEPATH provided below.
   - name: StorageType
     value: "hostpath"
   # Specify the location (directory) where
   # where PV(volume) data will be saved. 
   # A sub-directory with pv-name will be 
   # created. When the volume is deleted, 
   # the PV sub-directory will be deleted.
   #Default value is /var/openebs/local
   - name: BasePath
     value: "/var/openebs/local/"
provisioner: openebs.io/local
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
```



1. **用户创建 PVC**：
   - 用户通过定义 PVC 规格文件，并将存储类指定为 OpenEBS 的存储类，然后使用 `kubectl apply` 命令将 PVC 规格文件提交到 Kubernetes 集群。
2. **OpenEBS 控制平面监测 PVC 创建事件**：
   - OpenEBS 控制平面的组件，如 OpenEBS Operator、OpenEBS Provisioner 等，会持续监测 Kubernetes 中的 PVC 创建事件。
3. **根据存储类的定义创建 PV**：
   - 当 OpenEBS 控制平面检测到 PVC 创建事件时，它会根据 PVC 中指定的存储类（即 OpenEBS 的存储类）来创建相应的 PV。
   - OpenEBS 控制平面会根据存储类的定义信息，以及集群中的节点情况来决定在哪个节点上创建存储卷。
   - 控制平面会调用相应的 provisioner（如 openebs-localpv-provisioner-）来创建 PV。这个 provisioner 是一个控制器，负责与 Kubernetes API 交互，创建 PV 对象。
4. **PV 控制器创建 PV 对象**：
   - PV 控制器接收到来自 OpenEBS 控制平面的创建 PV 的请求，然后根据请求中的信息创建 PV 对象。
   - PV 控制器将 PV 对象的描述保存到 Kubernetes 的 API 服务器中，以便其他组件可以访问和使用这些 PV。
5. **PV 与 PVC 绑定**：
   - 一旦 PV 被创建，PV 控制器会将 PV 与相应的 PVC 进行绑定，使得 PVC 可以使用这个 PV 提供的存储资源。

```
数据平面的具体操作（如数据写入、读取等）是在创建 PV 后，当 Pod 使用 PVC 挂载 PV 并进行数据操作时才会发生。在这个阶段，数据平面的组件会负责处理实际的数据传输和存储操作。因此，在创建 PV 的流程中，没有直接涉及到数据平面的组件。
在 OpenEBS 中，数据平面组件负责实际的存储操作，与底层存储设备进行交互，管理数据的读写、复制、快照等功能。这些数据平面组件与存储引擎密切相关，它们负责将数据存储在物理存储设备上，并提供持久化存储的功能。
```



 Jiva或cStor要建立在本地卷功能的基础之上；
                Jiva --> 依赖于本地卷来解决每个节点上的存储需求

```bash
#部署jiva
kubectl apply -f https://openebs.github.io/charts/jiva-operator.yaml
#声明jiva volume策略（声明 副本数/再每个节点存用什么类型存储）

apiVersion: openebs.io/v1alpha1
kind: JivaVolumePolicy
metadata:
  name: jivavolumepolicy-demo
  namespace: openebs
spec:
  replicaSC: openebs-hostpath #类型存储
  target:
    # This sets the number of replicas for high-availability
    # replication factor <= no. of (CSI) nodes
    replicationFactor: 2 #副本数
    # disableMonitor: false
    # auxResources:
    # tolerations:
    # resources:
    # affinity:
    # nodeSelector:
    # priorityClassName:
  # replica:
    # tolerations:
    # resources:
    # affinity:
    # nodeSelector:
    # priorityClassName:


----
#创建存储类的时候要指定使用那个存储策略
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: openebs-jiva-csi
provisioner: jiva.csi.openebs.io
allowVolumeExpansion: true 
parameters:
  cas-type: "jiva"
  policy: "jivavolumepolicy-demo"  

----
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: openebs-jiva-csi-pvc
spec:
  storageClassName: openebs-jiva-csi
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
      
      
 
#这是个jiva卷用于复制数据到不同的节点的中间层
kubectl get jivavolume -n openebs

```

它会再不同的节点根据复制因子，复制多份数据，Pod读写时，我们的jiva会再创建一个Pod把这两个存储关联到此POD上，并给需要使用的POD使用该PV

![image-20240331173228757](../images/image-20240331173228757.png)





下面两个Pod用于在不同的节点初始化 和写入数据

![image-20240331192555198](../images/image-20240331192555198.png)



会创建两个pvc/pv 有几个副本复制几份

在每个节点部署 iscsi Client

```
sudo apt-get update
sudo apt-get install open-iscsi
sudo systemctl enable --now iscsid
```



jiva存储 块级别的只能单路路读写

如果想实现多路读写，需要额外部署nfs server 对jiva 再次封装

![image-20240331193307134](../images/image-20240331193307134.png)

```yaml
#部署nfs-operator
kubectl apply -f https://openebs.github.io/charts/nfs-operator.yaml


apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    cas.openebs.io/config: |
      - name: NFSServerType
        value: "kernel"
      - name: BackendStorageClass
        value: "openebs-hostpath"
    openebs.io/cas-type: nfsrwx
  name: openebs-rwx
provisioner: openebs.io/nfsrwx
reclaimPolicy: Delete
volumeBindingMode: Immediate


---
piVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: "openebs-rwx"
  resources:
    requests:
      storage: 1Gi              
```



应用配置

应用配置：
    临时卷：empytDir
    本地卷：hostPath, local 
    网络卷：nfs, ...
    特殊卷：configMap，secret, downwardAPI
    卷扩展：CSI

configMap：保存非敏感的配置，数据以明文存储
        secret: 保存敏感配置，数据以base64编码格式存储
            数据格式：
                Key: Value 

                Value：分为两类
                    单行值：单行字符串
                    多行值：文件格式的配置信息

资源类型：configMap、secret
            保存于api server中的资源对象, 最终存储于etcd中

#### ConfigMap和Secret资源

```
ConfigMap和Secret是Kubernetes系统上两种特殊类型的存储卷

 ConfigMap用于为容器中的应用提供配置数据以定制程序的行为，而敏感的配置信息，例如密钥、证书等则通常由Secret来配置

 ConfigMap和Secret将相应的配置信息保存于资源对象中etcd，而后在Pod对象上支持以存储卷的形式将其挂载并加载相关的配置，从而降低了配置与镜像文件的耦合关系，提高了镜像复用能力

 Kubernetes借助于ConfigMap对象实现了将配置文件从容器镜像中解耦，从而增强了工作负载的可移植性，使其配置更易于更改和管理，并避免了将配置数据硬编码到Pod配置清单中

此二者都属于名称空间级别，只能被同一名称空间中的Pod引用
```

#### ConfigMap和Secret资源（2）

ConfigMap和Secret资源都是数据承载类的组件，是Kubernetes API的标准资源类型，是一等公民

 主要负责提供key-value格式的数据项，其值支持

​	  单行字符串：常用于保存环境变量值，或者命令行参数等

​	  多行字串：常用于保存配置文件的内容

![image-20240331195001337](../images/image-20240331195001337.png)

```
资源规范中不使用spec字段，而是直接使用特定的字段嵌套定义key-value数据
ConfigMap支持使用data或binaryData字段嵌套一至多个键值数据项
Secret支持使用data或stringData（非base64编码的明文格式）字段嵌套一至多个键值数据项
 从Kubernetes v1.19版本开始，ConfigMap和Secret支持使用immutable字段创建不可变实例
```

#### 在Pod中引用配置的方式

环境变量

 将configmap对象上的某key的值赋值给（valueFrom）指定的环境变量

卷

在Pod上基于configMap卷插件引用configmap对象

​	 在Container上挂载configMap卷

​			每个kv会分别被映射为一个文件，文件名同key，value将成为文件内容

#### configmap

创建ConfigMap对象的方法有两种

命令式命令

 字面量：kubectl create configmap NAME --from-literal=key1=value1

 从文件加载：kubectl create configmap NAME --from-file=[key=]/PATH/TO/FILE

 从目录加载： kubectl create configmap NAME --from-file=[key=]/PATH/TO/DIR/

配置文件

命令式：kubectl create -f 

声明式：kubectl apply -f

![image-20240331195142408](../images/image-20240331195142408.png)

```bash
#命令行创建 cofigmap
kubectl create configmap NAME [--from-file=[key=]source] [--from-literal=key1=value1] [--dry-run=server|client|none]

#默认创建的Key名就是文件名
kubectl create configmap nginx-cfg --from-file=./myserver.conf --dry-run=client -o yaml

#修改文件名
kubectl create configmap nginx-cfg --from-file=my.conf=./myserver.conf   --from-file=bb.conf=./sh.conf  --dry-run=client -0 yaml
```

资源示例

命令式命令

 kubectl create configmap nginx-confs --from-file=./nginx-conf.d/myserver.conf --from-file=status.cfg=./nginx

conf.d/myserver-status.cfg

![image-20240331201149263](../images/image-20240331201149263.png)

#### 引用ConfigMap对象

在Pod上配置使用ConfigMap示例

挂载到容器中是以两级软连接的方式+隐藏目录，只需要修改第一个软连接动态加载文件，但是动态加载文件要取决于应用程序是否能动态加载配置文件

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: demoapp-config
  namespace: default
data:
  demoapp.port: "8080"
  demoapp.host: 127.0.0.1
---
apiVersion: v1
kind: Pod
metadata:
  name: configmaps-env-demo
  namespace: default
spec:
  containers:
  - image: ikubernetes/demoapp:v1.0
    name: demoapp
    env:
    - name: PORT
      valueFrom:
        configMapKeyRef:
          name: demoapp-config
          key: demoapp.port
          optional: false
```





```yaml
apiVersion: v1
data:
  gzip.cfg: |
    gzip on;
    gzip_comp_level 5;
    gzip_proxied     expired no-cache no-store private auth;
    gzip_types text/plain text/css application/xml text/javascript;
  myserver.conf: |
    server {
        listen 8080;
        server_name www.ik8s.io;

        include /etc/nginx/conf.d/myserver-*.cfg;

        location / {
            root /usr/share/nginx/html;
        }
    }
kind: ConfigMap
metadata:
  creationTimestamp: null
  name: nginx-cf


---
apiVersion: v1
kind: Pod
metadata:
  name: configmaps-volume-demo
  namespace: default
spec:
  containers:
  - image: nginx:alpine
    name: nginx-server
    volumeMounts:
    - name: ngxconfs
      mountPath: /etc/nginx/conf.d/
      readOnly: true
  volumes:  #挂载整个configmap
  - name: ngxconfs
    configMap:
      name: nginx-config-files
      optional: false

#挂载configmap自定的键
apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  containers:
  - name: mycontainer
    image: myimage
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
  volumes:
  - name: config-volume
    configMap:
      name: my-configmap
      items:
      - key: my-key    
        path: my-key.txt #挂载到容器中的文件名  /etc/config/my-key.txt

```





#### Secret资源

Secret主要用于存储密钥、OAuth令牌和 SSH 密钥等敏感信息，这些敏感信息采用base64编码保存，略好于明文存储

Secret根据其用途等，还有类型上的区分

 ![image-20240331214712501](../images/image-20240331214712501.png)

引导口令：  



**generic**

kubectl create secret generic NAME [--type=string] [--from-file=[key=]source] [--from-literal=key1=value1]

除了后面docker-registry和tls命令之外的其它类型，都可以使用该命令中的--type选项进行定义，但有些类型有key的特

定要求



**tls**

kubectl create secret tls NAME --cert=path/to/cert/file --key=path/to/key/file

通常，其保存cert文件内容的key为tls.crt，而保存private key的key为tls.key



**docker-registry**

kubectl create secret docker-registry NAME --docker-username=user --docker-password=password --docker-email=email [--docker-server=string] [--from-file=[key=]source]

通常，从已有的json格式的文件加载生成的就是dockerconfigjson类型，命令行直接量生成的也是该类型





#### 创建Secret **generic**

支持类似于ConfigMap的创建方式，但Secret有类型子命令，而且不同类型在data或stringData字段中支持嵌套使用的key亦会有所有同

```yaml
kubectl create secret generic mysql-secret --from-literal=root.password='M@geEdu' --from-literal=user.password="WDPdSS" -n wordpress --dry-run=client -o yaml
---
apiVersion: v1
data:
  root.password: TUBnZUVkdQ==
  user.password: V0RQZFNT
kind: Secret
metadata:
  creationTimestamp: null
  name: mysql-secret

apiVersion: v1
data:
	password: TWFnRWR1LmMwbQ==
	username: cm9vdA==
kind: Secret
metadata:
name: mysql-root-authn
	namespace: default
	type: Opaque
```



 **docker-registry**创建

```bash
kubectl create secret docker-registry harbor-li --docker-username=zed  --docker-password=zedking --docker-emil=505697096@qq.com  --dry-run=client -o yaml
#-server一般不用指定因为镜像标签上带有server地址

#创建Pod时引用
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: my-container
    image: myregistry.example.com/myimage:latest
  imagePullSecrets:
  - name: harbor-li
# imagePullSecrets 字段是列表，通过遍历列表中所有的账号密码登录 harbor
#列表 Pod中有多个容器，每个容器使用不同的镜像，不同的仓库需要不同的认证凭据
第二种引用方式：pods.spec.serviceAccountName
                  serviceaccount.imagePullSecrets 

```



**tls**

专用配置服务基于ssl/tls通信时使用的数字证书和私钥的类型

```yaml
kubectl create secret tls <name> --cert=path/to/cert/file --key=path/to/key/file --dry-run=client -o yaml
#键名固定
  证书的键名：tls.crt 
  私钥的键名：tls.key 
---  
apiVersion: v1
data: 
	tls.crt:  .....
	tls.key:  .....
kind: Secret
metadata:
  namespace: default
  name: nginx-ssl-secret
type: kubernetes.io/tls


#nginx引用ssl
---
apiVersion: v1
kind: Pod
metadata:
  name: secrets-volume-demo
  namespace: default
spec:
  containers:
  - image: nginx:alpine
    name: ngxserver
    volumeMounts:
    - name: nginxcerts
      mountPath: /etc/nginx/certs/
      readOnly: true
    - name: nginxconfs
      mountPath: /etc/nginx/conf.d/
      readOnly: true
  volumes:
  - name: nginxcerts
    secret:
      secretName: nginx-ssl-secret
  - name: nginxconfs
    configMap:
      name: nginx-sslvhosts-confs
      optional: false
```









scret资源在Pod中引用的方式同样有两种

 环境变量

 引用Secret对象上特定的key，以valueFrom赋值给Pod上指定的环境变量

在Pod上使用envFrom一次性导入Secret对象上的所有key-value，key（也可以统一附加特定前缀）即为环境变量名，

value自动成为相应的变量值

 secret卷

在Pod上将Secret对象引用为存储卷，而后整体由容器mount至某个目录下

key转为文件名，value即为相应的文件内容

在Pod上定义Secret卷时，仅引用其中的部分key，而后由容器mount至目录下

在容器上仅mount Secret卷上指定的key

 注意：容器很可能会将环境变量打印到日志中，因而不建议以环境变量方式引用Secret中的数据



![image-20240331220336917](../images/image-20240331220336917.png)

#### Image Pull Secret

dockercfg及dockerconfigjson类型的Secret主要用于从私有Image Registry中下载容器镜像

 其引用定义在pod.spec.imagePullSecrets字段上

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: demoapp
  namespace: default
spec:
  containers:
  - name: demoapp
    image: ikubernetes/demoapp:v1.0
  imagePullSecrets:
  - name: ikuberneteskey
```



### DownwardAPI 和 Projected

 与ConfigMap和Secret不同，DownwardAPI自身并非一种独立的API资源类型

 DownwardAPI只是一种将Pod的metadata、spec或status中的字段值注入到其内部Container里的方式

DownwardAPI提供了两种方式用于将 POD 的信息注入到容器内部

​	环境变量：用于单个变量，可以将 POD 信息和容器信息直接注入容器内部

​	 Volume挂载：将 POD 信息生成为文件，直接挂载到容器内部中去



 downwardAPI：
        RabbitMQ Cluster:
           zookpeeker-0.rabbitmq.rabbit.svc.cluster.local 
           zookpeeker-1.rabbitmq.rabbit.svc.cluster.local
           zookpeeker-2.rabbitmq.rabbit.svc.cluster.local

 Pod  内部运行的容器并不知道自己属于那个命名空间归属于那个svc、pod

让Pod中的容器了解自己之上的信息

#### 可向容器注入的元数据

在容器上基于DownwardAPI引用Pod元数据，可通过两种字段完成

 fieldRef：引用常规的元数据

 resourceFieldRef：引用同资源限制和资源需求相关的元数据

![image-20240331224013795](../images/image-20240331224013795.png)



![image-20240331224109932](../images/image-20240331224109932.png)

  向容器中注入Pod的metdata、spec或status字段信息的方式
            **环境变量：**
                filedRef
                resourceFieldRef

```yaml
containers:
  - name: rabbitmq
    image: registry.magedu.com/rabbitmq/rabbitmq:3.12-management
    ports:
      - containerPort: 15672
        name: discovery
      - containerPort: 5672
        name: amqp
    env:
      - name: RABBIT_POD_NAME
        valueFrom:
          fieldRef:
            apiVersion: v1
            fieldPath: metadata.name
      - name: RABBIT_POD_NAMESPACE
        valueFrom:
          fieldRef:
            fieldPath: metadata.namespace
      - name: RABBITMQ_NODENAME
        value: rabbit@$(RABBIT_POD_NAME).rabbitmq.$(RABBIT_POD_NAMESPACE).svc.cluster.local
      - name: RABBITMQ_USE_LONGNAME
        value: "true"
      - name: RABBITMQ_CONFIG_FILE
        value: "/config/rabbitmq"
      - name: RABBITMQ_ERLANG_COOKIE
        valueFrom:
          secretKeyRef:
            name: rabbit-secret
            key: RABBITMQ_ERLANG_COOKIE
      - name: K8S_HOSTNAME_SUFFIX
        value: .rabbitmq.$(RABBIT_POD_NAMESPACE).svc.cluster.local
```

 **卷插件注入**:

![image-20240331225032663](../images/image-20240331225032663.png)





#### Projected Volume

Projected Volume是一种特殊的卷类型，它能够将已存在的多个卷投射进同一个挂载点目录中

Projected Volume仅支持对如下四种类型的卷（数据源）进行投射操作，这类的卷一般都 是用于为容器提供预先定义好的数据

Secret：投射Secret 对象

 ConfigMap：投射ConfigMap对象

 DownwardAPI：投射Pod元数据

 ServiceAccountToken：投射ServiceAccount Token

正常情况我们把多个卷挂载到同一个目录，他们会互相覆盖，要使用Projected Projected 类似联合文件系统挂载

实例:

![image-20240331225627433](../images/image-20240331225627433.png)

```yaml
 总结：
        为Pod提供配置：
            ConfigMap、Secret
                API Server支持资源类型：需要先定义出资源对象，而后引用
                           
            downwardAPI
                非为资源类型，可直接引用，因为它们自身即为Pod属性
                    fieldRef 
                    resourceFieldRef

            Projected
                非为资源类型，但其要引用现有的configmap、secret资源对象，或downwardAPI中的元数据信息
                投射进同一个挂载点
```





## Service 服务发现

**Kubernetes Service是什么？**

负责基于单个端点（入口）暴露部署在一组Pod上的服务端应用程序

可为动态、短生命周期的Pod资源提供稳定的IP地址和DNS名称来提供可靠的接流量入机制

源自集群内、外的客户端均可基于Service访问

其后面Pod上的服务

 集群内部客户端

​	其它的Pod对象

​	工作节点上的进程

​	独立运行的容器中的进程

 集群外部客户端

​	集群外部主机上的进程



我们在创建service 时 ，他要提供负载均衡能力，就要定义一负载均衡集群，

vip：port    ---->   svip：port，如果是该地址和该端口，就往后端的地址端口转发。

对于每个service我们都要给他分配一个  独占vip地址：端口，作为识别流量的唯一特征

因为IP地址已经被service 独占，那么这地址对应的所有端口都可以使用，因为你只是用你这个IP的端口，不会和别人冲突（众所周知）

一般不建议手动指定容易冲突



相比以前我们手动管理的负载均衡集群，我们是知道后端RS IP地址，我们直接手动配制即可。

但是在k8s中，后端Pod极具动态性，因此我们service必须自动发现 上游服务器地址，通过标签选择器发现后端pod，因此我们在实现创建pod前应该为其配置上对应的标签，，当pod创建后，被server标签选择器过滤出符合标签的pod，然后再去api-service查到这些pod 的地址。



规则应该添加到那些节点：

假如我们创建了一组mysql，他被调度到了node2 和node3，然后我们又创建了一组wordpress 他被调度至node1 node2 noode3 各一个，这三个wordpress都要访问mysql，当node1上的wordpress要访问mysql 的时，他怎么知道mysql地址，它怎么知道mysql的service的地址，我们的客户端可能随时会被调度在不同的节点，而且在不同的节点要去访问mysql，我们就必须在该节点创建ipvs规则，你要为myslq提供一个固定的入口，那么就必须支持我在任何地方访问，都能访问到你。



当POD请求service时，报文从pod出来目标地址是service，到达宿主机内核，被组主机内核中的 ipvs规则匹配到，把service地址修改成后端 r s 地址，源地址不变

 由每个节点上的kube-proxy 配置规则

当本地pod 在node1 访问mysq，而且mysql node1，node2，node3节点都有，pod访问本地myslq性能更好，因为省略了目标地址转换和报文封装。因此我们可以配置service 当pod访问mysql，只调度到本地的mysql（local），但是如果pod本地myslq 那么就没人能响应它的请求，因为mysql 在node2和node3。pod 在node1，我们限制了service 只能调度至本节点

![image-20240401204314987](../images/image-20240401204314987.png)



cluster ip是虚拟出来的，客户根本无法访问这个ip请求我们的服务。

客户端想访问只能把请求发送给节点IP地址， 但是客户端访问的是节点ip，我们的iptables规则是service ip, 由于匹配不到负载均衡集群，流量直接进入节点但节点没人监听端口，就被拒绝了。

因此我们就得把节点 ip和端口定义成 分割流量的规则，但ipvs规则要在每个节点上都要定义，因此ip就不能作为分隔流量的标识 ，它可以是每个节点上的ip，但端口就得固定，找出所有节点的一个端口，专门配置给某个service使用，集群外部的客户端无论访问每个节点的这个端口都能够作为内核中IPvs规则的流量识别特征，IP地址不能向以前一样固定是因为客户端可能访问的是任意节点的ip，不管你访问的是那个节点只要是这个端口都对应的是某个service'

30000-32767（随机/手动） 但这个端口对于客户端来说不常规，再前面再加一层负载均衡器 负载均衡器监听80，由负载均衡器代理到后端所有节点的30000-32767某个端口。

这个负载均衡器手动建 就很难受，因为service很灵活，我们可能随时创建删除，而且端口还是随机的每次都不一样

云端支持Lbaas,支持k8s直接调用云端api接口动态创建 负载均衡器



nodeport 30000-32767 端口不好记，但我们又想给他 一个常规的众所周知端口，如果我们的k8s部署再物理服务器上且服务不多，假设我们服务器上有多个网卡IP，我们可以把没人用的ip和端口配置再service上，前提是这个ip和端口是公网可达的（单点问题）keeplived解决此问题 ExternalIP



```apl
 Service的类型： 
     ClusterIP：客户端必须集群内部的地址；Service关键标识是ClusterIP；
     NodePort：客户端源自于集群外部；Service的关键标识是NodePort；
            增强版的CLusterIP，它使用NodePort接入集群外部客户端流量，使用ClusterIP接入集群内部流量 
            但端口并不是常规端口，如果我们期望用常规端口，可以在外面加一层负载均衡器，但负载均衡配置起来很麻烦，因为service的创建删除很灵活。如果我们的服务器上有多余的公网IP，也可以把该ip+port配置到service上，让他再多加一条ipvs规则，如果你访问ip+port也能访问到该service，并且可以代理到后端pod上，但他有单点问题，可以结合keeplived实现高可用。也可以使用公有云的loadBalancer
            
        LoadBalancer：客户端源自于集群外部；Service的关键标识是NodePort；但额外需要一个集群外部的负载均衡器；
            LoadBalancer Service是增强版的NodePort
	    ExternalIP：手动配置；存在一些解决方案，能自动完成该功能，例如OpenELB或MetalLB；
	
    
    
Service的模式：取决kube proxy的配置；
     iptables（默认）
     nftables 
     ipvs 
```

原本service只修改目标地址源地址不变 设置为true 可以改变源地址

![image-20240401222816962](../images/image-20240401222816962.png)

服务自己访问自己ii的时候 源地址也会改变，发夹流量，对内核而言会拒绝



#### Endpoints和EndpointSlice

每创建一个service 就会创建一个Endpoints

 Endpoints对象上保存Service匹配到的所有Pod的IP和Port信息

后端每个Pod的每次变动，都需更新整个Endpoints对象（牵一发而动全身），并需要将该对象同步至每个节点的kube-proxy

##### Endpoints和EndpointSlice

 即便只有一个Pod的IP等信息发生变动，也必须向集群中的每个kube-proxy发送整个endpoints对象

存储在etcd中的对象的默认大小限制为1.5MB，这也决定了单个Endpoints对象的存储上限

至多可以存储5000个左右的端点信息

极端场景

一个由2000个节点组成的集群中，更新一个有着5000个Pod IP的Endpoints对象，需要发送3GB的数据

若以滚动更新机制，一次替换一个Pod的信息，更新这个Endpoints对象需要发送15T的数据

EndpointSlice资源通过将Endpoints切分为多片来解决上述问题

自Kubernetes v1.16引入

每个端点信息的变动，仅需要更新和发送一个EndpointSlice，而非整个Endpoints

每个EndpointSlice默认存储100个端点信息，不会触达etcd对单个对象的存储限制

可在kube-controller-manager程序上使用“--max-endpoints-per-slice”选项进行配置

```
后端每个Pod的每次变动，都需更新整个Endpoints对象，并需要将该对象同步至每个节点，这就意味着，每当后端pod信息改变每个节点都要去api-service上读取一份新的数据，etcd中一个键值最大1.5m，一个enbpoints可以存5000个pod地址。
如果100个节点1.5G，如果有1000个节点就要发15G数据，所以就引入了EndpointSlice100个端点，如果更新只更新某个EndpointSlice，只更新一部分即可。
```







### 创建Service资源

由Service表示的负载均衡器，主要定义如下内容

负载均衡器入口：ClusterIP及相关的Service Port、NodePort（每个节点的Node IP都可用）

 根据通信需求，确定选择的类型

 标签选择器：用于筛选Pod，并基于筛选出的Pod的IP生成后端端点列表（被调度的上游端点）

 Service类型的专有配置

#### 标签和标签选择器

标签：附加在资源对象上的键值型元数据

键标识：由“键前缀（可选）”和“键名”组成，格式为“key_prefix/key_name”

键前缀必须使用DNS域名格式

键名的命名格式：支持字母、数字、连接号、下划线和点号，且只能以字母或数字开头；最长63个字符；

“kubectl label”命令可管理对象的标签



**标签选择器**：基于标签筛选对象的**过滤条件**，支持两种类型

 基于等值关系的选择器

操作符：=或==、!=

 基于集合关系的选择器

操作符：in、notin和exists

使用格式：KEY in (VALUE1, VALUE2, …)、 KEY notin (VALUE1, VALUE2, …)、KEY 和 !KEY





```
  定义方式2：
            命令：kubectl label 
                kubectl label [--overwrite] (-f FILENAME | TYPE NAME) KEY_1=VAL_1 ... KEY_N=VAL_N

                增加：
                    kubectl label TYPE NAME KEY_1=VAL_1 ... KEY_N=VAL_N

                修改：
                   kubectl label --overwrite TYPE NAME KEY_1=VAL_1 ... KEY_N=VAL_N 

                删除：
                    kubectl label TYPE NAME KEY_1-

```



实例：

```
拥有此标签且值是v1
kubectl label pods demonapp version="v1"

拥有此标签且值不是v1或压根就没有此标签
kubectl label pods demonapp version != "v1"

拥有version标签，且值是下面三种之一
kubectl label pods demonapp "version in (fb,app,web)"

拥有version标签，且值不是下面三种之一 或 压根不存在此标签
kubectl label pods demonapp "version notin (fb,app,web)"

有此标签就行，不关心标签的值
exists
```





#### Service资源规范

```bash
apiVersion: v1
kind: Service
metadata:
  name: …
  namespace: …
spec:
  type <string> # Service类型，默认为ClusterIP
  selector <map[string]string> # 等值类型的标签选择器，内含“与”逻辑
  ports： # Service的端口对象列表
  - name <string> # 端口名称
    protocol <string> # 协议，目前仅支持TCP、UDP和SCTP，默认为TCP
    port <integer> # Service的端口号
    targetPort <string> # 后端目标进程的端口号或名称，名称需由Pod规范定义
    nodePort <integer> # 节点端口号，仅适用于NodePort和LoadBalancer类型
    clusterIP <string> # Service的集群IP，建议由系统自动分配
externalTrafficPolicy <string> # 外部流量策略处理方式，Local表示由当前节点处理，Cluster表示向集群范围调度
loadBalancerIP <string> # 外部负载均衡器使用的IP地址，仅适用于LoadBlancer
externalName <string> # 外部服务名称，该名称将作为Service的DNS CNAME值
```



##### 示例

ClusterIP（默认）

```yml
kind: Service
apiVersion: v1
metadata:
  name: demoapp
spec:
  type: ClusterIP # 类型标识，默认即为ClusterIP；
  selector:
    app: demoapp
  ports:
  - name: http # 端口名称标识
    protocol: TCP # 协议，支持TCP、UDP和SCTP
    port: 80 # Service的端口号
    targetPort: 80 # 目标端口号，即后端端点提供服务的监听端口号
```



NodePort

```yml
kind: Service
apiVersion: v1
metadata:
  name: demoapp
spec:
  type: NodePort # 必须明确给出Service类型
  selector:
    app: demoapp
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 80
    nodePort: 30080 # 可选，为避免冲突，建议由系统动态分配
```





#### NodePort Service流量策略（1）

流量策略一：Cluster，表示在整个Kubernetes集群范围内调度；

 该流量策略下，请求报文从某个节点上的NodePort进入，该节点上的Service会将其调度至任何一个可用后端

Pod之上，而不关心Pod运行于哪个节点



流量策略二：Local，表示仅将请求调度至当前节点上运行的可用后端端点；

 该流量策略下，请求报文从某节点NodePort进入后，该节点上的Service仅会将请求调度至当前节点上适配到

该Service的后端端点

 仅应该从运行有目标Service对象后端Pod对象的节点的NodePort发起访问

![image-20240402201517206](../images/image-20240402201517206.png)



对于外部流量服务端pod响应客户端，需要把报文返回给负载均衡器，因为客户端请求的是node ip+ port

pod不能直接返回，比如客户端请求node1，node1上没有服务转发到node2上的pod，pod'响应得相应给node1

如果客户端访问的当前节点有该服务，那么本地直接响应即可，没必要转发到node2，因为本地性能更好，但也有可能转发到节点node2会降低性能。local

但如果客户端访问的是node1，node1上没有服务，但转发策略是local，但node1本地并没有服务可以响应他的请求，会返回拒绝

    Node Port Service的外部流量策略：
        Local：结合外部的LB使用，外部LB要能理解Service Pod与Node的映射关系 
        Cluster：默认值，存在跃点





### LoadBalancer类型的Service

在接入外部流量方面，NodePort存在着几个方面的问题

非知名端口、私网IP地址、节点故障转移、节点间负载均衡、识别能适配到某Service的Local流量策略的节点等

外置的Cloud Load Balancer可以解决以上诸问题，Kubernetes通过调用IaaS平台的功能来创建LoadBalancer







#### ExternalIP

在Service上使用ExternalIP

 Service可通过使用节点上配置的辅助IP地址接入集群外部客户端流量

 流量入口仅能是配置有该IP地址的节点，其它节点无效，因而此时在节点间无负载均衡的效果

 external IP所在的节点故障后，该流量入口失效，除非将该IP地址转移配置到其它节点

 是除了LoadBalancer和NodePort外，接入外部流量的又一种方式

![image-20240402203950837](../images/image-20240402203950837.png)

```
个人理解：
给某个service加上一个IP，在每个节点内核中又生成了一条iptables规则 我们添加的ip + svc:port 对应后端pod （新的负载均衡集群 == 原来service ）
这个svc有两个可以识别的特征，cluster ip 对应后端 pod ip，ExternalIP 对应同一组后端pod 
存在单点问题，如拥有此ip的节点宕机那么此ip将不可达，那么就无法到达service后端的pod + keeplived 把ExternalIP飘逸到其他节点

路由器或交换机会把IP解析成mac地址，如果node1挂了我们去node2手动配置，但路由器交换机缓存的还是node1的mac地址。keeplived 自问自答的arp 请求，更新mac地址和ip地址对应关系
```



#### LoadBalancer类型的Service（2）

非云环境中的LoadBalancer

 部署于裸机或类似裸机环境中的Kubernetes集群，缺少可用的LBaaS服务

 MetalLB和OpenELB等项目为此提供了解决方案

MetalLB

 A network load-balancer implementation for Kubernetes using standard routing protocols

 MetalLB核心功能的实现依赖于两种机制

```
Address Allocation（地址分配）：基于用户配置的地址池，为用户创建的LoadBalancer分配IP地址，并配置在节点上
External Announcement（对外公告）：让集群外部的网络了解新分配的IP地址，MetalLB使用ARP、NDP或BGP实现
```

 MetalLB 可配置为在二层模式或BGP 模式下运行

 二层模式（ARP/NDP）

```
LoadBalancer IP地址配置在某一个节点上，并使用ARP（IPv4）或NDP（IPv6）对外公告

拥有LoadBalancer IP地址的节点将成为Service流量的惟一入口，并在节点故障时自动进行故障转移

并未真正实现负载均衡，存在性能瓶颈，且故障转移存在秒级的延迟
```

 BGP模式

集群中的所有节点与本地网络中的BGP Router建立BGP对等会话，通告LoadBalancer IP，从而告知Router如何进行流量路由，可以实现跨多个节点的真正意义上的负载均衡





#### MetalLB

前提：kube-proxy工作于ipvs模式时，必须要使用严格ARP（StrictARP）模式

部署MetalLB

默认使用的名称空间为metallb-system

部署两个组件：controller和speaker，前者负责地址分配，后者负责对外公告

创建多个CRD，包括 IPAddressPool、L2Advertisement、BGPPeer和BGPAdvertisement等



**部署：**

前置工作

```yaml
#kube-proxy工作于ipvs模式时，必须要使用严格ARP（StrictARP）模式
二进制安装
vim  /var/lib/kube-proxy/kube-proxy-config.yaml
...
excludeCIDRs: null
  minSyncPeriod: 0s
  scheduler: ""
  strictARP: true   #;如果是ipvs改成true
  syncPeriod: 30s
  tcpFinTimeout: 0s
  tcpTimeout: 0s
  udpTimeout: 0s
...

systemctl restart kube-proxy.service
systemctl status kube-proxy.service


#pod安装 kube-proxy
kubectl edit configmap -n kube-system kube-proxy

apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: "ipvs"
ipvs:
  strictARP: true


# see what changes would be made, returns nonzero returncode if different
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl diff -f - -n kube-system

# actually apply the changes, returns nonzero returncode on errors only
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl apply -f - -n kube-system

```





```yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.4/config/manifests/metallb-native.yaml

配置地址池 要和节点地址在同一网络，或者是公网可达ip


#配置可分配地址池
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: localip-pool
  namespace: metallb-system
spec:
  addresses:
  - 10.0.0.100-10.0.0.120
  autoAssign: true       #自动配置到某个node节点
  avoidBuggyIPs: true    #避免分配0.0.0.0 1.1.1.1 地址



#配置公告模式
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: localip-pool-l2a
  namespace: metallb-system
spec:
  ipAddressPools:      #使用定义好的地址池
  - localip-pool
  interfaces:		   #用那个网卡做apr 地址飘逸后公告
  - eth0

#最高同一网卡名称
```

![image-20240402222803924](../images/image-20240402222803924.png)





#### 验证

```yaml
kind: Service
apiVersion: v1
metadata:
  name: demoapp
spec:
  type: LoadBalancer # 必须明确给出Service类型
  externalTrafficPolicy: local|Cluster
  selector:
    app: demoapp
  ports:
  - name: http
    protocol: TCP
    port: 80
   targetPort: 80
   loadBalancerIP: 172.29.7.80 # 仅LBaaS支持时才能明确指定
```





### service 域名解析

**CoreDNS的默认配置详情查看ppt**

#### Service和Cluster DNS

Cluster DNS（CoreDNS）是Kubernetes集群的必备附件，负责为Kubernetes提供名称解析和服务发现

每个Service资源对象，在CoreDNS上都会自动生成一个遵循“<service>.<ns>.svc.<zone>”格式的名称

```
<service>：当前Service对象的名称
<ns>：当前Service对象所属的名称空间
<zone>：当前Kubernetes集群使用的域名后缀，默认为“cluster.local”
```

CoreDNS会持续监视API Server上的Service资源对象的变动，并实时反映到相关的DNS资源记录中

Pod中各容器默认会在/etc/resolv.conf中，将nameserver指向CoreDNS相关的Service的ClusterIP

由kubelet创建Pod时根据指定的配置自动注入



#### Service在Cluster DNS上的资源记录

API Server的客户端，注册监视每个Service的变动，自动为每个Service生成FQDN格式的名称

core dns是无状态的，他把所有的资源记录都存在etcd上

 Pod中的每个容器：
            /etc/resolv.conf  
                 nameserver ---  core dns 的service

节点的dns服务器并不会指向 Coredns

![image-20240403091507060](../images/image-20240403091507060.png)



#### 每个Service，在CoreDNS上都会有A/AAAA、SRV和PTR资源记录

```
A/AAAA资源记录
<service>.<ns>.svc.<zone>. <ttl> IN A <cluster-ip>
<service>.<ns>.svc.<zone>. <ttl> IN AAAA <cluster-ip>
```

为每个定义了名称的端口生成一个SRV记录，以支持服务发现

```
<port>._<proto>.<service>.<ns>.svc.<zone>. <ttl> IN SRV <weight> <priority> <port-number> 
<service>.<ns>.svc.<zone>.
```

为每个A记录（例如a.b.c.d）或AAAA记录生成对应的PTR记录，例如

```
<d>.<c>.<b>.<a>.in-addr.arpa. <ttl> IN PTR <service>.<ns>.svc.<zone>.
h4.h3.h2.h1.g4.g3.g2.g1.f4.f3.f2.f1.e4.e3.e2.e1.d4.d3.d2.d1.c4.c3.c2.c1.b4.b3.b2.b1.a4.a3.a2.a1.ip6.arpa <ttl> IN PTR <service>.<ns>.svc.<zone>.
```

Pod可基于Service的DNS名称向其发起服务访问请求

```
search default,svc.cluster,local svc.cluster.local cluster.local
最前面的名称空间在每个名称空间下都是当前的 svcname - 当前namespace -- svc.cluster,local
所以在当前命名空间内用svcname 访问其他pod 只需要写svcname后面会自动补全当前名称空间.svc.cluster,local。
跨名命名空间要写上namespace
 
dev/pod --> kube-system/openebs.
                        dev.svc.cluster.local    svc.cluster.local    cluster.local 
```



#### Pod上的DNS解析策略

为什么我们的pod默认就被注入dns信息，pod期望状态字段，由下面两个字段控制

```
Kubernetes支持在单个Pod资源规范上自定义DNS解析策略和配置，并组合生效
spec.dnsPolicy：解析策略

spec.dnsConfig：名称解析机制
```

**DNS解析策略**

```bash
Default：从运行在的节点继承DNS名称解析相关的配置

ClusterFirst(默认)：于集群DNS服务上解析集群域内的名称，其他域名的解析则交由从节点继承而来的上游名称服务器
#优先使用集群上自有的DNS Server进行名称解析，<zone>之外的域名，则交由Pod所在的节点的/etc/resolv.conf中配置的nameserver进行解析；

ClusterFirstWithHostNet：专用于在设置了hostNetwork的Pod对象上使用的ClusterFirst策略，如果pod配置了ClusterFirstWithHostNet，那么优先给此pod配置coredns服务器
#在某些特定场景，pod共享了宿主机的hostNetword: true ，就意味着他是使用的Dns服务器也是宿主机的，如果此pod想要访问svc name，宿主机的Dns将无法解析。

None：用于忽略Kubernetes集群的默认设定，而仅使用由dnsConfig自定义的配置
```

默认共享pasue容器的UTC Net IPC 卷 命名空间 

hostNetword: true 直接共享pod所在节点的netnamespace

![image-20240403094719554](../images/image-20240403094719554.png)



DNS解析机制(dns config)

```
 nameservers <[]string>：DNS名称服务器列表，附加于由dnsPolicy生成的DNS名称服务器之后

 searches <[]string>：DNS名称解析时的搜索域，附加由于dnsPolicy生成的搜索域之后

 options <[]Object>：DNS解析选项列表，同dnsPolicy生成的解析选项合并成最终生效的定义
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-dnspolicy
  namespace: default
spec:
  containers:
  - name: demo
    image: ikubernetes/demoapp:v1.0
    imagePullPolicy: IfNotPresent
  dnsPolicy: None
  dnsConfig:
    nameservers:
    - 10.96.0.10
    - 223.5.5.5
    - 223.6.6.6
    searches:
    - svc.cluster.local
    - cluster.local
    - ilinux.io
    options:
    - name: ndots
      value: "5"
```







```
 Service的特殊类型：
        ExternalName：
            Internal Client --> Service Name --> External Name --> 外部的某服务的IP地址；

                wordpress Pod --> mysql.blog.svc.cluster.local --> mysql.magedu.com --> 172.29.5.101/172.29.5.102

        Headless Service: 
            创建一个常规的ClusterIP类型的Service，但却要求不分配ClusterIP;
            被StatefulSet所依赖；
```



#### ExternalName

把MySQL放在了集群外部，并且做了DNS ，如果我们集群内部的服务想要用域名访问MySQL，但coredns解析不到，可以配置coredns配置该域名 转发到我们自己的dns服务器。但域名也不是我通常的svc域名

因此我们要创建你一个ExternalName svc 不用写ip 而是域名

```
本来域名 www.mysql.com
mysql.dev.svc.cluster.loacl ---- www.mysql.com  --- Coredns 无法解析，配置coreDNS 转发
forllowerd mysql.com 到我们自己的dns服务器

Internal Client --> Service Name --> External Name --> 外部的某服务的IP地址；
相当于别名记录，没有cluster ip
```



```
kubectl describe configmap -n kube-system coredns
```

示例：

```yaml
kind: Service
apiVersion: v1
metadata:
  name: externalname-mageedu
spec:
  type: ExternalName
  externalName: www.magedu.com
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
    selector: {}
```



#### Headless Service

Service的各类型中，ClusterIP、NodePort和LoadBalancer都为其Service配置一个ClusterIP，CoreDNS上，这些Service对象的A记录也解析为它的ClusterIP；

广义上，那些没有ClusterIP的Service则称为Headless Service，它们又可以为分两种情形

 有标签选择器，或者没有标签选择器，但有着与Service对象同名的Endpoint资源

```
Service的DNS名称直接解析为后端各就绪状态的Pod的IP地址，调度功能也将由DNS完成

各Pod IP相关PTR记录将解析至Pod自身的名称，假设Pod IP为a.b.c.d，则其名称为a-b-c-d.<service>.<ns>.svc.<zone>
这种类型也就是狭义上的Headless Service
```

无标签选择器且也没有与Service对象同名的Endpoint资源

Service的DNS名称将会生成一条CNAME记录，对应值由Service对象上的spec.externalName字段指定



直接访问svc name 直接解析后端pod地址

```yaml
kind: Service
apiVersion:v1 
metadata:
name: demoapp-headless-svc
spec:
  clusterIP:None
  selector:
    app: demoapp
  ports:
  - port: 30
    targetort: 80
    name: http
```





## Deployment资源及控制器

Deployment控制器简介

Deployment Controller --> 管理一切Deployment资源类型下的资源对象

 控制器模式： 
            Spec: 期望状态，由用户定义，并提交给API Server 
            Status: 实际状态，由控制器负责通过运行代码生成



#### 声明式API和控制器模式

控制器模型（控制回路）

初始，Controller负责根据Input（目标状态）控制System，并生成Output（结果状态）

Feedback根据Output生成Feedback Signal，而后由Error Detector基于Feedback Signal和Input来判定是否存在错误，并在有错误时生成Error Signal

Error Signal将驱动Controller生成Actuating Signal，并控制System的行为与Input要求相同



Controller根据spec，控制System生成Status

Controller借助于Sensor持续监视System的Spec和Status，在每一次控制回路中都会对二者进行比较，并确保System的Status不断逼近或完全等同Spec



无状态应用编排：ReplicaSet、Deployment

有状态应用编排：StatefulSet、第三方专用的Operator

系统级应用：DaemonSet

作业类应用：Job和CronJob



有状态无状态的区别

我请求资源 A 或  先请求 B 在请求 A 结果是一样的，请求一张图片 你一直请求他返回结果是一样的

wordpress 你发文章之前和发文章之后看到的不一样

状态数据/业务数据

鸡鸭可以互相取代，但猫狗不能寄托了感情

#### Deployment控制器简介

负责编排无状态应用的基础控制器是ReplicaSet，相应的资源类型

replicas：期望运行的Pod副本数

 selector：标签选择器（挑选已有的pod，多退少补）

 podTemplate：Pod模板

name--前缀固定 后面随机

Deployment是建立在ReplicaSet控制器上层的更高级的控制器

它位于ReplicaSet更上面一层，基于ReplicaSet提供了**滚动更新**、**回滚**等更为强大的应用编排功能

随意修改replicas的值 简单便捷的完成扩缩容

```ABAP
但需要值注意的是ReplicaSet 并不会自动更新，因为他不具备自动更新和回滚的能力，当我们修改了镜像版本他并不会触发自动更新。只有在删除pod，pod数不满足期望状态重建pod时，才会更新。
```



**Deployment编排ReplicaSet，ReplicaSet编排Pod**

![image-20240403120134083](../images/image-20240403120134083.png)





#### ReplicaSet和Deployment资源规范

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  namespace: dev
  name: rs-example
spec:
  replicas: 2
  selector:
    matchLabels:
      app: demoapp
  template:
     metadata:
     labels:
       app: demoapp
       release: stable
    spec:
      containers:
        - name: demoapp
          image: ikubernetes/demoapp:v1.0
```







### 更新策略

Deployment控制器支持两种更新策略

**滚动式更新（rolling updates）**

逐批次更新Pod的方式，支持按百分比或具体的数量定义批次规模，默认策略

```bash
#触发条件：podTemplate的hash码变动
仅podTemplate的配置变动才会导致hash码改变
replicas和selector的变更不会导致podTemplate的hash变动
```

**重建式更新（recreate）**

```bash
#触发条件：现有Pod被删除
在Pod资源被删除时，使用新的模板定义被足缺失的Pod数量，完成更新
```

创建Deployment 生成的 RS 名称是 template 的hash值



##### 触发更新

最为常见的更新需求是应用升级，即镜像文件更新，常用方法

```

```



```
 更新状态：kubectl rollout status (TYPE NAME | TYPE/NAME) [flags] [options]
 更新历史：kubectl rollout history (TYPE NAME | TYPE/NAME) [flags] [options]

 回滚到前一版本： kubectl rollout undo (TYPE NAME | TYPE/NAME) 
 回滚到指定版本： kubectl rollout undo (TYPE NAME | TYPE/NAME) --to-revision=X
```



 **Deployment的滚动更新支持使用如下两个字段来配置相关的策略**

maxSurge：指定升级期间存在的总Pod对象数量最多可超出期望值的个数，其值可以是0或正整数，也可以是相对于期望值的一个百分比 默认值为 25%

maxUnavailable：升级期间正常可用的Pod副本数（包括新旧版本）最多不能低于期望值的个数，其值可以是0或正整数，也可以是相对于期望值的一个百分比，默认值为 25%

![image-20240403144319817](../images/image-20240403144319817.png)



![image-20240403151740196](../images/image-20240403151740196.png)







## StatefulSet和Operator

StatefulSet的编排机制

各Pod副本分别具有**唯一的名称标识**，这依赖于一个**专用的Headless Service**实现

基于Pod管理策略（Pod Management Policy），定义创建、删除及扩缩容等管理操作期间，施加在Pod副本上的操作方式

```
OrderedReady：创建或扩容时，顺次完成各Pod副本的创建，且要求只有前一个Pod转为Ready状态后，才能进行后一个Pod副本的创建；删除或缩容时，逆序、依次完成相关Pod副本的终止
Parallel：各Pod副本的创建或删除操作不存在顺序方面的要求，可同时进行
```

各Pod副本存储的状态数据并不相同，因而需要专用且稳定的Volume

```
基于podTemplate定义Pod模板
在podTemplate上使用volumeTemplate为各Pod副本动态置备PersistentVolume
```





**Pod副本的专用名称标识**

每个StatefulSet对象强依赖于一个专用的Headless Service对象

StatefulSet中的各Pod副本分别拥有唯一的名称标识

```bash
#各Pod的名称标识可由ClustrDNS直接解析为Pod IP
前缀格式为“$(statefulset_name)-$(ordinal)”
后缀格式为“$(service_name).$(namespace).svc.cluster.local”
#示例
headless service: mysql 
            mysql-0.mysql.blog.svc.cluster.local --> Pod IP 
```

**volumeTemplateClaim**

在创建Pod副本时绑定至专有的PVC

PVC的名称遵循特定的格式，从而能够与StatefulSet控制器对象的Pod副本建立关联关系

支持从静态置备或动态置备的PV中完成绑定

删除Pod（例如缩容），并不会一并删除相关的PVC

因为各个有状态应用在部署，扩容缩容的运维操作不尽相同，很难标准化。StatefulSet只是为我们提供了一个基本的框架，存储、每个有状态服务的唯一标识



StatefulSet 资源规范及示例：

```yaml
apiVersion: apps/v1 # API群组及版本；
kind: StatefulSet # 资源类型特有标识；
metadata:
  name <string> # 资源名称，在作用域中要惟一；
  namespace <string> # 名称空间；StatefulSet资源隶属名称空间级别；
spec:
  minReadySeconds <integer> # Pod就绪后多少秒内任一容器无crash方可视为“就绪”；
  serviceName <string> # 关联的Headless Service的名称，需要事先存在；
  selector <object> # 标签选择器，必须匹配template字段中Pod模板中的标签；
  replicas <integer> # Pod的副本数量；
  template <object> # Pod模板对象；
    volumeClaimTemplates <[]Object> # 卷请求模板；
    podManagementPolicy <string> # Pod管理策略，支持OrderedReady和Parallel两种，默认为前者；
    revisionHistoryLimit <integer> # 滚动更新历史记录数量，默认为10；
    updateStrategy <Object> # 滚动更新策略
    type <string> # 滚动更新类型，可用值有OnDelete和RollingUpdate；
    rollingUpdate <Object> # 滚动更新参数，专用于RollingUpdate类型；
      maxUnavailable <string> # 更新期间可比期望的Pod数量缺少的数量或比例；
      partition <integer> # 更新策略中的partition号码，默认为0；
      
 有状态应用一般先减后加，redis集群在更新时先加一个，槽位分布就和以前不一样了
 
#更新分区
partition <integer> # 更新策略中的partition号码，默认为0；
假如我们有4个Pod，那他们的序号 0 1 2 3 
如果 partition: 0  那么大于等于0编号的Pod都要被更新
如果 partition: 3  那么只有pod3被更新
```



##### 更新策略

```
rollingUpdate：滚动更新，自动触发
onDelete：删除时更新，手动触发
```

滚动更新

```
maxUnavailable：定义单批次允许更新的最大副本数量
partition <integer>：用于定义更新分区的编号，其序号大于等于该编号的Pod都将被更新，小于该分区号的都不予更新；默认编号为0，即更新所有副本
```





#### Operator 简介

```
https://operatorhub.io/
```

Operator 是增强型的控制器（Controller），它扩展了Kubernetes API的功能，并基于该扩展管理复杂应用程序

使用**自定义资源（例如CRD）**来管理应用程序及其组件

增强版的控制器，在基础的控制器之上，实现更高级更复杂的功能

    基于专用的Operator编排运行某有状态应用的逻辑：
        1、部署Operator及其专用的资源类型；
        2、使用专用的资源类型，来声明一个有状态应用的编排需求；



部署eck crd

```bash
kubectl create -f https://download.elastic.co/downloads/eck/2.12.1/crds.yaml

#安装完会扩展一些资源类型
kubectl get crd      kubectl api-resources
```



部署operator

```
#部署专门的控制器来控制管理
kubectl apply -f https://download.elastic.co/downloads/eck/2.12.1/operator.yaml
```

crd只是资源类型，我们定义好 apply 并没有任何实际作用，需要安装可以控制管理这组资源类型的控制器来管理他们。operator控制器自己也是一个pod，此控制器 pod 用来控制编排他所管理的资源







##### Operator示例

Eck Operator

```
kind: Elasticsearch
metadata:
name: myes
namespace: elastic-system
spec:
version: 8.11.3
nodeSets:
- name: default
count: 3
config:
node.store.allow_mmap: false
volumeClaimTemplates:
- metadata:
name: elasticsearch-data
spec:
accessModes:
- ReadWriteOnce
resources:
requests:
storage: 5Gi
storageClassName: 'openebs-hostpath'
```



```
apiVersion: kibana.k8s.elastic.co/v1
kind: Kibana
metadata:
name: kibana
namespace: elastic-system
spec:
version: 8.11.3
count: 1
elasticsearchRef:
name: "myes"
http:
tls:
selfSignedCertificate:
disabled: true
service:
spec:
type: LoadBalancer
```





**DaemonSet**

使用DaemonSet编排应用

同Deployment相似，DaemonSet基于标签选择器管控一组Pod副本；

但是，DaemonSet用于确保所有或选定的工作节点上都运行有一个Pod副本

```
提示：DaemonSet的根本目标在于让每个节点一个 Pod
有符合条件的新节点进入时，DaemonSet会将Pod自动添加至相应节点；而节点的移出，相应的Pod副本也将被回收；
```

常用场景

集群存储守护进程、集群日志收集守护进程以及节点监控守护进程等

特定类型的系统化应用，例如kube-proxy，以及Calico网络插件的节点代理calico-node等



  系统级存在共享宿主信息或资源需要：
            1、hostNet/hostPid/hostUser
            2、hostPath volume  加载宿主机的文件，从而采信息，不然他无法访问宿主机的文件内系统

**更新策略**

rollingUpdate：滚动更新，自动触发

```
DaemonSet 在更新时尽量不要配置maxSurge，如果允许更新时多1个副本，那么他是以节点为单位，但是没有节点他就只能在本节点新建一个（节点数量不可能增加），在现有的节点增加一个新的删除旧的。
在某些特定情况，比如共享了宿主机的网络，这时候在多加一个一模一样配置的pod，会导致冲突
```

onDelete：删除时更新，手动触发

```
        updateStrategy:
            rollingUpdate:
                maxSurge: 0
                maxUnavailable: 1
            type: RollingUpdate
```

配置清单

```bash
apiVersion: apps/v1 # API群组及版本；
kind: DaemonSet # 资源类型特有标识；
metadata:
name <string> # 资源名称，在作用域中要惟一；
 namespace <string> # 名称空间；DaemonSet资源隶属名称空间级别；
spec:
minReadySeconds <integer> # Pod就绪后多少秒内任一容器无crash方可视为“就绪”；
serviceName <string> # 关联的Headless Service的名称，需要事先存在；
 selector <object> # 标签选择器，必须匹配template字段中Pod模板中的标签；
replicas <integer> # Pod的副本数量；
 template <object> # Pod模板对象；
volumeClaimTemplates <[]Object> # 卷请求模板；
podManagementPolicy <string> # Pod管理策略，支持OrderedReady和Parallel两种，默认为前者；
 revisionHistoryLimit <integer> # 滚动更新历史记录数量，默认为10；
 updateStrategy <Object> # 滚动更新策略
 type <string> # 滚动更新类型，可用值有OnDelete和RollingUpdate；
 rollingUpdate <Object> # 滚动更新参数，专用于RollingUpdate类型；
 maxUnavailable <string> # 更新期间可比期望的Pod数量缺少的数量或比例；
partition <integer> # 更新策略中的partition号码，默认为0；
```









## Job

Job负责编排运行有结束时间的“一次性”任务，而前面的Deployment和DaemonSet主要负责编排始终运行的守护进程类应用；

**有着特定声明周期长度的应用**

控制器要确保Pod内的进程“正常（成功完成任务）”地退出

非正常退出的Pod可以根据需要重启，并在重试一次的次数后终止

有些Job是单次任务，也有些Job需要运行多次（次数通常固定）

```
运行多次和周期任务有这很大区别
运行多次指的是这一次任务中执行多次，但多次执行完就退出了，不会执行了
周期任务是执行退出等下一次时间到了还会执行
```

有些任务支持同时创建及并行运行多个Pod以加快任务处理速度，Job控制器还允许用户自定义其并行度

比如有10个日志文件收集，一次收集一个，执行多此结束，或者我们可以并行，一次执行2个，5次收集完

**需要周期性运行的Job，则由CronJob控制器负责编排**

CronJob建立在Job的功能之上，是更高层级的控制器

它以Job控制器完成单批次的任务编排，而后为这种Job作业提供需要运行的周期定义



**注意：**

```
job类应用的重启策略不能设置为Always，执行完正常退出一次结束，他不应该重启。应该改设置为OnFailure，Never。

对于DaemonSet，Deployment，StatefulSete而且重启策略必须是Always，服务类应用必须持久运行在后台，为服务端提供服务，因此不管他们以什么方式退出，一定要重启。
```



#### Job资源规范

Job资源同样需要标签选择器和Pod模板，但它不需要指定replicas，而是应该给定completions，即需要完成的作业次数，默认为1次；

ob资源会为其Pod对象自动添加“job-name=JOB_NAME”和“controller-uid=UID”标签，并使用标签选择器完成对controller-uid标签的关联，因此，selector并非必选字段

 Pod的命名格式：`$(job-name)-$(index)-$(random-string)，其中的$(index)字段取值与completions和completionMode有关

 注意

 Job资源所在群组为“batch/v1”

 Job资源中，Pod的RestartPolicy的取值 只能为Never或OnFailure 



```bash
apiVersion: batch/v1 # API群组及版本；
kind: Job # 资源类型特有标识；
metadata:
name <string> # 资源名称，在作用域中要惟一；
 namespace <string> # 名称空间；Job资源隶属名称空间级别；
spec:
selector <object> # 标签选择器，必须匹配template字段中Pod模板中的标签；
suspend <boolean> # 是否挂起当前Job的执行，挂起作业会重置StartTime字段的值；
 template <object> # Pod模板对象；
 completions <integer> # 期望的成功完成的作业次数，成功运行结束的Pod数量；
completionMode <string> # 追踪Pod完成的模式，支持Indexed和NonIndexed（默认）两种； 无序
 ttlSecondsAfterFinished <integer> # 终止状态作业的生存时长，超期将被删除；
 parallelism <integer> # 作业的最大并行度，默认为1；
 backoffLimit <integer> # 将作业标记为“Failed”之前的重试次数，默认为6；
 activeDeadlineSeconds <integer> # 作业启动后可处于活动状态的时长；
 #一个小时之内运行完毕，运行不完终止
```

![image-20240404111248068](../images/image-20240404111248068.png)

示例：

```
apiVersion: batch/v1
kind: Job
metadata:
name: job-demo
spec:
template:
spec:
containers:
- name: myjob
image: ikubernetes/admin-box:v1.0
imagePullPolicy: IfNotPresent
command: ["/bin/sh", "-c", "sleep 30"]
restartPolicy: Never
completions: 3
ttlSecondsAfterFinished: 3600
backoffLimit: 3
activeDeadlineSeconds: 300
```



##### 并行式Job

Job对象能够支持多个Pod的可靠、并发执行

编排彼此间相互通信的并行进程并非Job的设计目标，它仅用于支撑一组相互独立而又有所关联的工作任务的并行处理

常见的场景，有如发送电子邮件、渲染视频帧、编解码文件、NoSQL数据库中扫描主键范围等

并行式Job的关键配置参数

parallelism：任务并行度，即最大可同行运行的Pod数量，可以将其理解为工作队列的数量

completions：总共需要完成的任务数量，即总共需要多少个相关的Pod成功完成执行，通常要大于parallelism值

```
apiVersion: batch/v1
kind: Job
metadata:
  name: para-job-demo
spec:
  template:
  spec:
    containers:
    - name: myjob
      image: ikubernetes/admin-box:v1.0
      imagePullPolicy: IfNotPresent
      command: ["/bin/sh", "-c", "sleep 30"]
    restartPolicy: OnFailure
completions: 7
parallelism: 2
completionsMode: Indexed
ttlSecondsAfterFinished: 3600
backoffLimit: 3
activeDeadlineSeconds: 1200
```





### CronJob

在job之上增加了时间编排功能，把job当模板

CronJob控制器用于管理Job资源的运行时间，它允许用户在特定的时间或以指定的间隔运行Job

cronJob控制器的功能类似于linux操作系统的周期性任务作业计划（crontab），用于控制作业运行的时间点及周期性运行的方式：

仅在未来某时间点将指定的作业运行一次

在指定的周期性时间点重复运行指定的作业

在CronJob中，通配符“?”和“*”的意义相同，它们都表示任何可用的有效值

```bash
apiVersion: batch/v1 # API群组及版本；
kind: CronJob # 资源类型特有标识；
metadata:
name <string> # 资源名称，在作用域中要惟一；
 namespace <string> # 名称空间；CronJob资源隶属名称空间级别；
spec:
jobTemplate <Object> # job作业模板，必选字段；
 metadata <object> # 模板元数据；
 spec <object> # 作业的期望状态；
 schedule <string> # 调度时间设定，必选字段；
 concurrencyPolicy <string> # 并发策略，可用值有Allow、Forbid和Replace；
 前一个作业没执行完，下一个任务开始了。Replace替换前面的
 
 failedJobsHistoryLimit <integer> # 失败作业的历史记录数，默认为1；
 successfulJobsHistoryLimit <integer> # 成功作业的历史记录数，默认为3；
 startingDeadlineSeconds <integer> # 因错过时间点而未执行的作业的可超期时长；
 每隔一段时间执行，到此次执行12点的时候可能因为系统阻塞并没有按时执行，那么错过了12点多少执行还算有效
 
 suspend <boolean> # 是否挂起后续的作业，不影响当前作业，默认为false；
```





```yaml
#时间规范和Crontable一样 
    Cronjob: 
        # ┌───────────── minute (0–59)
        # │ ┌───────────── hour (0–23)
        # │ │ ┌───────────── day of the month (1–31)
        # │ │ │ ┌───────────── month (1–12)
        # │ │ │ │ ┌───────────── day of the week (0–6) (Sunday to Saturday;
        # │ │ │ │ │                                   7 is also Sunday on some systems)
        # │ │ │ │ │
        # │ │ │ │ │
        # * * * * * <command to execute> 
```



示例：

```yaml
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: cronjob-demo
  namespace: default
spec:
  schedule: "*/2 * * * *"
  jobTemplate:
    metadata:
      labels:
        controller: cronjob-demo
    spec:
      parallelism: 1
      completions: 1
      ttlSecondsAfterFinished: 600
      backoffLimit: 3
      activeDeadlineSeconds: 60
      template:
        spec:
          containers:
          - name: myjob
            image: ikubernetes/admin-box:v1.2
            command:
            - /bin/sh
            - -c
            - date; echo Hello from CronJob, sleep a while...; sleep 10
          restartPolicy: OnFailure
  startingDeadlineSeconds: 300
```







## Kubernetes集群的流量管理

Service

```
基于iptables或ipvs实现的四层负载均衡机制
不支持基于URL等机制对HTTP/HTTPS协议进行高级路由、超时/重试、基于流量的灰度等高级流量治理机制
难以将多个Service流量统一管理
```

Ingress

```
由Ingress API和Ingress Controller共同组成
前者负责以k8s标准的资源格式定义流量调度、路由等规则
后者负责监视（watch）Ingress并生成自身的配置，并据此完成流量转发
```

Ingress Controller非为内置的控制器，需要额外部署

```
通常以Pod形式运行于Kubernetes集群之上
一般应该由专用的LB Service负责为其接入集群外部流量
```





在以前我们将服务类应用暴露至集群外部的方法：

​		NodePort Service、LoadBalancer Service、ExternalIP  （四层代理）

以上方法都得创建 NodePort 资源，使用专用NodePort来暴露服务

Service with ExternalIP，使用专用的ExternalIP来暴露服务

如果我们要暴露100个服务，就意味着我们需要100NodePort，100个专用且外部可路由的ExternalIP(公网根达）

假如我们要暴露100个服务，这100个服务要么是100NodePort或100ExternalIP或是这两种的组合，每一个服务都有自己的流量入口，那就意味着流量入口有100个，而且他们都是四层代理，无法卸载https会话的卸载，不同的服务或Pod要配置不同的证书会很麻烦，也无法对所有流量做统一的治理。

因而如果我们期望给k8s集群所暴露的服务提供一个统一的出入口，这样我们就可以统一管理请求的流量



七层代理：http/https，



在我们的集群中部署 一个Pod 把他暴露出去，在由此pod 把流量按需代理给其他需要暴露的服务，而且只需要在此pod上配置ssl证书，需要一个七层代理。但我们的服务是极具动态性的我们可能随时要暴露服务出去，或者停止一个服务，那么这个七层代理就得具备动态性，随时改随时更新。

七层代理有很多，用户可能安装Nginx、Haproxy、evnoy、他们的配置文件各不相同，定义起来非常麻烦，还得学习，因此k8s为我们抽象了一层，我们只需要提供基本配置，要暴露的服务，端口 路径 后端服务等，以一个资源对象定义出来 (Ingress) 是七层代理通用的配置 ，他既不是Nginx配置 也不是Haproxy的配置。但我们把ingress提交到api-server，那么这个七层代理就要具备能 发现我们提交的ingress并把他转换成自己的配置格式，还要支持动态配置生效功能



k8s支持部署多种不同的 Ingress Controller ，假如我们安装了 nginx 和 haproxy，我们 Ingress 配置，由他们俩谁来配置生效，两个一起配置？ 因此我们需要定义 Ingress Class用来区分我们的ingress资源配置给哪一个 Ingress Controller ，避免他俩同时加载配置

ingress是一种资源类型，而且它需要Ingress Controller 来支持 而Ingress Controller 是一个统称，所有满足 可以解析 ingress  Ingress Class 把解析成自己的配置文件，并动态生效

### Ingress和Ingress Controller

 各主流Ingress Controller对比图：

```
https://blog.palark.com/wp-content/uploads/2019/10/kubernetes-ingress-comparison.png
```



```
用户通过 Kubernetes API Server 创建或更新 Ingress 资源对象，定义了路由规则、TLS 设置等配置。

Ingress Controller 持续监视 Kubernetes API Server，当发现 Ingress 资源对象发生变化时，会及时获取最新的配置信息。

根据配置信息，Ingress Controller 将配置应用到实际的负载均衡器或反向代理服务器上。这可能涉及到更新负载均衡器的配置、重新加载代理服务器的配置等操作。
```



    Ingress及其它相关的资源类型 + Ingress Controller 
        资源类型： 
            Ingress 
            IngressClass
            IngressGateway



Kubernetes上的标准API资源类型之一

 仅定义了抽象路由配置信息，只是元数据，需要由相应的控制器动态加载

Ingress Controller

反向代理服务程序，需要监视API Server上Ingress资源的变动，并将其反映至自身的配置文件中

 Kubernetes的非内置的控制器，需要额外选择部署

```
实现方案有很多，包括Ingress-Nginx、HAProxy、Traefik、Gloo、Contour和Kong等
Kubernetes支持同时部署二个或以上的数量的Ingress Controller
Ingress资源配置可通过特定的annotation或spec中嵌套专有的字段指明期望加载该资源的Ingress Controller
专用的annotation：kubernetes.io/ingress.class
v1.18版本起，Ingress资源配置中增添了新字段：ingressClassName，引用的IngressClass是一种特定的资源类型
```



七层代理多个服务的方式：
        虚拟主机：
            portxxxxx
            ip  x'x'x'xxxxx
            host: 基于主机名的虚拟主机

基于单一虚拟主机开放多服务：scheme://host:port/PATH{1,2,3, ...}



#### 部署Ingress Controller

以Kubernetes社区维护的Ingress-Nginx为例

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/cloud/deploy.yaml
```



##### 流量路径



通过Ingress Controller 暴露服务到集群外部， 一般情况我们要给后端服务创建一个service。

但此时流量并不会通过service，而是直接由Ingress Controller pod 代理到后端pod，Ingress Controlle负载均衡，而且pod和pod直接通信性能更好没必要在中间加一层service的地址转换。那么 service还由存在的意义马？

有的因为还需要他做服务发现，Ingress Controller 必须依靠service发现pod，并把pod ip作为 upstram，并且还会依赖此service 来获取后端pod的变动







#### ingress 类型

基于单一虚拟主机使用不同的Path开放多服务,基于主机名的虚拟主机 ,SSL    

##### 类型一：Simple fanout

在同一个FQDN下通过不同的URI完成不同应用间的流量分发

基于单个虚拟主机接收多个应用的流量

常用于将流量分发至同一个应用下的多个不同子应用，同一个应用内的流量由调度算法分发至该应用的各后端端点

不需要为每个应用配置专用的域名

![image-20240404154826729](../images/image-20240404154826729.png)

##### 类型二：Name based virtual hosting

为每个应用使用一个专有的主机名，并基于这些名称完成不同应用间的流量转发

每个FQDN对应于Ingress Controller上的一个虚拟主机的定义

同一组内的应用的流量，由Ingress Controller根据调度算法完成请求调度

##### 类型三：TLS

Ingress也可以提供TLS支持，但仅限于443/TCP端口

若TLS配置部分指定了不同的主机，则它们会根据通过SNI TLS扩展指定的主机名

Ingress控制器支持SNI在同一端口上复用

TLS Secret必须包含名为tls.crt和 的密钥tls.key，它们分别含有TLS的证书和私钥



### Ingress 资源

 **Annotation：**
        注解信息；添加到资源对象上的kv类型的数据；
            键标识：[prefix/]key （key不限制长度 labels63）

不适用于标签选择器来过滤资源对象

```apl
提供配置信息： Annotation 可以用于向资源对象提供配置信息，例如指定特定的参数、选项或行为。控制器可以读取这些 Annotation，并根据其中的信息来调整应用程序的配置。

记录普通注解： Annotation 还可以用于记录额外的信息，例如资源对象的创建时间、修改历史、项目等。这些信息可以帮助管理员和开发/运维人员更好地理解和管理资源对象。

标记资源对象： Annotation 还可以用于标记资源对象，以指示它们的特定属性或状态。这些标记可以被其他工具或脚本用于进一步处理或分析资源对象。
```

**注意事项：**
                (1) Ingress是名称空间级别的资源，它仅应该引用同一个名称空间下的Service；
                (2) 主机名不是集群上的资源对象，因而其作用范围为集群级别；



创建Ingress的**命令**：kubectl create ingress NAME --rule=host/path=service:port[,tls[=secret]]

```
常用选项
 --annotation=[]：提供注解，格式为“annotation=value”
 --rule=[]：代理规则，格式为“host/path=service:port[,tls=secretname]”
 --class=‘’：该Ingress适配的Ingress Class
```



**配置示例（1）**

Simple fanout

```bash
#基于URI方式代理不同应用的请求时，后端应用的URI若与代理时使用的URI不同，则需要启用URL Rewrite完成URI的重写
Ingress-Nginx支持使用“annotation nginx.ingress.kubernetes.io/rewrite-target”注解进行

#示例：对于发往demoapp.magedu.com的请求，将“/v10”代理至service/demoapp10，将“/v11”代理至service/demoapp11

kubectl create ingress demo --rule="www.zedking.org/v10=demoapp10:80" --rule="www.zedking.org/v11=demoapp11:80" --class=nginx --annotation nginx.ingress.kubernetes.io/rewrite-target="/"


#示例2：功能同上，但使用URI的前缀匹配，而非精确匹配，且基于正则表达式模式进行url rewrite
kubectl create ingress demo --rule='www.zedking.org/v10(/|$)(.*)=demoapp10:80' --rule='www.zedking.org/v11(/|$)(.*)=demoapp11:80' --class=nginx --annotation nginx.ingress.kubernetes.io/rewrite-target='/$2'


#理解 路径映射:
nginx.ingress.kubernetes.io/rewrite-target="/" 
客户端请求代理:https://www.zedking.org/v10/web/
代理到后端：https://某service对应podIP+port/
代理后端可能没有/v10/web/路径，因此到后端就变成 /

如果不定义nginx.ingress.kubernetes.io/rewrite-target="/" 
访问路径：https://www.zedking.org/v10/web/ --> demoapp10:80/v10/web/
但我们后端服务 demoapp10:80/v10/web/ 并没有/v10/web/这个路径 所以需要定义路径映射
```

Name based virtual hosting

基于FQDN名称代理不同应用的请求时，需要事先准备好多个域名，且确保对这些域名的解析能够到达Ingress Controller

```bash
#示例：对demoapp10.magedu.com的请求代理至service/demoapp10，对demoapp11.magedu.com请求代理至service/demoapp11
kubectl create ingress demoapp --rule="demoapp10.magedu.com/*=demoapp10:80" --rule="demoapp11.magedu.com/*=demoapp11:80" --class=nginx
```





**配置示例（2）**

**SSL Ingress:**

准备secret

```bash
(umask 077; openssl genrsa -out zedking.key 2048)
openssl req -new -x509 -key ./zedking.key -out ./zedking.crt -days=3655 -subj="/O=zedking1/OU=DevOps/CN=www.zedking.org"

kubectl create secret tls tls-wordpress --cert=.zedking.crt --key=./zedking.key -n blog

#创建常规的虚拟主机代理规则，同时将该主机定义为TLS类型
kubectl create ingress ingress-wordpress --rule='www.zedking.org/*=wordpress:80,tls=tls-wordpress' --class=nginx -n blog

#注意：启用tls后，该域名下的所有URI默认为强制将http请求跳转至https，若不希望使用该功能，可以使用如下注解选项
--annotation nginx.ingress.kubernetes.io/ssl-redirect=false
```





#### Ingress资源规范





### 基于Ingress Nginx进行灰度发布 

以往的缺陷：

我们有一组应用3个pod，前面有一个负载均衡器把请求调度至后端Pod，在版本升级时流量该怎么分发是个问题

比如我们把后端3个Pod中的一个Pod升级为新版本，现在我们有3000个请求怎么调度这3000个请求呢? 按照常规负载均衡器，轮询的方式，那么后端每个Pod都将接收1000个请求。那么这1000个请求都将交给新环境处理，这种方式有一个很大的闭端，我们把后端Pod其中一个升级为新版本，另外的2个是旧版本，用户在请求时第一次调度新版本第二次可能调度旧版本用户体验很差。如果过是动态服务后端pod要连接数据库，新版本和旧版本的数据库不兼容，访问旧版本连接新版本库不兼容，访问新版本连接旧版数据库。

因此我们把流量统一处理，而是挑选一部分流量只让他们访问新版本，而不是一视同仁

根据用户请求时，请求报文特征来匹配是否调度到新版本

![image-20240404200118505](../images/image-20240404200118505.png) 



#### 基于Ingress Nginx的灰度发布

基于Ingress Nginx的Canary规则

**1**.**nginx.ingress.kubernetes.io/canary-by-header**：基于该Annotation中指定Request Header进行流量切分，适用于灰度发布以及A/B测试

```bash
在请求报文中，若存在该Header且其值为always时，请求将会被发送到Canary版本
若存在该Header且其值为never时，请求将不会被发送至Canary版本
对于任何其它值，将忽略该Annotation指定的Header，并通过优先级将请求与其他金丝雀规则进行优先级的比较
#指定表头名，但值固定。
可以使用1规则指定标头名，然后结合2规则指定表头值，也可以结合3规则指定正则匹配对应的值
```

 

**2**.**nginx.ingress.kubernetes.io/canary-by-header-value：**基于该Annotation中指定的Request Header的值进行流量切分，标头名称则由前一个Annotation（nginx.ingress.kubernetes.io/canary-by-header）进行指定

```
请求报文中存在指定的标头，且其值与该Annotation的值匹配时，它将被路由到Canary版本，对于任何其它值，将忽略该Annotation
```

**3.nginx.ingress.kubernetes.io/canary-by-header-pattern**

```
同canary-by-header-value的功能类似，但该Annotation基于正则表达式匹配Request Header的值
若该Annotation与canary-by-header-value同时存在，则该Annotation会被忽略
```





**4.nginx.ingress.kubernetes.io/canary-weight**

基于服务权重进行流量切分，适用于蓝绿部署，权重范围0 - 100按百分比将请求路由到Canary Ingress中指定的服务

```
权重为 0 意味着该金丝雀规则不会向Canary入口的服务发送任何请求
权重为100意味着所有请求都将被发送到 Canary 入口
```



**5.nginx.ingress.kubernetes.io/canary-by-cookie**：基于 cookie 的流量切分，适用于灰度发布与 A/B 测试

```
cookie的值设置为always时，它将被路由到Canary入口
cookie的值设置为 never时，请求不会被发送到Canary入口
对于任何其他值，将忽略 cookie 并将请求与其他金丝雀规则进行优先级的比较
```

**规则的应用次序**

Canary规则会按特定的次序进行评估

次序：canary-by-header -> canary-by-cookie -> canary-weight



测试准备：

准备一个ingress ----  old service --- deployment -- pod

准备新版ingress ---- new service --- new deployment --- pod new

这两个ingress 公用同一个主机名，

![image-20240404203428258](../images/image-20240404203428258.png)

    以上全部需要手动实现，很繁琐。
    工作负载型控制器的高级实现：
        Argo Rollouts，可取代Deployment的全部功能
        OpenKruise Kruise Rollouts

示例：

详情请看lerngink8s

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
annotations:
kubernetes.io/ingress.class: nginx
nginx.ingress.kubernetes.io/canary: "true"
nginx.ingress.kubernetes.io/canary-by-header: "Username"
nginx.ingress.kubernetes.io/canary-by-header-pattern: "(vip|VIP)_.*"
name: demoapp-canary-by-header-pattern
spec:
rules:
- host: demoapp.magedu.com
http:
paths:
- backend:
service:
name: demoapp-v11
port:
number: 80
path: /
pathType: Prefix

#权重
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
annotations:
kubernetes.io/ingress.class: nginx
nginx.ingress.kubernetes.io/canary: "true"
nginx.ingress.kubernetes.io/canary-weight: "10"
name: demoapp-canary-by-weight
spec:
rules:
- host: demoapp.magedu.com
http:
paths:
- backend:
service:
name: demoapp-v11
port:
number: 80
path: /
pathType: Prefix
```





Helm包管理利器



#### Helm 基础

Helm是一款简化安装和管理Kubernetes应用程序的工具

为了方便管理，简化部署和删除，复用。为了满足不同环境下的复用性 chart通常是模板，在提交给api-service前赋值

Chart中的yaml文件格式：
            模板文件 --> 向模板字串赋值 --> 完成模板渲染

```
赋值方式：
	命令行选项：helm --set KEY=VALUE --set ...
    值文件：helm -f /PATH/TO/YAML_FILE 
    Chart通常会附带默认的值文件（values.yml）
```

使用chart 运行的程序 release



```
 helm程序组件：
        v2: 
            helm --> Tiller （部署运行在Kubernetes集群上） --> API Server 

        v3: 
            helm --> API Server 
```



可用于Kubernetes之上的应用程序管理的资源配置文件需要以特定的结构组织为Chart

```
Chart代表着可由Helm管理的有着特定格式的程序包
Chart中的资源配置文件通常以模板（go template）形式定义，在部署时，用户可通过向模板参数赋值实现定制化安装的目的
各模板参数通常也有默认值，这些默认值定义在Chart包里一个名为values.yml的文件中
```

类似于kubectl，Helm也是Kubernetes API Server的命令行客户端工具

```
支持kubeconfig认证文件
需要事先从仓库或本地加载到要使用目标Chart，并基于Chart完成应用管理
Chart可缓存于Helm本地主机上
```

支持仓库管理和包管理的各类常用操作，例如Chart仓库的增、删、改、查，以及Chart包的制作、发布、搜

索、下载等









#### Helm及应用部署 

**Helm是啥**

API Server的客户端程序

支持使用kubeconfig文件认证到API Server

从Chart Repository中下载Chart至本地缓存

利用values.yaml完成对Chart中的模板字串的渲染，生成API Server可接受的配置文件

用户可以借助于自定义的值文件和命令行选项“--set”等自定义模板字串值，从而完成自定义部署



**Chart 是什么**

主要由部署某应用需要用到的对象配置所构成的配置文件组成

这些配置中通常使用了模板字串，以便用户根据需要自定义以完成定制

可从社区中获取（https://artifacthub.io/），也可自行创建，并通过社区分发

```
需要先将Chart Repository的信息配置在Helm上才能从中下载Chart，Chart保存在本地缓存中
```



#### 获取并使用Helm

```
wget https://get.helm.sh/helm-v3.14.3-linux-amd64.tar.
tar xvf helm-v3.14.3-linux-amd64.tar.gz
cd linux-amd64/
cp helm /usr/local/bin/
```



常用命令

```bash
#管理仓库
helm repo

如果支持oci就不用导入仓库 否则要导入对应的仓库

#Repostory管理
repo命令，支持repository的add、list、remove、update和index等子命令
#Chart管理
create、 package、pull、 push、dependency、search、show和verify等操作
#Release管理
install、upgrade、get、list、history、status、rollback和uninstall等操作


heml status <Release name> -n namespace

#查看渲染后的values文件
helm get manifest harbor -n harbor
helm get values harbor -n harbor
```



#### 部署wordpress

部署MySQL

```
    helm install mysql  \
        --set auth.rootPassword='zedking' \
        --set global.storageClass=nfs-csi \
        --set architecture=replication \
        --set auth.database=wpdb \
        --set auth.username=wpuser \
        --set auth.password='qwer123' \
        --set secondary.replicaCount=1 \
        --set auth.replicationPassword='zedking' \
        oci://registry-1.docker.io/bitnamicharts/mysql \
        -n wordpress --create-namespace    
```



```
helm install wordpress \
            --set mariadb.enabled=false \
            --set externalDatabase.host=mysql-primary.wordpress.svc.cluster.local \
            --set externalDatabase.user=wpuser \
            --set externalDatabase.password='qwer123' \
            --set externalDatabase.database=wpdb \
            --set externalDatabase.port=3306 \
            --set persistence.storageClass=nfs-csi \
            --set ingress.enabled=true \
            --set ingress.ingressClassName=nginx \
            --set ingress.hostname=www.zedking.blog \
            --set ingress.pathType=Prefix \
            --set wordpressUsername=admin \
            --set wordpressPassword='magedu.com' \
            oci://registry-1.docker.io/bitnamicharts/wordpress \
            -n wordpress --create-namespace  
```

\





harbor

```bash
#添加仓库
helm repo add harbor https://helm.goharbor.io

helm repo list
NAME  	URL                     
harbor	https://helm.goharbor.io

#查看
helm search repo harbor


#查看所有值文件
helm show values harbor/harbor

#安装
helm install myharbor -f harbor-values.yaml harbor/harbor -n harbor --create-namespace
helm unistall myharbor -n harbor
```





## 认证体系

访问API Server

API Server内置了一个有着三级别的访问控制机制

认证 ：辨明身份|身份识别

鉴权 ：检查请求者是否被授予了所请求资源的权限

准入控制：仅同“写”请求相关，负责实现“校验（validating）”和“修订或补全（mutating）

​					校验写请求是否符合规范，补全默认值

```
认证：核验请求者身份的合法性
鉴权：核验请求的操作是否获得许可
准入控制：检查操作内容是否合规/补全
```

读请求是不会经过准入控制插件的

插件化机制，每种访问控制机制均有一组专用的插件栈



一个写请求先到达 认证插件（多个）如果多个认证插件中有一个检查通过，将跳过其他认证插件的检查。
然后到达 鉴权插件（多个）类似于白名单，默认任何权限，所以要先获得许可，没有许可就会被拒绝，如果多个鉴权插件中有一个检查通过，将跳过其他鉴权插件的检查。
最后到达 准入控制 (多个) 准入控制插件的多有插件都要对 写请求 逐一检查，比如 先检查必要字段是否定义，第二插件检查，字段的值是否规范，第三插件补全，就算第一个检查失败了也会继续往下检查，因为要告诉客户端详细的错误（一次性检查出所有错误，统一返回给用户） 只有通过校验检查，才会进行补全

```
认证：身份核验过程遵循“或”逻辑，且任何一个插件核验成功后都将不再进行后续的插件验证
均不成功，则失败，或以“匿名者”身份访问 建议禁用“

鉴权：鉴权过程遵循“或”逻辑，且任何一个插件对操作的许可授权后都将不再进行后续的插件验证
均未许可，则拒绝请求的操作

准入控制：内容合规性检查过程遵循“与”逻辑，且无论成败，每次的操作请求都要经由所有插件的检验
将数据写入etcd前，负责检查内容的有效性，因此仅对“写”操作有效
分两类：validating（校验）和 mutating（补全或订正）
```

API Server中的鉴权框架及启用的鉴权模块负责鉴权

模块化：并允许同时启用多个
            认证插件：可同时存在多个
            鉴权插件：
            准入控制插件：



API Server是Kubernetes集群的网关，是能够与etcd通信惟一入口；

 kube-controller-manager、kube-scheduler、kubelet、kube-proxy，以及后续部署的集群插件CoreDNS、Project 

Calico等，彼此间**互不**通信，彼此间的所有协作均经由API Server的REST API进行，它们都是API Server的客户

端

 确保对API Server的安全访问至关重要

客户端对API Server的访问应经过身份验证及权限检查；

为防止中间人攻击，各类客户端与API Server间的通信都应使用TLS进行加密

 各kubelet也会监听一些套接字，提供一个小型的REST API

 10250是具有所在节点上Pod管理权限的读写端口，应谨慎管理

 10255仅提供只读操作，是REST API的子集

 另外，10248是本地healthz端点使用的端口





#### API 身份验证

**Kubernetes系统的用户大体可分为 2 类**

Service Account：服务账户，指Pod内的进程访问API Server时使用的身份信息，连接到api service prometheus

```
API Server使用ServiceAccount类型的资源对象来保存该类账号
认证到API Server的认证信息称为Service Account Token，它们保存于同名的专用类型的Secret对象中
名称空间级别
```



User Account：用户账户，指非Pod类的客户端访问API Server时使用的身份标识，一般是现实中的“人”

```
API Server没有为这类账户提供保存其信息的资源类型，相关的信息通常保存于外部的文件或认证系统中
身份核验操作可由API Server进行，也可能是由外部身份认证服务完成
本身非由Kubernetes管理，因而作用域为整个集群级别
```

默认每个命名空间下都有一个默认的Serviceaccount，如果我们运行Pod时没指定就用这个默认的账号连接到API server获取元数据信息 dodwoder api 



#### 身份认证策略

**X.509客户端证书认证**  CN/用户名  O/组名

给客户端签发证书的CA必须是API-Server所信任的CA (双向认证) 客户端和服务端都要认证对方的信息

**持有者令牌（bearer token）**

静态令牌文件（Static Token File）

```
需要个互相信任的令牌签发者，  令牌签发者生成密钥并且用自己的私钥加密来确保此密钥就是由我们所信任的令牌签发者签署的。  客户端拿着这个token认证Api-server， Api-server提前信任令牌签发者，并用令牌签发者的公钥解密，校验证书是否被篡改
```

Bootstrap令牌 （第一次加入集群 jont in）

Service Account令牌（非交互式，提前配置在Pod上，运行Pod前由API server签署好，并给pod使用)

Webhook令牌

OIDC（OpenID Connect）令牌（oauth2）

身份认证代理（Authenticating Proxy）

我们把集群创建在阿里云，我们需要阿里云账号，还需要k8s账号。比如登录淘宝需要账号，下单登录账号，看物流要登录账号，这很麻烦，所以我们需要单点认证 SSO，比如可以用qq登录 腾信旗下的很多游戏，不用每个游戏在独立认证一下，只需要点一下授权。

找一个外部单点认证服务，把k8s的账号委托给单点认证服务，



Token Issuer： 
            KeyCloak
            Dex 

#### kubelet启用的身份认证机制

kubelet和Api-server互为客户端服务端

kubelet要作为客户端连接到Api-server 获取关于节点pod信息 创建pod事件 等等

Api-serve 要作为客户端连接到kubelet 执行一些操作，比如用户连接Api-serve 再通过kubelet进入容器

**kubelet的REST API端点默认通过TCP协议的10250端口提供，支持管理操作**

![image-20240406212920650](../images/image-20240406212920650.png)



#### 测试：

静态令牌认证的基础配置

令牌信息保存于文本文件中

```
文件格式为CSV，每行定义一个用户，由“令牌、用户名、用户ID和所属的用户组”四个字段组成，用户组为可选字
段

token,user,uid,"group1,group2,group3"
```

创建文件由kube-apiserver在启动时通过--token-auth-file选项加载 

加载完成后的文件变动，仅能通过重启程序进行重载，因此，相关的令牌会长期有效。（内存中）除非重启否则后续不生效



如果使用kubeadm部署的kube-apiserve 是以静态Pod方式运行， 因此这个因为要创建在宿主机或外部存储，通过挂载的方式挂载到容器中，然后使用选项加载此文件的路径。

```bash
#静态pod默认会加载这么目录下yaml文件，只要有变化就重启Pod
/etc/kubernetes/manifests/
cp /etc/kubernetes/manifests/kube-apiserver.yaml   /root/

#修改kube-apiserver.yaml文件
把文件挂载到Pod中 用hostpath
添加配置 --token-auth-file=
```

![image-20240406221627119](../images/image-20240406221627119.png)

![image-20240406221813436](../images/image-20240406221813436.png)



```bash
#生成token
echo "$(openssl rand -hex 3).$(openssl rand -hex 8)"
a151e0.df5400aa17ef073c
805a29.ff505ca1ede75e53
3cd812.8fde990a9690cd67
#生成static token文件
vim token.csv
a151e0.df5400aa17ef073c,tom,10086,zj
805a29.ff505ca1ede75e53,jerry,10010,zj
3cd812.8fde990a9690cd67,zed,12306,zj


vim /etc/systemd/system/kube-apiserver.service
[Service]
ExecStart=/usr/local/bin/kube-apiserver \
  --allow-privileged=true \
  --token-auth-file=/root/token.csv \ #添加这一项
  --anonymous-auth=false \
  --api-audiences=api,istio-ca \
  --authorization-mode=Node,RBAC \
  --bind-address=10.0.0.200 \
  --client-ca-file=/etc/kubernetes/ssl/ca.pem \
  --endpoint-reconciler-type=lease \
  --etcd-cafile=/etc/kubernetes/ssl/ca.pem \

systemctl daemon-reload
systemctl restart kube-apiserver.service && systemctl status kube-apiserver.service



#正常检验服务端证书
每个工作节点/etc/kubernetes/ssl/都保存了api CA证书，便于我们客户端校验Api-server的身份
kubectl --server=https://10.0.0.200:6443 --token="a151e0.df5400aa17ef073c" --certificate-authority=/etc/kubernetes/ssl/ca.pem get pods

#跳过服务端证书校验
kubectl --server=https://10.0.0.200:6443 --token="a151e0.df5400aa17ef073c" --insecure-skip-tls-verify=true  get pods
Error from server (Forbidden): pods is forbidden: User "tom" cannot list resource "pods" in API group "" in the namespace "default"


#使用curl命令直接发起请求测试：
curl -k -H "Authorization: Bearer 805a29.ff505ca1ede75e53" https://10.0.0.200:6443/api/v1/namespace/default/pods/


```

#### X509 数字证书认证

X509客户端认证依赖于PKI证书体系，kubeadm部署Kubernetes集群时会自动生成所需要的证书，它们位于/etc/kubernetes/pki目录下

有三套CA  

etcd集群互相需要对等证书认证，双向认证，需要etcd CA向 etcd 签署客户端证书和服务端证书

Api-server是服务端，kubernetes-CA 向kube-scheduler、kube-proxy、kube-controlller、kubectl、kubelet客户端证书

第三方API认证扩展外部认证颁发

![image-20240406224125509](../images/image-20240406224125509.png)

当某个节点要加入集群，有kubelet向api-server申请csr请求用来加入集群时候用，kubeadm

```bash 
#手动确认
kubectl certificate approve|deny
这条命令会去调用/etc/kubernetes/ssl/ca.pem 给客户端签署证书，api-server支持自动签署功能(kubeadm)
```





```
[root@node-01 ~]#ll /etc/kubernetes/ssl/
总计 20
drwxr-xr-x 2 root root 4096  3月 26 14:14 ./
drwxr-xr-x 3 root root 4096  3月 26 14:14 ../
-rw-r--r-- 1 root root 1310  3月 26 14:14 ca.pem
-rw-r--r-- 1 root root 1675  3月 26 14:14 kubelet-key.pem
-rw-r--r-- 1 root root 1460  3月 26 14:14 kubelet.pem
```





 **数字证书认证测试1：**

```bash
mkdir crt
openssl genrsa -out lixijun.key 2048

openssl req -new -key lixijun.key -out lixijun.csr -subj "/CN=lixijun/O=zj"
#将CSR进行base64编码并复制到配置清单中
cat  lixijun.csr | base64 | tr -d "\n"
LS0tLS1CRUdJTiBDRVJUSUZJQ0FURSBSRVFVRVNULS0tLS0KTUlJQ1pEQ0NBVXdDQVFBd0h6RVFNQTRHQTFVRUF3d0hiR2w0YVdwMWJqRUxNQWtHQTFVRUNnd0NlbW93Z2dFaQpNQTBHQ1NxR1NJYjNEUUVCQVFVQUE0SUJEd0F3Z2dFS0FvSUJBUURIZTFKNVVEUks5Q0NxS1Q5Rk5xN0g1V052CmF1NFNrNWMyUGN0ZndlRWFvZTlzN2JMMnFKV2QrVDV0dWY1OE0wdHY5dERJYVpCU3JNeVFSVkJ4aVkzeXBxR2UKZ0dHNDlJelNoOTVrcjl5UEpNeEFlTlN3R080bmhFcWZRelU5eGw4ODMrSHhKNmZTK0FlTS84aUVIbjdWWGRDWgpkdmVPT3ZEM1hoRUV5WU9TMGJ6T1dhSE9DYWJvY3hHQ0drbFBnMGhIRmJTVlQzZFdYTEtvWGFDZkpFTWFEcmdkClE3cFgxQVlhQ3dWY1NsanpTb3BjVzhwMVRTMmhUazhVMGcyNVowL2ExTTQzclBVL3dHKzdjeWYvenZ4N0F0ZkkKMEx2QUVQK0NRUkVWRnExUFhMRW92L0JBeDE3MDV1alUrYnhtaDZUa0xacGZYZmZaK3lkdGpOZkxnRmR6QWdNQgpBQUdnQURBTkJna3Foa2lHOXcwQkFRc0ZBQU9DQVFFQWNoa1VVeitlQmpidGhyc0NJZUU2bXZWSWYzTFMxazl2CktSbE1yMHVGUnp4bWZJT0VsL1IzYW1POVJMSnRnVkJJdlAwdlg3K2pzZDd6RmQ1NEZhZnorSWhpWkYrSUZWSysKbUtiNkNTcHBMb1J4R2I2bW9kcGRXS3RWd09jTWxwTGtiTGJHbGF0UkVZay9xY244dGdHQjhMcVZFTDMwUUgvbAovbHFpRGpIODNVcWo1Z1JIcW9aZEpaeEFGbUZXT0lIZ09GQjFTTWhMaWMwTjl6UmN4VmtHQncyZ0pUa3Z6TUkzCnNQVEtlUUUyU3I4VTR0czM0aFZHOFZDNVJpRnVHYVAzanRTYk03V05YNHJjeFhibVBWQWxQOHJMT1B6S3cyWmoKbW40RnRFcjdqY0tUMHhidUw4UERkcmhZV2xXM0NEUzFVTTJuZ2VKUy9rK1Q0NzBOc2tMUFVBPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUgUkVRVUVTVC0tLS0tCg==
```





```yaml
#创建为Kubernetes的CSR资源对象，并提交给API Server 
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: lixijun
spec:
  request: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURSBSRVFVRVNULS0tLS0KTUlJQ1pEQ0NBVXdDQVFBd0h6RVFNQTRHQTFVRUF3d0hiR2w0YVdwMWJqRUxNQWtHQTFVRUNnd0NlbW93Z2dFaQpNQTBHQ1NxR1NJYjNEUUVCQVFVQUE0SUJEd0F3Z2dFS0FvSUJBUURIZTFKNVVEUks5Q0NxS1Q5Rk5xN0g1V052CmF1NFNrNWMyUGN0ZndlRWFvZTlzN2JMMnFKV2QrVDV0dWY1OE0wdHY5dERJYVpCU3JNeVFSVkJ4aVkzeXBxR2UKZ0dHNDlJelNoOTVrcjl5UEpNeEFlTlN3R080bmhFcWZRelU5eGw4ODMrSHhKNmZTK0FlTS84aUVIbjdWWGRDWgpkdmVPT3ZEM1hoRUV5WU9TMGJ6T1dhSE9DYWJvY3hHQ0drbFBnMGhIRmJTVlQzZFdYTEtvWGFDZkpFTWFEcmdkClE3cFgxQVlhQ3dWY1NsanpTb3BjVzhwMVRTMmhUazhVMGcyNVowL2ExTTQzclBVL3dHKzdjeWYvenZ4N0F0ZkkKMEx2QUVQK0NRUkVWRnExUFhMRW92L0JBeDE3MDV1alUrYnhtaDZUa0xacGZYZmZaK3lkdGpOZkxnRmR6QWdNQgpBQUdnQURBTkJna3Foa2lHOXcwQkFRc0ZBQU9DQVFFQWNoa1VVeitlQmpidGhyc0NJZUU2bXZWSWYzTFMxazl2CktSbE1yMHVGUnp4bWZJT0VsL1IzYW1POVJMSnRnVkJJdlAwdlg3K2pzZDd6RmQ1NEZhZnorSWhpWkYrSUZWSysKbUtiNkNTcHBMb1J4R2I2bW9kcGRXS3RWd09jTWxwTGtiTGJHbGF0UkVZay9xY244dGdHQjhMcVZFTDMwUUgvbAovbHFpRGpIODNVcWo1Z1JIcW9aZEpaeEFGbUZXT0lIZ09GQjFTTWhMaWMwTjl6UmN4VmtHQncyZ0pUa3Z6TUkzCnNQVEtlUUUyU3I4VTR0czM0aFZHOFZDNVJpRnVHYVAzanRTYk03V05YNHJjeFhibVBWQWxQOHJMT1B6S3cyWmoKbW40RnRFcjdqY0tUMHhidUw4UERkcmhZV2xXM0NEUzFVTTJuZ2VKUy9rK1Q0NzBOc2tMUFVBPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUgUkVRVUVTVC0tLS0tCg==
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 864000  # ten days
  usages:
  - client auth

#提交给api-server
kubectl apply -f lxjcsr.yaml
##以Kubernetes管理员的身份，签署CSR
kubectl get csr
kubectl certificate approve lixijun #这条命令会去调用/etc/kubernetes/ssl/ca.pem 给客户端签署证书

#签署后客户端不可以直接用，用户获取证书信息，并保存为证书文件；
kubectl get csr lixijun -o json
kubectl get csr lixijun -o jsonpath='{.status.certificate}'| base64 -d > lxj.crt
```



 **数字证书认证测试2：**

第一种方式太过于麻烦，如果我们可以坐在master节点可以直接手动签发

注意: 这种方式无法回收

```bash
cd /etc/kubernetes/ssl/
#生成私钥
(umask 077; openssl genrsa -out msq.key 4096)
#创建证书签署请求
openssl req -new -key msq.key -out msq.csr -subj "/CN=msq/O=zj"
#由Kubernetes CA签署证书
openssl x509 -req -days 365 -CA ./ca.pem -CAkey ./ca-key.pem -CAcreateserial -in ./msq.csr -out ./msq.crt

#将ssl目录下的msq.key和msq.crt复制到某部署了kubectl的主机上，即可进行测试
这里以k8s-node01为示例；只需要复制msq.key和msq.crt即可，因为集群工作节点上已经有ca.crt文件
rsync -a msq.crt msq.key root@10.0.0.201:/root/
#测试
kubectl --server=https://10.0.0.200:6443 --client-key='msq.key' --client-certificate='msq.crt' --insecure-skip-tls-verify=true  get pod
```





X509客户端认证

```bash
rsync -a lxj.crt root@10.0.0.201:/root/lxj.crt
rsync -a lixijun.key  root@10.0.0.201:/root/

#测试
kubectl options
kubectl --server=https://10.0.0.200:6443 --client-key='./lixijun.key' --client-certificate='./lxj.crt' --insecure-skip-tls-verify=true  get pod 
```







#### Kubeconfig

命令行每次输入，太不方便了，于存储身份认证信息，以便于kubectl客户端加载并认证到API Server

```bash
kubectl --server=https://10.0.0.200:6443 --client-key='./lixijun.key' --client-certificate='./lxj.crt' --insecure-skip-tls-verify=true  get pod 
```

我们还可以定义两个Kubeconfig，cluster1一个 cluster2一个，然后使用KUBECONFIG环境变量把他们合并成一个Kubeconfig



kubeconfig是YAML格式的文件，用于存储身份认证信息，以便于客户端加载并认证到API Server

kubeconfig保存有认证到一至多个Kubernetes集群的相关配置信息，并允许管理员按需在各配置间灵活切换

```ABAP
clusters：Kubernetes集群访问端点（API Server）列表
users：认证到API Server的身份凭据列表
contexts：将每一个user同可认证到的cluster建立关联的上下文列表
current-context：当前默认使用的context
```

**客户端程序加载的kubeconfig文件的途径及次序**

```bash
--kubeconfig选项
KUBECONFIG环境变量：其值是包含有kubeconfig文件的列表
默认路径：$HOME/.kube/config

#注意
KUBECONFIG环境变量可以包含多个kubeconfig文件 :冒号隔开
```

常用命令：

```bash
kubectl config view --raw
#cluster相关的子命令
get-clusters
set-cluster
delete-cluster

#user相关的子命令
get-users
set-credentials
delete-user

#context相关的子命令
get-contexts
set-context
delete-context
rename-context

#current-context相关的子命令
current-context
use-context
```



##### 设定kubeconfig文件

示例1：为静态令牌认证的用户设定一个自定义的kubeconfig文件

```bash
kubectl config view --kubeconfig=/root/crt/kubeusers.conf 
#定义Cluster
提供包括集群名称、API Server URL和信任的CA的证书相关的配置；clusters配置段中的各列表项名称需要惟一
kubectl config set-cluster mykube --embed-certs=true --certificate-authority=/etc/kubernetes/ssl/ca.pem --server="https://10.0.0.200:6443" --kubeconfig=/root/crt/kubeusers.conf 
#把引用的证书文件直接保存到kubeconf文件中，如果不保存到kubeconf文件中那么就加载路径上的文件，外部依赖 --embed-certs=true
ca.pem 是由 Kubernetes 集群颁发的根证书，用于签署集群中其他组件的证书。这意味着如果你想要连接到 Kubernetes 集群，你需要将这个根证书提供给你的客户端，以便客户端可以验证集群颁发的证书的真实性。


#定义User
添加身份凭据，使用静态令牌文件认证的客户端提供令牌令牌即可
kubectl config set-credentials tom --token="a151e0.df5400aa17ef073c" --kubeconfig=/root/crt/kubeusers.conf

#定义Context
为用户tom的身份凭据与mykube集群建立映射关系
kubectl config set-context tom@mykube --cluster=mykube --user=tom --kubeconfig=/root/crt/kubeusers.conf 

#设定Current-Context
kubectl config use-context tom@mykube --kubeconfig=/root/crt/kubeusers.conf 

#测试
如果没设置Current-Context就得指定
kubectl get pods --kubeconfig=/root/crt/kubeusers.conf --context='tom@mykube'
```



##### 设定kubeconfig文件（3）

```bash
将基于X509客户端证书认证的lxj用户添加至kubeusers.conf文件中，同一个列表下，不同项
的名称不能相同
#定义集群
kubectl config set-cluster x509 --embed-certs=true --certificate-authority=/etc/kubernetes/ssl/ca.pem --server="https://10.0.0.200:6443" --kubeconfig=/root/crt/kubeusers.conf

#定义User
kubectl config set-credentials lxj --client-certificate=/root/crt/lxj.crt --client-key=/root/crt/lixijun.key --embed-certs=true --kubeconfig=/root/crt/kubeusers.conf

#定义Context
kubectl config set-context lxj@x509 --cluster=x509 --user=lxj --kubeconfig=/root/crt/kubeusers.conf

#测试
kubectl get pods --kubeconfig=/root/crt/kubeusers.conf --context='lxj@x509'

```



##### 合并kubeconfig文件

客户端能够通过多种途径获取到kubeconfig文件时，将遵循如下逻辑进行文件合并

设置了--kubeconfig参数时，则仅使用指定的文件，且不进行合并；该参数只能使用一次；

若设置了KUBECONFIG环境变量，则将其值用作应合并的文件列表；处理规则

```
忽略不存的文件
遇到内容无法反序列化的文件时，将生成错误信息
文件列表中，第一个设定了特定值或映射键(map key)的文件是为生效文件
创建一个键时，其将保存于列表中的第一个文件中
```





```bash
#合并kubeconfig
export KUBECONFIG='/root/crt/kubeusers.conf:/root/.kube/config'
kubectl config view

如果多个kubeconfig文件中有相同的定义，从左到右第一个文件的生效，后面的文件不生效。
```







## Service Account

### Service Account基础

API Server同样需要对这类来自于Pod资源中客户端程序进行身份验证，Service Account也就是设计专用于这类场景的账号

```
自动设定：Service Account通常由API Server自动创建并通过 ServiceAccount准入控制器自动关联到集群中创建的每个Pod上
自定义：在Pod规范上，使用serviceAccountName指定要使用的特定ServiceAccount
```

#### ServiceAccount资源

ServiceAccount是Kubernetes API上的标准资源类型
基于**资源对象**保存ServiceAccount的数据 (保存在Etcd中)
认证信息保存于ServiceAccount对象专用的Secret中（v1.23及之前的版本）
隶属名称空间级别，专供集群上的Pod中的进程访问API Server时使用

```
在早期版本，创建ServiceAccount资源会通过Token Controller 自动创建一个同名的Secret，用来保存凭据tonken
```

 



Kubernetes基于三个组件完成Pod上serviceaccount的自动化
ServiceAccount Admission Controller：负责完成Pod上的ServiceAccount的自动化

```
为每个名称空间生成一个默认的default ServiceAccount及其依赖到的Secret对象（如果用得到）
为未定义serviceAccountName的Pod资源自动附加名称空间下的serviceaccounts/default；
为定义了serviceAccountName的Pod资源检查其引用的目标对象是否存在(手动指定时)
```

以下两种是 Controller marager的组件

Token Controller

 ServiceAccount Controller



#### ServiceAccount的Secret和Token

ServiceAccount使用专用的Secret对象（Kubernetes v1.23-）存储相关的敏感信息

Secret对象的类型标识为“kubernetes.io/serviceaccount”

该Secret对象会自动附带认证到API Server用到的Token，也称为ServiceAccount Token

**ServiceAccount** Token的不同实现方式

Kubernetes v1.20

```
系统自动生成专用的Secret对象，并基于secret卷插件关联至相关的Pod；
Secret中会自动附带Token，且永久有效
```

Kubernetes v1.21-v1.23：

```
系统自动生成专用的Secret对象，并通过projected卷插件关联至相关的Pod；
Pod不会使用Secret上的Token，而是由Kubelet向TokenRequest API请求生成，每个默认有效期为一年，且每小时更新一次；  
```

Kubernetes v1.24+

```
系统不再自动生成专用的Secret对象
由Kubelet负责向TokenRequest API请求生成Token
```



**注解：**

```
创建Serviceaccount时，会自动创建Secret，pod启动时用到Serviceaccount，就会把这个自动创建的secret挂载到容器中 /var/run/secrets/kubernetes.io/serviceaccount/
```



#### ServiceAccount中的数据

ServiceAccount专用的Secret对象有三个固定的数据项，它们的键名称分别为

```
ca.crt：Kubernetes CA的数字证书
namespace：该ServiceAccount可适用的名称空间
token：认证到API Server的令牌，其生成方式曾多次变动
```

Kubernetes v1.21及之后的版本中，Pod加载上面三种数据的方式，改变为基于projected卷插件，通过三个数据源（source）分别进行

```
serviceAccountToken：提供由Kubelet负责向TokenRequest API请求生成的Token
configMap：经由kube-root-ca.crt这个ConfigMap对象的ca.crt键，引用Kubernetes CA的证书
downwardAPI：基于fieldRef，获取当前Pod所处的名称空间
```



![image-20240407144541624](../images/image-20240407144541624.png)



#### 创建和使用ServiceAccount

```bash
kubectl create serviceaccount zedking -n dev --dry-run=client -o yaml
```



```
apiVersion: v1
kind: ServiceAccount
metadata:
  name: …
  namespace: …
imagePullSecrets <[]Object>
secrets <[]Object>
automountServiceAccountToken <boolean>
```







## Kubernetes鉴权体系

```
支持的鉴权模块
Node：专用的授权模块，它基于kubelet将要运行的Pod向kubelet进行授权；
ABAC：通过将属性（包括资源属性、用户属性、对象和环境属性等）组合 在一起的策略，将访问权限授予用户；
RBAC：基于企业内个人用户的角色来管理对计算机或网络资源的访问的鉴权方法；
Webhook：用于支持同Kubernetes外部的授权机制进行集成；
```

配置方法

在kube-apiserver上使用 --authorization-mode 选项进行定义

kubeadm部署的集群，默认启用了Node和RBAC

多个模块彼此间以逗号分隔



```
客户端请求api-server，这个请求可能是GET,DELETE,UPDATE等，先经由认证类插件只要一个检擦通过就到鉴权环节，客户端请求可能是某个命名空间下的某些资源增删改查，鉴权插件要检擦该用户是否被授予对目标资源增删改查的权限。如果是写操作还要经过准入控制的参与，校验类插件先检查请求的合法性，再有补全修订类插件修订的结果存入etcd。
```

#### RBAC基础 ROle

```
RBAC基础概念
 实体（Entity）：在RBAC也称为Subject，通常指的是User、Group或者是ServiceAccount；
 角色（Role）：承载资源操作权限的容器；
 资源（Resource）：在RBAC中也称为Object，指代Subject期望操作的目标，例如Secret、Pod及Service对象等；
仅限于/api/v1/…及/apis/<group>/<version>/…起始的路径；
其它路径对应的端点均被视作“非资源类请求（Non-Resource Requests）”，例如/api或/healthz等端点；
 动作（Actions）：Subject可以于Object上执行的特定操作，具体的可用动作取决于Kubernetes的定义；
资源型对象
	只读操作：get、list、watch等
	读写操作：create、update、patch、delete、deletecollection等
非资源型端点仅支持get操作
 角色绑定（Role Binding）：将角色关联至实体上，它能够将角色具体的操作权限赋予给实体；
```

```
Subject: User Account, Service Account, Group 
        Action: create, delete, update, get, deletecollction, list, watch 
            Read: get/list/watch 
            Write: create/delete/deletecollection/patch/update 
        Object: Resources, non-resource url 
                
				Namespace级别资源类型：Role
                Namesapce级别资源类型和Cluster级别资源类型：ClusterRole

```

不能直接给用户授权，要先创建role 给role 授权，然后让用户扮演Role



授予名称空间级别资源的权限： 用户 --> RoleBinding --> Role <-- 许可（Resources/Action）

授予集群级别资源的： 用户 --> ClusterRoleBinding --> ClusterRole <-- 许可（Resources/Action）

```
用 ClusterRoleBinding --> ClusterRole  该用户将获得管理整个集群的能力，前提ClusterRole有许可

集群级别资源类型的权限：整个集群上的集群级别的资源和命名空间级别
名称空间级别资源类型的权限：整个集群上的所有名称空间内的名称空间级别的资源
```



```bash
当我们创建ClusterRole时，并赋予最高权限。我们用ClusterRoleBinding --> ClusterRole 那么该用户将获得所有命名空间下所有资源的权限，并且获得集群级别资源的权限

#用户 --> RoleBinding --> ClusterRole <-- 许可（Resources/Action）
当我们用 RoleBinding----ClusterRole时:
ClusterRole 上的集群级别的资源不可用，且所有名称空间级别权限缩小为RoleBinding所在的命名空间权限

```



```
Role/ClusterRole/RoleBinding/ClusterRoleBinding是API Server内置的标准资源类型：
Role和RoleBinding：名称空间级别
ClusterRole和ClusterRoleBinding：集群级别
```





**role**

```bash
#创建role
#想要用rolebinding绑定role那么就要在所在命名空间下创建role，并使用rolebinding这个角色

kubectl create role read --verb=get,list,watch --resource=deployments,pods,services  --namespace=default --dry-run=client -o yaml

verb：允许在资源上使用的操作（verb）列表
resources.group/subresource：操作可施加的目标资源类型或子资源列表
resourcename：特定的资源对象列表，可选
```

**RoleBinding** 

```bash
kubectl create rolebinding NAME --clusterrole=NAME|--role=NAME [--user=username] [--group=groupname] [--serviceaccount=namespace:serviceaccountname]

#可以绑定到Role，也可以绑定到ClusterRole，后者会将ClusterRole的权限缩减至当前名称空间之内
#Subject可以是User、Group或者ServiceAccount
示例：将用户tom绑定至角色read之上
kubectl create rolebinding tom-binding-read --role=read --user=tom --namespace=default

#测试
kubectl get service --kubeconfig=/root/crt/kubeusers.conf
#绑定组（组是创建用户指定的）
kubectl create rolebinding zj-binding-read --role=read --group=zj --namespace=default

#绑定Serviceaccount（可以跨命名空间访问资源）
kubectl create sa jenkins -n dev
kubectl create rolebinding sa-read --role=read --serviceaccount=dev:jenkins --namespace=default
我们把dev命名空间下的jenkins serviceaccount，绑定到namespace=default，那么dev 名称空间下的pod如果用了jenkins serviceaccount，就可以访问default下资源，而不是自己

#在 Kubernetes 中，角色（Role）和角色绑定（RoleBinding）的命名空间不一定要与角色所属的命名空间相匹配。这意味着您可以在一个命名空间中创建一个角色，然后在另一个命名空间中创建一个角色绑定来使用该角色。那就是我们随便在其他名称空间创建role，然后再当前名称空间创建rolebinding此角色，即可获取当前名称空间权限，RoleBinding 也可以和服务账户不在同一个命名空间。
```





资源示例：

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: tom-binding-read
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: read
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: tom
  
  
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: jerry-binding-cluster-admin
  namespace: test
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: jerry
```



### ClusterRole和ClusterRoleBinding

```bash
kubectl create clusterrole cluster-read --verb=get,list,watch --resource=sts,pvc,pv,sc --dry-run=client -o yaml

kubectl create clusterrolebinding NAME --clusterrole=NAME [--user=username] [--
group=groupname] [--serviceaccount=namespace:serviceaccountname]

kubectl create clusterrolebinding lxj-admin --clusterrole=cluster-admin  --user=lixijun
```



**RoleBinding和ClusterRoleBinding绑定一个ClusterRole的区别:**

```
ClusterRoleBinding:得到的是ClusterRole定义的所有权限，包括集群级别的资源类型的授权，以及全部名称空间上的名称空间级别资源类型的授权；
RoleBinding:得到的仅仅是RoleBinding自身所有名称空间上的仅限于名称空间级别的资源类型的授权；
```

#### 默认的ClusterRole及ClusterRoleBinding

启用RBAC鉴权模块时，API Server会自动创建一组ClusterRole和ClusterRoleBinding对象

多数都以“system:”为前缀，也有几个面向用户的ClusterRole未使用该前缀，如cluster-admin、admin等

它们都默认使用“kubernetes.io/bootstrapping: rbac-defaults”这一标签

```bash
默认的ClusterRole大体可以分为如下5个类别
#API发现相关的角色
包括system:basic-user、system:discovery和system:public-info-viewer
#面向用户的角色
包括cluster-admin、admin、edit和view
#核心组件专用的角色
包括system:kube-scheduler、system:volume-scheduler、system:kube-controller-manager、system:node和system:node-proxier等
#其它组件专用的角色包括
system:kube-dns、system:node-bootstrapper、system:node-problem-detector和system:monitoring等

```



**内置的面向用户的ClusterRole：**
   		      cluster-admin, admin, edit, view 

| ClusterRole   | 默认的 ClusterRoleBinding | 描述                                                         |
| ------------- | ------------------------- | ------------------------------------------------------------ |
| cluster-admin | system:masters 组         | 允许用户在目标范围内的任意资源上执行任意操作；使用ClusterRoleBinding关联至用户时，授权操作集群及所有名称空间中任何资源；使用RoleBinding关联至用户时，授权控制其所属名称空间中的所有资源，包括Namespace资源自身； |
| admin         |                           | 管理员权限，主要用于结合RoleBinding为特定名称空间快速授权生成管理员用户，它能够将RoleBinding所属名称空间中的大多数资源的读/写权限授予目标用户，包括创建Role和RoleBinding的能力；但不支持对ResourceQuota及Namespace本身进行操作； |
| edit          |                           | 接近于admin的权限，支持对名称空间内的大多数对象进行读/写操作，包括Secret，但不允许查看或修改Role及RoleBinding； |
| view          |                           | 允许以只读方式访问名称空间中的大多数对象，但不包括Role、RoleBinding和Secret； |



默认kubernetes-admin用户就拥有管理员权限，但是他并没有clusterrolebinding一个集群角色，是因为他的证书中的 用户添加到了一个特定组 而这个组就是管理员组

验证：

```bash
kubectl config view --raw
#复制证书内容并解码
[root@master-01 crt]#echo "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUQyakNDQXNLZ0F3SUJBZ0lVUHl3TC8rb00rRXBQbUpKTldzUW9uYit6T0FNd0RRWUpLb1pJaHZjTkFRRUwKQlFBd1pERUxNQWtHQTFVRUJoTUNRMDR4RVRBUEJnTlZCQWdUQ0VoaGJtZGFhRzkxTVFzd0NRWURWUVFIRXdKWQpVekVNTUFvR0ExVUVDaE1EYXpoek1ROHdEUVlEVlFRTEV3WlRlWE4wWlcweEZqQVVCZ05WQkFNVERXdDFZbVZ5CmJtVjBaWE10WTJFd0lCY05NalF3TXpJMk1EWXdOREF3V2hnUE1qQTNOREF6TVRRd05qQTBNREJhTUdjeEN6QUoKQmdOVkJBWVRBa05PTVJFd0R3WURWUVFJRXdoSVlXNW5XbWh2ZFRFTE1Ba0dBMVVFQnhNQ1dGTXhGekFWQmdOVgpCQW9URG5ONWMzUmxiVHB0WVhOMFpYSnpNUTh3RFFZRFZRUUxFd1pUZVhOMFpXMHhEakFNQmdOVkJBTVRCV0ZrCmJXbHVNSUlCSWpBTkJna3Foa2lHOXcwQkFRRUZBQU9DQVE4QU1JSUJDZ0tDQVFFQXZ4VmZWU2RsSEI3VENQY28KQzVvODdMSTRnbmRrMDlISW1VTm9RbW9SR1hONmxxRVdrb1YvOUF6c1BsVHFxSloyc09INC9oSzB2WXprb1hmMwpNZS9nQnlLS2o0NFo5QVJ5Z0dKeVI5UUtBTE0xcnIwNmo4U05kaE9TUFBPTWREcTFvem1VUFdsbVZYMzYrb1QyCmptYlZoOVB4Vk9OWHNzK2RiNFJFK2dMUTU4MSttTlNwWjhuMnRjbmsyK2V1K0MwY3k1YjBGMzYyL0J2UXkzd3cKWDB1VEZCV0RFMk43NkNMWm1zZzloVEhnbFdFOUZuWk1reERsaUZUS0tkZjBYcXYzR2ZiNmVTQ3pvNDR1c1g1RAo3OE4yU1QrazhCQ25za0p5VkpWWXFENThlQlNoNWtTV2I3NURQc2QyZkh5WjZUczIxa0pFZkNBbWF4Z1F2OGI1CjRyVmVKd0lEQVFBQm8zOHdmVEFPQmdOVkhROEJBZjhFQkFNQ0JhQXdIUVlEVlIwbEJCWXdGQVlJS3dZQkJRVUgKQXdFR0NDc0dBUVVGQndNQ01Bd0dBMVVkRXdFQi93UUNNQUF3SFFZRFZSME9CQllFRkcwUGo5Ym1wOFJoWDJaSwpmZkhzaHYwTXFuV2lNQjhHQTFVZEl3UVlNQmFBRkpNd2Z0UlB3cUlONWNwV1VodVVQZEFCQTJscE1BMEdDU3FHClNJYjNEUUVCQ3dVQUE0SUJBUUF6djJQNlprTGxGWWRPRko5VXRpUk9xUjc1OTNua3YzbTRyTS9LOWI1Yjh6UngKNGVDZkoyYkVqbDhiUEpINjdkVEVuVlFDeW82WDRRNHlKdmExSmxaWXRIY3ArNmhBcDYrTnZsdTVpc2hqbUJjRApWSUUxN3RydTVjdW9yQjNWT3hqVDk2TU9rNnFETjZCMnZndkJjYkdrYWI4NFN5bERseW5OQm93NzJ4bzBEdGdRCm1sUnh1bkI3VjBhUHdkN3oxc1BzRVlUdWhienp5aUFpc3o4ZEVtMlE3di9lWVV0cVh5aEJRTXp4NVRPdG9td0cKQkhNdTFvSG82anVoMFlSbTY2RHMvKzA0S0ZIWmxFbEt5dTlYQjZBOWlWcUpCS3ZZTWlmNlV5ZzBIQWVWUUwrVApkWEFCNVpRQ25lQlZ6NXdvN3NIMEt6MGkwTnMyUWhzRHY4KzVpbER3Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K" | base64 -d > zs.csr
root@master-01 ~]#openssl x509 -noout -text  -in zs.crt 
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            3f:2c:0b:ff:ea:0c:f8:4a:4f:98:92:4d:5a:c4:28:9d:bf:b3:38:03
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: C = CN, ST = HangZhou, L = XS, O = k8s, OU = System, CN = kubernetes-ca
        Validity
            Not Before: Mar 26 06:04:00 2024 GMT
            Not After : Mar 14 06:04:00 2074 GMT
        Subject: C = CN, ST = HangZhou, L = XS, O = system:masters, OU = System, CN = admin												#注意这个组
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:bf:15:5f:55:27:65:1c:1e:d3:08:f7:28:0b:9a:
                    3c:ec:b2:38:82:77:64:d3:d1:c8:99:43:68:42:6a:
                    11:19:73:7a:96:a1:16:92:85:7f:f4:0c:ec:3e:54:
                    ea:a8:96:76:b0:e1:f8:fe:12:b4:bd:8c:e4:a1:77:
                    f7:31:ef:e0:07:22:8a:8f:8e:19:f4:04:72:80:62:
                    72:47:d4:0a:00:b3:35:ae:bd:3a:8f:c4:8d:76:13:
                    92:3c:f3:8c:74:3a:b5:a3:39:94:3d:69:66:55:7d:
                    fa:fa:84:f6:8e:66:d5:87:d3:f1:54:e3:57:b2:cf:
                    9d:6f:84:44:fa:02:d0:e7:cd:7e:98:d4:a9:67:c9:
                    f6:b5:c9:e4:db:e7:ae:f8:2d:1c:cb:96:f4:17:7e:
                    b6:fc:1b:d0:cb:7c:30:5f:4b:93:14:15:83:13:63:
                    7b:e8:22:d9:9a:c8:3d:85:31:e0:95:61:3d:16:76:
                    4c:93:10:e5:88:54:ca:29:d7:f4:5e:ab:f7:19:f6:
                    fa:79:20:b3:a3:8e:2e:b1:7e:43:ef:c3:76:49:3f:
                    a4:f0:10:a7:b2:42:72:54:95:58:a8:3e:7c:78:14:
                    a1:e6:44:96:6f:be:43:3e:c7:76:7c:7c:99:e9:3b:
                    36:d6:42:44:7c:20:26:6b:18:10:bf:c6:f9:e2:b5:
                    5e:27
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage: 
                TLS Web Server Authentication, TLS Web Client Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Subject Key Identifier: 
                6D:0F:8F:D6:E6:A7:C4:61:5F:66:4A:7D:F1:EC:86:FD:0C:AA:75:A2
            X509v3 Authority Key Identifier: 
                93:30:7E:D4:4F:C2:A2:0D:E5:CA:56:52:1B:94:3D:D0:01:03:69:69
    Signature Algorithm: sha256WithRSAEncryption
    Signature Value:
        33:bf:63:fa:66:42:e5:15:87:4e:14:9f:54:b6:24:4e:a9:1e:
        f9:f7:79:e4:bf:79:b8:ac:cf:ca:f5:be:5b:f3:34:71:e1:e0:
        9f:27:66:c4:8e:5f:1b:3c:91:fa:ed:d4:c4:9d:54:02:ca:8e:
        97:e1:0e:32:26:f6:b5:26:56:58:b4:77:29:fb:a8:40:a7:af:
        8d:be:5b:b9:8a:c8:63:98:17:03:54:81:35:ee:da:ee:e5:cb:
        a8:ac:1d:d5:3b:18:d3:f7:a3:0e:93:aa:83:37:a0:76:be:0b:
        c1:71:b1:a4:69:bf:38:4b:29:43:97:29:cd:06:8c:3b:db:1a:
        34:0e:d8:10:9a:54:71:ba:70:7b:57:46:8f:c1:de:f3:d6:c3:
        ec:11:84:ee:85:bc:f3:ca:20:22:b3:3f:1d:12:6d:90:ee:ff:
        de:61:4b:6a:5f:28:41:40:cc:f1:e5:33:ad:a2:6c:06:04:73:
        2e:d6:81:e8:ea:3b:a1:d1:84:66:eb:a0:ec:ff:ed:38:28:51:
        d9:94:49:4a:ca:ef:57:07:a0:3d:89:5a:89:04:ab:d8:32:27:
        fa:53:28:34:1c:07:95:40:bf:93:75:70:01:e5:94:02:9d:e0:
        55:cf:9c:28:ee:c1:f4:2b:3d:22:d0:db:36:42:1b:03:bf:cf:
        b9:8a:50:f0


#可以看到这个组system:masters 被绑定到了这个集群角色cluster-admin（内置管理员角色）
[root@master-01 ~]#kubectl describe  clusterrolebinding cluster-admin
Name:         cluster-admin
Labels:       kubernetes.io/bootstrapping=rbac-defaults
Annotations:  rbac.authorization.kubernetes.io/autoupdate: true
Role:
  Kind:  ClusterRole
  Name:  cluster-admin
Subjects:
  Kind   Name            Namespace
  ----   ----            ---------
  Group  system:masters  


#
kubectl create rolebinding jerry-view-dev  --clusterrole=view --user=jerry -n dev
```



##### Prometheus的权限需求

将Prometheus部署运行于Kubernetes之上并监控集群时，需要使用专用的ServiceAccount运行prometheus server相关的Pod；

```
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
name: prometheus
rules:
- apiGroups: [""]
resources:
- nodes
- nodes/proxy
- services
- endpoints
- pods
verbs: ["get", "list", "watch"]
- apiGroups:
- extensions
resources:
- ingresses
verbs: ["get", "list", "watch"]
- nonResourceURLs: ["/metrics"]
verbs: ["get"]
```



```
---
apiVersion: v1
kind: ServiceAccount
metadata:
name: prometheus
namespace: prom
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
name: prometheus
roleRef:
apiGroup: rbac.authorization.k8s.io
kind: ClusterRole
name: prometheus
subjects:
- kind: ServiceAccount
name: prometheus
namespace: prom
```





##### Jenkins Master的权限需求

```
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
name: jenkins-master
namespace: jenkins
rules:
- apiGroups: [""]
resources: ["pods"]
verbs: ["create","delete","get","list","patch","update","watch"]
- apiGroups: [""]
resources: ["pods/exec"]
verbs: ["create","delete","get","list","patch","update","watch"]
- apiGroups: [""]
resources: ["pods/log"]
verbs: ["get","list","watch"]
- apiGroups: [""]
resources: ["events"]
verbs: ["watch"]
- apiGroups: [""]
resources: ["secrets"]
verbs: ["get"]
```



```
---
apiVersion: v1
kind: ServiceAccount
metadata:
name: jenkins-master
namespace: jenkins
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
name: jenkins-master
namespace: jenkins
roleRef:
kind: ClusterRole
name: jenkins-master
apiGroup: rbac.authorization.k8s.io
subjects:
- kind: ServiceAccount
name: jenkins-master
namespace: jenkins
```





#### 部署Kuboard

```bash
https://kuboard.cn/
#查看官方文档
https://kuboard.cn/install/v3/install.html
```



##### 使用 StorageClass 提供持久化

```bash
#获取部署 Kuboard 所需的 YAML 文件
curl -o kuboard-v3.yaml https://addons.kuboard.cn/kuboard/kuboard-v3-storage-class.yaml
修改部分选项


  Warning  FailedScheduling  2m32s (x3 over 2m36s)  default-scheduler  0/3 nodes are available: persistentvolumeclaim "kuboard-data-pvc" not found. preemption: 0/3 nodes are available: 3 Preemption is not helpful for scheduling.

官方有坑，pvc默认创建再deafut命名空间，而kuboard运行再 kuuboard 命名空间
```





## Kubernetes的网络解决方案

#### Kubernetes网络模型

Kubernetes集群上会存在三个分别用于节点、Pod和Service的网络

三个网络于集群节点上完成交汇

由节点内核中的路由模块，以及iptables/netfilter和ipvs等完成网络间的流量转发

#### Kubernetes的Pod网络

Kubernetes将Pod网络功能通过CNI委托给了外部的插件，该类插件主要负责解决如下4个问题 （目标地址不能nat转换）

同一Pod内容器间的通信（Container to Container）

Pod间的通信（Pod to Pod）同节点/跨节点

Service到Pod间的通信（Service to Pod）

集群外部与Service之间的通信（external to Service）



路由方式：每个节点都会获得一个Pod子网  判定Pod地址属于那个子网，子网对应Node节点

  通信网络：
          overlay：隧道网络，叠加网络
          underlay：承载网络，底层网络
          routing：路由网络
          ipvlan/macvlan：VLAN网络

#### CNI网络插件基础

CNI的全称为“容器网络接口”，它是容器引擎与遵循该规范网络插件的中间层，专用于为容器配置网络子系统

简单来说，目前的CNI规范主要由NetPlugin（网络插件）和IPAM两个插件API组成

网络插件也称Main插件，负责**创建/删除网络**以及**向网络添加/删除容器**

```
它专注于连通容器与容器之间以及容器与宿主机之间的通信，同容器相关网络设备通常都由该类插件所创建，例如
bridge、ipvlan、macvlan、loopback、ptp、veth以及vlan等虚拟设备；
```

iPAM的全称“IP Address Management”，该类插件负责**创建/删除地址池**以及**分配/回收容器的IP地址**

```
目前，该类型插件的实现主要有host-local和dhcp两个，前一个基于预置的地址范围进行地址分配，而后一个通过dhcp协议获取地址；
```

**把Pod接入Pod网络**

```bash
1.创建出Pod网络
2.创建Pod时，给Pod注入虚拟网络接口
3.给虚拟网络接口分配IP地址
4.将Pod的虚拟网络接口接入到Pod网络中
```



#### 配置容器网络接口的常用方法

不同的容器虚拟化网络解决方案中为Pod的网络名称空间创建虚拟接口设备的方式也会有所不同，目前，较为注流的实现方式有虚拟以太网设备（veth）、多路复用及硬件交换三种

```bash
veth设备：创建一个网桥，并为每个容器创建一对虚拟以太网接口（veth），一个接入容器内部，另一个留
置于根名称空间内添加为Linux内核桥接功能或OpenVSwitch（OVS）网桥的从设备

#注解
每创建一个Pod就给它创建一对虚拟网卡，一半接入到Pod中，一半接入到宿主机。我们可以再宿主机上创建一个虚拟交换机把另一半桥接到交换机上，此交换机有两重作用既可以当作二层设备，又可以当作宿主机的虚拟网卡。
给虚拟交换机配置上IP地址，就可以和Pod通信，把其他Pod桥接到交换机上他们也可以通过arp地址解析通信
#veth和虚拟交换机都是linux内核支持的参数
缺点本地通信是也要封装报文
```



```bash
多路复用：多路复用可以由一个中间网络设备组成，它暴露多个虚拟接口，使用数据包转发规则来控制每个
数据包转到的目标接口
MACVLAN技术为每个虚拟接口配置一个MAC地址并基于此地址完成二层报文收发，IPVLAN则是分配一个IP地址并
共享单个MAC并根据目标IP完成容器报文转发；

#注解
直接再宿主机网卡上虚拟出多个网络接口，把Pod桥接到宿主机网卡
```



```
硬件交换：现今市面上有相当数量的NIC都支持单根I/O虚拟化（SR-IOV），它是创建虚拟设备的一种实现
方式，每个虚拟设备自身表现为一个独立的PCI设备，并有着自己的VLAN及硬件强制关联的QoS；SR-IOV提
供了接近硬件级别的性能；  硬件支持
```

![image-20240407222750172](../images/image-20240407222750172.png)



#### Kubernetes的网络解决方案

**NetPlugin目前常用的实现方案有叠加网络（Overlay Network）和承载网络（Underlay Network）两类**

叠加网络借助于VXLAN、UDP、IPIP或GRE等隧道协议，通过隧道协议报文封装Pod间的通信报文（IP报文或以太网帧）来构建虚拟网络

承载网络通常使用direct routing（直接路由）技术在Pod的各子网间路由Pod的IP报文，或使用bridge、macvlan或ipvlan等技术直接将容器暴露至外部网络中

**叠加网络的底层网络也就是承载网络**

承载网络的解决方案也就是一类非借助于隧道协议而构建的容器通信网络

相较于承载网络，叠加网络由于存在额外的隧道报文封装，会存在一定程度的性能开销

但希望创建跨越多个L2或L3的逻辑网络子网时，只能借助于叠加封装协议实现

### Overlay网络模型

VXLAN（Virtual eXtensible Local Area Network，虚拟扩展局域网）目前最流行的叠加网络隧道协议之一也是由IETF定义的NVO3（Network Virtualization over Layer 3）标准技术之一采用L2 over L4（MAC-in-UDP）的报文封装模式，将二层报文用三层协议进行封装，可实现二层网络在三层范围内进行扩展



### Underlay网络模型

容器网络中的承载网络是指借助驱动程序将宿主机的底层网络接口直接暴露给容器使用的一种网络构建技术，较为常见的解决方案有macvlan、ipvlan和直接路由等

**MACVLAN**

```
MACVLAN支持在同一个以太网接口上虚拟出多个网络接口，每个虚拟接口都拥有惟一的MAC地址，并可按需配置IP地址
MACVLAN允许传输广播和多播流量，它要求物理接口工作于混杂模式与Bridge模式相比，MACVLAN不再依赖虚拟网桥、NAT和端口映射，它允许容器以虚拟接口方式直接连接至物理接口
```

![image-20240407224130516](../images/image-20240407224130516.png)

### Underlay网络模型（2）

**IPVLAN**

```bash
IPVLAN类似于MACVLAN，它同样创建新的虚拟网络接口并为每个接口分配惟一的IP地址，不同之处在于，
每个虚拟接口将共享使用物理接口的MAC地址，从而不再违反防止MAC欺骗的交换机的安全策略，且不要求在物理接口上启用混杂模式
#内部是工作再第三层 因为mac地址一样要通过ip地址区分
```

![image-20240407224600135](C:\Users\50569\Desktop\运维笔记运维笔记\笔记图片\image-20240407224600135.png)



### Underlay网络模型（3）

**Direct Routing（直接路由）**

放弃跨主机的容器在L2的连通性，而专注于通过路由协议解决它们在L3的通信的解决方案通常可简称为“直接路由”模型

跨主机的容器间通信，需要借助于主机上的路由表指示完成报文路由，因此每个主机的物理接口地址都有可能被引用为另一个主机路由报文时的“下一跳（nexthop）”，这就要求各主机的物理接口必须位于同一个L2网络中

```
veth虚拟一对网络接口，一半Pod，另一半宿主机用来连通Pod和宿主机的网络，并且要把网关指向宿主机（查路由表）
每一个主机分配的Pod子网是什么，每一个主机地址是什么，下一跳的映射关系
```

![image-20240407225734600](../images/image-20240407225734600.png)









```bash
#把pod接入网络
	veth pair： 
		在宿主机上创建虚拟交换机，该虚拟交换机也作为宿主机的接口使用；
生成一对虚拟网卡veth pair，一端再Pod中一端再宿主机，只要宿主机一端和pod中的ip再同一个网段他们就可以通信。但这样以来每创建一个Pod就要消耗两个IP，一个节点一共就254个地址消耗太大，为了解决这一问题

Flanne直接再宿主机生成一个虚拟交换机（CNI-0），把Pod网卡另一半直接桥接在CNI-0上，并且给CNI-0配置一个同网段地址，这个CNI-0是宿主机网卡，和Pod通信用CNI-0即可。同节点Pod在交换机内apr广播寻址就可以完成通信

Pod把网关指向CNI-0，如果访问的地址不再CNI-0上那么，因为他是宿主机网卡，就直接走宿主机路由报表
```

![image-20240408200138275](../images/image-20240408200138275.png)



![image-20240408200604288](../images/image-20240408200604288.png)



#### 网络插件对比

```
flannel: 隧道vxlan/host-Gw			NO	    	 不支持网络策略	api-server   跨界点加密
Calico:  隧道Vxlan/ipip/BGP Route     BGP分发路由   网络策略		   api-server	跨界点加密
Cllium：Vxlan / 路由ebpf			   BGP分发路由	 网络策略		  api-server   跨界点加密
```



#### 如何选择网络插件

通常来说，选择网络插件时应该通过底层系统环境限制、容器网络的功能需求和性能需求三个重要的评估标准来衡量插件的适用性

**底层系统环境限制**

```
 公有云环境多有专有的实现，例如Google GCE、Azure CNI、AWS VPC CNI和Aliyun Terway等，它们通常是
相应环境上较佳的选择
 虚拟化环境限制较多，除叠加网络模型别无选择，可用有Flannel vxlan、Calico ipip、Weave和Antrea等
 物理机环境几乎支持任何类型的网络插件，此时一般应该选择性能较好的的Calico BGP、Flannel host-gw或DAMM IPVLAN等
```

**容器网络功能需求**

```
 支持NetworkPolicy的解决方案以Calico、WeaveNet和Cilium为代表，而且后两个支持节点到节点间的通信加密
 而大量Pod需要与集群外部资源互联互通时应该选择承载网络模型一类的解决方案
```

**容器网络性能需求**

```
 Overlay网络中的协议报文有隧道开销，性能略差，而Underlay网络则几乎不存这方面的问题
 但Overlay或Underlay路由模型的网络插件支持较快的Pod创建速度，而Underlay模型中IPVLAN或MACVLAN模
式中较慢
```





## Flannel网络插件

### Flannel简介

由CoreOS研发，兼容CNI插件API，支持Kubernetes、OpenShift、Cloud Foundry、Mesos、Amazon ECS、Singularity和OpenSVC等平台

使用“虚拟网桥和veth设备”的方式为Pod创建虚拟网络接口，通过可配置的“后端”定义Pod间的通信网络，支持基于VXLAN和UDP的Overlay网络，以及基于三层路由的Underlay网络

```
虚拟网桥cni0
隧道接口通常为flannel.1
```

在IP地址分配方面，它将预留的一个专用网络（默认为10.244.0.0/16）切分成多个子网后作为每个节点的podCIDR，而后由节点以IPAM插件host-local进行地址分配，并将子网分配信息保存于etcd之中







IP是主机标识，但大部分通信时是进程和进程通信，传输层用端口号标识进程地址

Node1和Node2通信，假设他们中间隔着两个路由器，中间要经过两个路由器转发实现，意味着报文要先到达 route1 然后 route2  最后到达 Node2.。但报文的目标地址是Node2，怎么到达route1呢，在我们的宿主机上的路由表应该有到底该路由器的地址。

当报文从N1发出来，要封装 应用层  传输层  IP首部 ， 源/目标mac 但要到达node2，就要先到达route1，因此要

封装route 1的mac地址，route1收到看到mac地址是自己拆开一看，IP是Ndoe2又要查路由表，查到了到node2的rooute2 因此最外层的目标mac要换成route2的，源mac换成route1某个接口的mac地址，route2收到后看到mac地址是自己拆开报文一开ip是 node2，查路由查到了node2mac地址，因此把源地址换成自己的，目标mac换成node2。 最外层的mac地址会一直变

如何获得route1的 mac地址：本机记录了route路由地址，通过apr地址解析拿到routemac地址

mtu 1500

![image-20240408205458916](../images/image-20240408205458916.png)



Vxlan就是在L2的以太网帧外部通过UDP协议在封装一层宿主机的IP以太网帧，通过宿主机路由表发送报文。本质上就是overlay网络。通过抓包测试可以看到 Pod ip mac、node ip mac。我的网络插件还必须要互相学习路由，通过中央数据库或者BGP协议。 VTEP与宿主机的网络相连，会给NVE设备分配一个宿主机物理IP地址，flannel.1的vetp就是和宿主机同网段的，Vxlan的源地址就是本节点的VTEP，目标地址就是对方的VTEP。

##### Pod跨宿主机通信

```
Pod封装源Pod地址和目标Pod地址，先通过CNI-0 arp广播看看是否CNI-0上的设备，如果不是报文就会到达宿主机路由表，路由表明确记录了到达目标Pod地址该怎么走，如果10.0.0.100 就会交给 flannel.1设备接口 ，然后报文就到达该网络边缘设备，由flannel封装Vtep(Vxlan标头，UDP标头，外层ip mac)，再次查看路由报表到达Node2怎么走，然后就到达node2
```



![image-20240408214914704](../images/image-20240408214914704.png)



![image-20240408215317413](../images/image-20240408215317413.png)

隧道: 要想到达目标表pod 先到达flannel.1

路由：到达Pod 直接指向对端node节点

```bash
 pod子网        node地址
10.244.1.0  -  10.0.0.200    eth1
10.244.10.0 -  10.0.0.202    eth1

#必须把到达Pod的目标地址指向对端节点的地址，中间不能跨3层网络，因为中间的路由器并没有记录，那些pod子网对应的node节点地址

#路由隧道组合使用 混合模式
```

#### flanneld 

Flannel在每个主机上运行一个名为flanneld的二进制代理程序

flanneld该程序负责从预留的网络中按照指定或默认的掩码长度为当前节点申请分配一个子网，并将网络配置、已分配的子网和辅助数据（例如主机的公网IP等）存储于Kubernetes API或etcd之中，并且也会读取其他flanneld写入的信息，在本地生成隧道路由，封装对端vtep 这个就在etcd中，由它节点上的flanneld上传至etcd。

Flannel使用称为后端（backend）的容器网络机制转发跨节点的Pod报文，它目前支持的主流backend如下

```
vxlan
使用Linux内核中的vxlan模块封装隧道报文，以叠加网络模型支持跨节点的Pod间互联互通
额外支持直接路由（Direct Routing）模式，该模式下位于同二层网络内的节点之上的Pod间通信可通过路由模式直接发送，而跨网络的节点之上的Pod间通信仍要使用VXLAN隧道协议转发
vxlan后端模式中，flanneld监听于8472/UDP发送封装的数据包；

host-gw
类似于VXLAN中的直接路由模式，但不支持跨网络的节点，因此这种方式强制要求各节点本身必须在同一个二层w络中，不太适用于较大的网络规模，有着较好的转发性能，且易于设定，推荐对报文转发性能要求较高的场景使用

```

![image-20240408224549931](../images/image-20240408224549931.png)

![image-20240408225414755](../images/image-20240408225414755.png)





**抓包分析**

我们在node1上的Pod 请求node2上的Pod 80

![image-20240408223233189](../images/image-20240408223233189.png)





#### Vxlan和host-gw 路由表对比

![image-20240408225247125](../images/image-20240408225247125.png)







```bash
#修改flannle模式
root@k8s-master01:~# kubectl get configmap -n kube-flannel
NAME               DATA   AGE
kube-flannel-cfg   2      10d
kube-root-ca.crt   1      10d
root@k8s-master01:~# kubectl get configmap kube-flannel-cfg -o yaml -n kube-flannel > kube-flannel-cfg.yaml
apiVersion: v1
data:
  cni-conf.json: |
    {
      "name": "cbr0",
      "cniVersion": "0.3.1",
      "plugins": [
        {
          "type": "flannel",
          "delegate": {
            "hairpinMode": true,
            "isDefaultGateway": true
          }
        },
        {
          "type": "portmap",
          "capabilities": {
            "portMappings": true
          }
        }
      ]
    }
  net-conf.json: |
    {
      "Network": "10.244.0.0/16",
      "Backend": {
        "Type": "vxlan"  #修改host-gw
      }
    }
kind: ConfigMap
metadata:
  labels:
    app: flannel
    k8s-app: flannel
    tier: node
  name: kube-flannel-cfg
  namespace: kube-flannel
  resourceVersion: "275"
  uid: 314107b1-882c-44e2-a591-ef911b4b9f8e
```





## Calico网络插件

ProjectCalico

它把每个节点都当作虚拟路由器（vRouter），把每个节点上的Pod都当作是“节点路由器”后的一个终端设备并为其分配一个IP地址

各节点路由器通过BGP（Border Gateway Protocol）协议学习生成路由规则从而实现不同节点上Pod间的互联互通



把每个主机当作一个末端网络，Calico连接内核作虚拟出一个路由器，并且把自己所在的网络和后端的终端子网通过BGP协议通告给其他路由器，而且还会学习其他人通告的网络信息

```
Calico在每一个计算节点利用Linux内核实现了一个高效的vRouter（虚拟路由器）进行报文转发，而每个vRouter通过BGP协议负责把自身所属的节点上运行的Pod资源的IP地址信息，基于节点的agent程序（Felix）直接由vRouter生成路由规则向整个Calico网络内传播
```

![image-20240409151802361](../images/image-20240409151802361.png)

### Calico简介

**Calico的工作机制**

Calico把Kubernetes集群环境中的每个节点上的Pod所组成的网络视为一个自治系统，各节点也就是各自治系统的边界网关，它们彼此间通过BGP协议交换路由信息生成路由规则

考虑到并非所有网络都能支持BGP，以及BGP路由模型要求所有节点必须要位于同一个二层网络，Calico还支持基于IPIP和VXLAN的叠加网络模型

类似于Flannel在VXLAN后端中启用DirectRouting时的网络模型，Calico也支持混合使用路由和叠加网络模型，BGP路由模型用于二层网络的高性能通信，IPIP或VXLAN用于跨子网的节点间（Cross-Subnet）报文转发

```
Vxlan开销比较大:[(传输层，IP，mac帧)传输层，IP，mac帧 ]
IP in IP :[(传输层，IP)，IP，mac帧 ]
```



### Calico系统组件

概括来说，Calico主要由Felix、Orchestrator Plugin、etcd、BIRD和BGP Router Reflector等组件组成,

Felix：Calico Agent,每个节点都有，主要负责维护虚拟接口设备和路由信息/学习路由生成路由表/并根据网路策略生成iptables/ nfstables规则

BIRD：负责分发路由信息的BGP客户端

etcd：持久存储Calico数据的存储管理系统

Orchestrator Plugin：编排系统（例如Kubernetes、OpenStack等）用于将Calico整合进行系统中的插件，例如Kubernetes的CNI

BGP Route Reflector：BGP路由反射器，可选组件，用于较大规模的网络场景

```
每个节点都要去连接其他节点通告路由和学习路由，如果有100个节点，那么我们每个节点都将开启99个连接，非常消耗性能。
这个时候我们就需要BGP路由反射器来解决此问题，所有节点都连接BGP路由反射器，BGP路由反射器负责学习其他节点的路由并通告给其他节点。但一个路由反射器容易单点，我们可以部署两个路由反射器，每个节点只需要维持两个连接即可。
```



![image-20240409153148327](../images/image-20240409153148327.png)![image-20240409153708632](../images/image-20240409153708632.png)

#### Calico程序组件及架构

![image-20240409153133683](../images/image-20240409153133683.png)

用户提交网络策略，由calico-controlle监视到，并根据网络策略中的定义，控制对应节点上的Felix生成 iptables/nftables规则



#### Calico程序组件及架构（2）

calico-node

运行于集群中的每个节点，负责路由编程（Felix）和路由分发（BIRD）

Felix：负责生成路由规则和iptables规则，前者用于完成Pod报文路由，后者用于支撑NetworkPolicy

BIRD：读取并分发由同一节点上的Felix生成的路由规则，支持多种分发拓扑

calico-kube-controller

负责监视Kubernetes对象中（包括NetworkPolicy、Pod、Namespace、ServiceAccount和Node等）会影响到路由的相关变更

将变更带来的影响生成Calico配置，并保存于

Calico Datastore中将变更带来的影响生成Calico配置，并保存于Calico Datastore中

![image-20240409154543512](../images/image-20240409154543512.png)

、

Typha

各calico-node实例同Calico Datastore通信的中间层，由其负责将Calico Datastore中生成的更改信息分发给各calico-node，以减轻50个节点以上规模集群中的Calico Datastore的负载

有缓存功能，且能够通过删除重复事件，降低系统负载

**Calico Datastore**

通用术语，是指存储的Calico配置、路由、策略及其它信息，它们通常表现为Calico CRD资源对象

支持的CRD包括BGPConfiguration、BGPFilter、BGPPeer、BlockAffinity、CalicoNodeStatus、ClusterInformation、FelixConfiguration、GlobalNetworkPolicy、GlobalNetworkSet、HostEndpoint、IPAMBlock、IPAMConfig、IPAMHandle、IPPool、IPReservation、NetworkPolicy、NetworkSet和KubeControllersConfiguration等

```
BGPConfiguration：全局BGP配置，用于设定AS（自治系统）编号、node mesh，以及用于通告ClusterIP的设置
FelixConfiguration：Felix相关的低级别配置，包括iptables、MTU和路由协议等
GlobalNetworkPolicy：全局网络策略，生效于整个集群级别；
GlobalNetworkSet：全局网络集，是指可由GlobalNetworkPolicy引用的外部网络IP列表或CIDR列表；
IPPool：IP地址池及相关选项，包括要使用的路由协议（IPIP、VXLAN或Native）；一个集群支持使用多个Pool；
```

#### Calico数据存储模式：Kubernetes

![image-20240409160022515](../images/image-20240409160022515.png)



### Calico下的Pod网络接口

Calico网络插件如何为Pod配置网络接口

为每个Pod创建一组veth pair，一端注入Pod网络名称空间，另一端驻留在宿主机上

Pod内的一端，通常名称格式为“etho@ifN”，其中的n是驻留在宿主机上的另一端的ip link编号

驻留宿主机的一端，名称格式为“caliXXXXXXXXXXX@ifN”，其中的11位X是经由函数计算生成，而N则是注入Pod网络名称空间中的对端的ip link编号

 Pod网络名称空间中，会生成独特的默认路由，将网关指向169.254.1.1

![image-20240409160236452](../images/image-20240409160236452.png)

宿主机为每个cali接口都开启了ARP Proxy功能，从而让宿主机扮演网关设备，并以自己的MAC地址代为应答对端Pod中发来的所有ARP请求

ARP Proxy的关键配置：/proc/sys/net/ipv4/conf/DEV/proxy_arp

![image-20240409160317774](../images/image-20240409160317774.png)

![image-20240409160331930](../images/image-20240409160331930.png)

```bash
通信的大概逻辑：
Calico为每个Pod创建一组veth pair，一端注入Pod网络名称空间，另一端驻留在宿主机上，在Pod网络名称空间中把网关指向在宿主机一端的，并且给宿主机一端接口开启ARP Proxy，宿主机就会把自己的mac地址响应给Pod，报文就到达了宿主机网卡，查看宿主机路由表来决定自己到哪里
#同一主机Pod通信 查宿主机路由表解决
```

要走这个网关出去169.254.1.1 封装报文，但是这个地址并不存在，解析不到mac地址就无法通信，所以要在宿主机一端的cali接口上配置 APR Proxy，把自己的mac地址响应给报文，从而封装报文到达宿主机查路由表



### 路由模式

Calico支持多种路由模式

 Native：原生路由，无隧道封装

 IP-in-IP：IPIP隧道模式，开销较小的隧道协议

 VXLAN：VXLAN隧道模式

![image-20240410090704185](../images/image-20240410090704185.png)

### 路由模式（2）

![image-20240410090738462](../images/image-20240410090738462.png)

### 路由模式（3）

![image-20240410091859467](../images/image-20240410091859467.png)



安装文档

```
https://docs.tigera.io/calico/latest/getting-started/kubernetes/self-managed-onprem/onpremises
```

### 部署前关注的配置

![image-20240410095736147](../images/image-20240410095736147.png)

```
Cross-Subent 混合模式，如果跨子网就使用隧道，反之直接路由

使用服务器的块网卡的IP 通告BGP协议  默认自动识别
IPIP 和Vxlan的 1450 1480
```

![image-20240410095858162](../images/image-20240410095858162.png)

**安装Calico ctl**

```bash
https://docs.tigera.io/calico/latest/operations/calicoctl/install
#下载
curl -L https://github.com/projectcalico/calico/releases/download/v3.27.3/calicoctl-linux-amd64 -o calicoctl
#添加权限
chmod +x ./calicoctl
#移动
mv calicoctl /usr/local/bin/


calicoctl get ippool  
calicoctl get ippool  <ippool name> -o yamml
calicoctl get node
calicoctl status 
```



### 配置Calico

![image-20240410101015604](../images/image-20240410101015604.png)

默认注释而且需要添加自定义子网掩码

```yaml
#注意缩进
			- name: CALICO_IPV4POOL_CIDR
               value: "192.168.0.0/16"
            - name: CALICO_IPV4POOL_BLOCK_SIZE
               value: "24"
```

![image-20240410101424271](../images/image-20240410101424271.png)



#### Calico CRD

IPPool CRD

```
Calico可用于为Pod配置IP地址的地址池
配置路由模式
支持在同一集群上配置使用多个地址池
可通过annotation配置默认的ippool
可通过nodeSelector限定其适用到的目标节点
需要预留小段地址时，可通过IPReservation CRD进行定义
```

注解：

```yaml
apiVersion: crd.projectcalico.org/v1
kind: IPPool
metadata:
name: …
spec:
  allowedUses <[]string> # 支持的使用场景，可选项有Tunnel和Workload
  blockSize <integer> # 使用的子网掩码长度，IPv4默认为26，IPv6默认为122
  cidr <string> # 使用的CIDR
  ipipMode <string> # IPIP的启用模式，默认为Never
  natOutgoing <boolean> # 目标地址不在本地CIDR范围内时，是否启用SNAT
  vxlanMode <string> # VXLAN的启用模式，默认为Never
  nodeSelector <string> # 地址池适用到的目标节点，此为节点的标签选择器
  disableBGPExport <boolean> # 是否禁止BGP传播本地址池内的相关路由
  disabled <boolean> # 是否禁用本地址池
  
#全设置为Never表示纯BGP通信，但中间不能有路由器
#如果在kubecl/calico -f 文件中写 CrossSubnet，写在Vxlan就和vxlan混合，写在ipip就和ipip混合
#如果是下载的官方部署文件写，Cross-Subnet 
```

![image-20240410111723085](../images/image-20240410111723085.png)



#### BGP Peering

Calico在各节点间基于BGP传播路由信息

BGP是路由器间交换路由信息的标准路由协议

```
iBGP：Interior Border Gateway Protocol，负责在同一AS内的BGP路由器间传播路由，它通过递归方式进行路径选择
eBGP： Exterior Border Gateway Protocol，用于在不同AS间传播BGP路由，它基于hop-by-hop机制进行路径选择
```

 每个路由器都存在一到多个BGP Peer（对等端）

 Calico Node能够基于BGP协议将物理路由器作为BGP Peer

**BGP的常用拓扑**

Full-mesh

启用BGP时，Calico默认在所有节点间建立一个AS（64512），并基于iBGP为它们创建full-mesh连接

该模式较适用于集群规模较小（100个节点以内）的场景

Route Reflectors

```
在大规模的iBGP场景中， BGP route reflectors能显著降低每个节点需要维护的BGP Peer的数量

可选择几个节点作为BGP RR，并在这些RR之间建立full mesh拓扑

其它节点只需要同这些RR之间建立Peer连接即可
```



![image-20240410141734395](../images/image-20240410141734395.png)





![image-20240410143233759](../images/image-20240410143233759.png)

```
peerSelector： 仅和有某某标签的节点建立BGP peer #找一个节点作为BGP反射器 给他打上这个标签
```

![image-20240410144225796](../images/image-20240410144225796.png)





## Network Policy

标准的API资源类型

由网络插件负责转换为节点上的iptables filter规则，以定义Pod间的通信许可

主要针对TCP、UDP和SCTP协议，实现在IP地址或Port层面进行流量控制

**Network Policy的功能**

描述对端实体的方法有如下几种

针对一组Pod，定义其同对端实体通信时，在入向（Ingress）或/和 出向（Egress）流量上的控制规则

```
一组Pod对象，通常基于标签选择器定义筛选条件
单个或一组名称空间
IP地址块（但Pod同其所在的节点间的通信不受限制）
```



```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ...
  namespace: ...
spec:
  egress: # 出向流量控制规则，默认为开放
    to: # 出向流量控制规则，默认为开放；流量目标的表示方式与ingress.from相同；
    - ports: # 出向流量的目标端口；流量目标端口的表示方式与ingress.ports相同
  ingress: # 入向流量控制规则，默认为开放
    from: # 入向流量源，多个列表项之间为“或”逻辑；未给定任何值或未定义该字段，将匹配所有
      ipBlock: # 源IP地址段，通常是网络地址；不支持同namespaceSelector或podSelector同时使用；
        cidr: # CIDR格式的网络地址
        except: # 要排除的地址列表，可以是CIDR格式的子网地址；
      namespaceSelector: # namespace标签选择器，用于表示源自匹配到的namespace内的所有流量
      podSelector: # pod标签选择器，用于表示源自匹配到的Pod上的所有流量；可以同nameSelector
        # 同时使用，用于匹配选定namespace中选定的pod；
        ports: # 入向流量的目标端口，即流量源要访问的目标端口，生效机制同from；
          port: # 端口，同endPort字段同时使用时，表示端口范围的起始端口号
          endPoint: # 端口号，同port字段同时使用时，表示端口范围的结束端口号
          protocol: # 协议，仅支持TCP、UDP和SCTP，默认为TCP；
  podSelector: # Pod标签选择器，用于选定流量规则适用的对象，必选字段
  policyTypes: # 规则类型，支持Ingress、Egress，默认在两个方向上同时生效
```



### Cilium网络插件



BPF  运行于内核空间，负责在寄存器编译运行从用户空间注入到内核空间的代码  



内核空间和用户空间时隔离的，我们必须通过系统调用通讯，通过系统调用发送给内核 增强内核功能

**什么是EBPF：**

Linux内核中的一个功能，用于在内核中执行安全的、高性能的、可编程的网络和系统事件处理。eBPF允许用户编写并在内核中运行小型程序，这些程序可以拦截系统调用、监控网络流量、执行数据包过滤和修改等操作，而无需修改内核代码或重新编译内核模块。



**XDP**：

内核中基于eBPF提供的高性能数据路径，支持绕过内核的网络栈直接在网络驱动程序的级别处理数据包
无须处理上下文切换、中断等，可大大减少内核开销



原理：

用户使用Cilium定义网络和安全策略，这些策略描述了应用程序之间的通信规则、网络拓扑结构以及安全要求。Cilium根据用户定义的策略生成eBPF（Extended Berkeley Packet Filter）代码。这些代码包含了网络过滤、安全检查和其他用户定义的功能。生成的eBPF代码需要经过编译器编译成内核可加载模块。编译器通常是LLVM编译器集合中的Clang，用于将eBPF代码编译成BPF字节码。编译成EBPF程序并加载到内核中，启动



Cilium：

不许要kube-proxy

容器网络解决方案和负载均衡器CNI, Kubernetes Servicel,  Multi-Cluster
网络安全
Network Policy, Identity-based,Encryption
可观测性
Metrics, Flow Visibility, ServiceDependency

![image-20240418150859598](../笔记图片/image-20240418150859598.png)

![image-20240418150923199](../笔记图片/image-20240418150923199.png)



不论是iptables和ipvs都有很多表，都是线性列表，大规模场景下性能瓶颈

![image-20240418151236708](../笔记图片/image-20240418151236708.png)





#### 对比传统网络插件

![image-20240418151724100](../笔记图片/image-20240418151724100.png)



![image-20240418155030265](../笔记图片/image-20240418155030265.png)





```
Cilium部署
只作为CNI网络插件，Service的功能仍由kube-proxy实现;
作为CNI网络插件，同时也能够取代kube-proxy部分功能，余下功能部分仍由kube-proxy实现;
完全取代kube-proxy

# 部署Kubernetes集群
kubeadm init --control-plane-endpoint kubeapi.magedu.com
--kubernetes-version=v1.29.2
--pod-network-cidr=10.244.0.0/16
--service-cidr=10.96.0.0/12
--upload-certs
--image-repository=registry.magedu.com/google containers
--skip-phases=addon/kube-proxy
```



![image-20240418155459013](../笔记图片/image-20240418155459013.png)





虚拟设备

![image-20240418161614833](../笔记图片/image-20240418161614833.png)



会在宿主机创建一对网卡，cilium_host和Cilium_net

```

```

![image-20240418173214428](../笔记图片/image-20240418173214428.png)



#### 启用hubble

![image-20240418175737694](../笔记图片/image-20240418175737694.png)



#### 启用ciliumIngress Controlle!

![image-20240418180325323](../笔记图片/image-20240418180325323.png)



![image-20240418180354484](../笔记图片/image-20240418180354484.png)



![image-20240418181042337](../笔记图片/image-20240418181042337.png)





![image-20240418181324372](../笔记图片/image-20240418181324372.png)





![image-20240430182407435](../笔记图片/image-20240430182407435.png)

![image-20240418195337689](../笔记图片/image-20240418195337689.png)





![image-20240418195655738](../笔记图片/image-20240418195655738.png)





![image-20240418195948898](../笔记图片/image-20240418195948898.png)

![image-20240418200017580](../笔记图片/image-20240418200017580.png)

![image-20240418200152022](../笔记图片/image-20240418200152022.png)
