# kubenetes

## 组件

### mast

#### API servcie：

所有有关集群的请求到这里后先确认信息（3A）鉴权，然后写入ETCD里

Kubernetes API Server作为集群的核⼼，负责集群各功能模块之间的通信。集群内的各个功能模块通过APIServer将信息存⼊etcd，当需要获取和操作这些数据时，则通过API Server提供的REST接⼝（⽤GET、LIST或WATCH⽅法）来实现，从⽽实现各模块之间的信息交互。

- kubelet进程与API Server的交互：每个Node上的kubelet每隔⼀个时间周期，就会调⽤⼀次API Server的REST接⼝报告⾃身状态，API Server在接收到这些信息后，会将节点状态信息更新到etcd中。
- kube-controller-manager进程与API Server的交互：kube-controller-manager中的Node Controller模块通过API Server提供的Watch接⼝实时监控Node的信息，并做相应处理。
- kube-scheduler进程与API Server的交互：Scheduler通过API Server的Watch接⼝监听到新建Pod副本的信息后，会检索所有符合该Pod要求的Node列表，开始执⾏Pod调度逻辑，在调度成功后将Pod绑定到⽬标节点上。

#### controller-manager：

负责集群中各样的控制器

- 节点控制器：管理节点的生命周期，包括创建、删除和更新节点。

- 副本控制器：确保指定数量的 Pod 副本在集群中运行。

- 端点控制器：管理端点，这是服务和 Pod 之间的连接点。

- 服务控制器：管理服务，这是集群中抽象的 API 对象，为一组 Pod 提供网络访问。

- 令牌控制器：管理服务帐户令牌，这些令牌用于 Pod 与 Kubernetes API 服务器进行身份验证

#### Scheduleer：

watch 机制，有变动后选择最优的NODE节点进行调度

Kubernetes Scheduler是负责Pod调度的重要功能模块，Kubernetes Scheduler在整个系统中承担了“承上启下”的重要功能，“承上”是指它负责接收Controller Manager创建的新Pod，为其调度⾄⽬标Node；“启下”是指调度完成后，⽬标Node上的kubelet服务进程接管后继⼯作，负责Pod接下来⽣命周期。

Kubernetes Scheduler的作⽤是将待调度的Pod（API新创建的Pod、Controller Manager为补⾜副本⽽创建的Pod等）按照特定的调度算法和调度策略绑定（Binding）到集群中某个合适的Node上，并将绑定信息写⼊etcd中。

在整个调度过程中涉及三个对象，分别是待调度Pod列表、可⽤Node列表，以及调度算法和策略。

Kubernetes Scheduler通过调度算法调度为待调度Pod列表中的每个Pod从Node列表中选择⼀个最适合的Node来实现Pod的调度。随后，⽬标节点上的kubelet通过API Server监听到Kubernetes Scheduler产⽣的Pod绑定事件，然后获取对应的Pod清单，下载Image镜像并启动容器。

##### 调度策略：

- 预选（Predicates）：输⼊是所有节点，输出是满⾜预选条件的节点。kube-scheduler根据预选策略过滤掉不满⾜策略的Nodes。如果某节点的资源不⾜或者不满⾜预选策略的条件则⽆法通过预选。如“Node的label必须与Pod的Selector⼀致”。
- 优选（Priorities）：输⼊是预选阶段筛选出的节点，优选会根据优先策略为通过预选的Nodes进⾏打分排名，选择得分最⾼的Node。例如，资源越富裕、负载越⼩的Node可能具有越⾼的排名。

##### 标签与标签选择器的作⽤

标签：是当相同类型的资源对象越来越多的时候，为了更好的管理，可以按照标签将其分为⼀个组，为的是提升资源对象的管理效率。

标签选择器：就是标签的查询过滤条件。⽬前API⽀持两种标签选择器：

- 基于等值关系的，如：“=”、“”“==”、“！=”（注：“==”也是等于的意思，yaml⽂件中的matchLabels字段）；
- 基于集合的，如：in、notin、exists（yaml⽂件中的matchExpressions字段）；

注：in:在这个集合中；notin：不在这个集合中；exists：要么全在（exists）这个集合中，要么都不在（notexists）；

使⽤标签选择器的操作逻辑：

- 在使⽤基于集合的标签选择器同时指定多个选择器之间的逻辑关系为“与”操作（⽐如：- {key:name,operator: In,values: [zhangsan,lisi]} ，那么只要拥有这两个值的资源，都会被选中）；
- 使⽤空值的标签选择器，意味着每个资源对象都被选中（如：标签选择器的键是“A”，两个资源对象同时拥有A这个键，但是值不⼀样，这种情况下，如果使⽤空值的标签选择器，那么将同时选中这两个资源对象）
- 空的标签选择器（注意不是上⾯说的空值，⽽是空的，都没有定义键的名称），将⽆法选择出任何资源；

在基于集合的选择器中，使⽤“In”或者“Notin”操作时，其values可以为空，但是如果为空，这个标签选择器，就没有任何意义了。

```sh
selector:
 matchLabels: #基于等值
 app: nginx
 matchExpressions: #基于集合
 - {key: name,operator: In,values: [zhangsan,lisi]} #key、operator、values这三个字段是固定的
 - {key: age,operator: Exists,values:} #如果指定为exists，那么values的值⼀定要为空
```

##### 常⽤的标签分类有哪些？ 必会

标签分类是可以⾃定义的，但是为了能使他⼈可以达到⼀⽬了然的效果，⼀般会使⽤以下⼀些分类：

- 版本类标签（release）：stable（稳定版）、canary（⾦丝雀版本，可以将其称之为测试版中的测试版）、beta（测试版）；
- 环境类标签（environment）：dev（开发）、qa（测试）、production（⽣产）、op（运维）；
- 应⽤类（app）：ui、as、pc、sc；
- 架构类（tier）：frontend（前端）、backend（后端）、cache（缓存）；
- 分区标签（partition）：customerA（客户A）、customerB（客户B）；
- 品控级别（Track）：daily（每天）、weekly（每周）。

#### 种查看标签的⽅式

```sh
[root@master ~]# kubectl get pod --show-labels #查看pod，并且显示标签内容
[root@master ~]# kubectl get pod -L env,tier #显示资源对象标签的值
[root@master ~]# kubectl get pod -l env,tier #只显示符合键值资源对象的pod，⽽“-L”是显示所有的pod
```

#### 添加、修改、删除标签的命令

```sh
#对pod标签的操作
[root@master ~]# kubectl label pod label-pod abc=123 #给名为label-pod的pod添加标签
[root@master ~]# kubectl label pod label-pod abc=456 --overwrite #修改名为labelpod的标签
[root@master ~]# kubectl label pod label-pod abc- #删除名为label-pod的标签
[root@master ~]# kubectl get pod --show-labels#对node节点的标签操作
[root@master ~]# kubectl label nodes node01 disk=ssd #给节点node01添加disk标签
[root@master ~]# kubectl label nodes node01 disk=sss –overwrite #修改节点node01的标签
[root@master ~]# kubectl label nodes node01 disk- #删除节点node01的disk标签
```



### node

在Kubernetes集群中，在每个Node（⼜称Worker）上都会启动⼀个kubelet服务进程。该进程⽤于处理Master下发到本节点的任务，管理Pod及Pod中的容器。

kubelet

每个kubelet进程都会在API Server上注册节点⾃身的信息，定期向Master汇报节点资源的使⽤情况，并通过cAdvisor监控容器和节点资源。

​	CRI :containerd\dockerd

​	CNI:flannel\calico\cilium

​	CSI:????

kube-proxy

​	根据APIserver指定对应的IPVS规则

iptables与IPVS都是基于Netfilter实现的，但因为定位不同，⼆者有着本质的差别：iptables是为防⽕墙⽽设计的；IPVS则专⻔⽤于⾼性能负载均衡，并使⽤更⾼效的数据结构（Hash表），允许⼏乎⽆限的规模扩张。

与iptables相⽐，IPVS拥有以下明显优势：

- 为⼤型集群提供了更好的可扩展性和性能；
- ⽀持⽐iptables更复杂的复制均衡算法（最⼩负载、最少连接、加权等）；
- ⽀持服务器健康检查和连接重试等功能；
- 可以动态修改ipset的集合，即使iptables的规则正在使⽤这个集合。

### 其他

Dasboard、coreDNS、Metrics、Ingress、Prometheus Stack、EFK



yaml格式

```
版本
Kind：Pod、Server
```



## 控制

### 节点控制器

deploymentset  无序数量（代替了RC、RS，）

statefulset 有序（redis、ES）

DaemonSet 编排系统应用的：每个节点都部署的应用，exporter\fluentbit

job、cornjob:一次性的（清理大量国企资源、清除临时文件）或者周期性的（发送集群报告、夜间批量作业（备份、处理以前的日志、））

| 特性         | DeploymentSet    | ReplicaController (RC) | ReplicaSet (RS) |
| ------------ | ---------------- | ---------------------- | --------------- |
| 引入版本     | Kubernetes 1.22+ | Kubernetes 1.0+        | Kubernetes 1.2+ |
| 推荐使用     | 是               | 否                     | 否              |
| 滚动更新     | 支持             | 支持                   | 支持            |
| 多版本部署   | 支持             | 否                     | 否              |
| 蓝绿部署     | 支持             | 否                     | 否              |
| 升级策略     | 支持多种策略     | 只支持滚动更新         | 支持多种策略    |
| Pod 管理策略 | 支持多种策略     | 只支持删除并重新创建   | 支持多种策略    |
| 历史记录管理 | 支持             | 否                     | 否              |

#### deployment

##### 升级过程

maxSurge ： 此参数控制滚动更新过程，副本总数超过预期pod数量的上限。可以是百分⽐，也可以是具体的值。默认为1。

maxUnavailable ：此参数控制滚动更新过程中，不可⽤的Pod的数量。

- 初始创建Deployment时，系统创建了⼀个ReplicaSet，并按⽤户的需求创建了对应数量的Pod副本。

- 当更新Deployment时，系统创建了⼀个新的ReplicaSet，并将其副本数量扩展到1，然后将旧ReplicaSet缩减为2。
- 之后，系统继续按照相同的更新策略对新旧两个ReplicaSet进⾏逐个调整。
- 最后，新的ReplicaSet运⾏了对应个新版本Pod副本，旧的ReplicaSet副本数量则缩减为0。

##### 滚动升级策略

在Deployment的定义中，可以通过spec.strategy指定Pod更新的策略，⽬前⽀持两种策略：Recreate（重建）和RollingUpdate（滚动更新），默认值为RollingUpdate。

Recreate：设置spec.strategy.type=Recreate，表示Deployment在更新Pod时，会先杀掉所有正在运⾏的Pod，然后创建新的Pod。

RollingUpdate：设置spec.strategy.type=RollingUpdate，表示Deployment会以滚动更新的⽅式来逐个更新Pod。同时，可以通过设置spec.strategy.rollingUpdate下的两个参数（maxUnavailable和maxSurge）来控制滚动更新的过程。



##### Pod调度⽅式：

- Deployment或RC：该调度策略主要功能就是⾃动部署⼀个容器应⽤的多份副本，以及持续监控副本的数量，在集群内始终维持⽤户指定的副本数量。
- NodeSelector：定向调度，当需要⼿动指定将Pod调度到特定Node上，可以通过Node的标签（Label）和Pod的nodeSelector属性相匹配。

##### NodeAffinity亲和性调度：

亲和性调度机制极⼤的扩展了Pod的调度能⼒，⽬前有两种节点亲和⼒表达：

- requiredDuringSchedulingIgnoredDuringExecution：硬规则，必须满⾜指定的规则，调度器才可以调度Pod⾄Node上（类似nodeSelector，语法不同）。
- preferredDuringSchedulingIgnoredDuringExecution：软规则，优先调度⾄满⾜的Node的节点，但不强求，多个优先级规则还可以设置权重值。

##### Taints和Tolerations（污点和容忍）：

- Taint：使Node拒绝特定Pod运⾏；
- Toleration：为Pod的属性，表示Pod能容忍（运⾏）标注了Taint的Node。



##### RC、RS：都是副本控制器，RS是RC的升级版

- 滚动更新：ReplicaSet 允许您以受控和渐进的方式更新 Pod 镜像或配置。

- Pod 模板：ReplicaSet 使用 Pod 模板来定义要创建的 Pod 的规范。这提供了更大的灵活性，因为您可以使用标签选择器和 Pod 模板来更精确地指定要管理的 Pod。

- pod 管理策略：ReplicaSet 支持多种 pod 管理策略，例如OnDelete和Recreate。

### DaemonSet

DaemonSet这种资源对象会在每个k8s集群中的节点上运⾏，并且每个节点只能运⾏⼀个pod，这是它和deployment资源对象的最⼤也是唯⼀的区别。所以，在其yaml⽂件中，不⽀持定义replicas，除此之外，与Deployment、RS等资源对象的写法相同。

它的⼀般使⽤场景如下：

- 在去做每个节点的⽇志收集⼯作；
- 监控每个节点的的运⾏状态；

### pod

#### 可能会有的状态

Pending：Pod 已创建，但尚未启动任何容器。这可能是由于正在拉取镜像或正在创建存储卷。

Running：Pod 中的所有容器都已启动并正在运行。

Succeeded：Pod 中的所有容器都已成功终止

Failed：Pod 中至少有一个容器以非零退出代码终止。

Unknown：Kubernetes 无法确定 Pod 的状态。这可能是由于与 Pod 节点通信出现问题。

Terminated：Pod 已被终止，但其容器仍在运行。这可能是由于 preStop 挂钩或正在进行的优雅终止过程。

Evicted：Pod 已被从节点驱逐。这可能是由于节点故障或资源不足。

#### Pod创建流程 必会

- 客户端提交Pod的配置信息（可以是yaml⽂件定义好的信息）到kube-apiserver；
- Apiserver收到指令后，通知给controller-manager创建⼀个资源对象；
- Controller-manager通过api-server将pod的配置信息存储到ETCD数据中⼼中；
- Kube-scheduler检测到pod信息会开始调度预选，会先过滤掉不符合Pod资源配置要求的节点，然后开始调度调优，主要是挑选出更适合运⾏pod的节点，然后将pod的资源配置单发送到node节点上的kubelet组件上。
- Kubelet根据scheduler发来的资源配置单运⾏pod，运⾏成功后，将pod的运⾏信息返回给scheduler，scheduler将返回的pod运⾏状况的信息存储到etcd数据中⼼。

#### 删除⼀个Pod会发⽣什么事情？ 必会

答：Kube-apiserver会接受到⽤户的删除指令，默认有30秒时间等待优雅退出，超过30秒会被标记为死亡状态，此时Pod的状态Terminating，kubelet看到pod标记为Terminating就开始了关闭Pod的⼯作；

关闭流程如下：

- pod从service的endpoint列表中被移除；
- 如果该pod定义了⼀个停⽌前的钩⼦，其会在pod内部被调⽤，停⽌钩⼦⼀般定义了如何优雅的结束进程；
- 进程被发送TERM信号（kill -14）
- 当超过优雅退出的时间后，Pod中的所有进程都会被发送SIGKILL信号（kill -9）。



### 镜像拉去策略

IfNotPresent

Always

never



### Pod重启策略

Always

OnFailure

同时Pod的重启策略与控制⽅式关联，当前可⽤于管理Pod的控制器包括ReplicationController、Job、DaemonSet及直接管理kubelet管理（静态Pod）。

不同控制器的重启策略限制如下：

- RC和DaemonSet：必须设置为Always，需要保证该容器持续运⾏；
- Job：OnFailure或Never，确保容器执⾏完成后不再重启；
- kubelet：在Pod失效时重启，不论将RestartPolicy设置为何值，也不会对Pod进⾏健康检查。



### 资源限制

#### resources：request、limits

Kubernetes集群⾥的节点提供的资源主要是计算资源，计算资源是可计量的能被申请、分配和使⽤的基础资源。当前Kubernetes集群中的计算资源主要包括CPU、GPU及Memory。CPU与Memory是被Pod使⽤的，因此在配置Pod时可以通过参数CPU Request及Memory Request为其中的每个容器指定所需使⽤的CPU与Memory量，Kubernetes会根据Request的值去查找有⾜够资源的Node来调度此Pod。

通常，⼀个程序所使⽤的CPU与Memory是⼀个动态的量，确切地说，是⼀个范围，跟它的负载密切相关：负载增加时，CPU和Memory的使⽤量也会增加。

#### Requests和Limits如何影响Pod的调度 必会

当⼀个Pod创建成功时，Kubernetes调度器（Scheduler）会为该Pod选择⼀个节点来执⾏。对于每种计算资源（CPU和Memory）⽽⾔，每个节点都有⼀个能⽤于运⾏Pod的最⼤容量值。调度器在调度时，⾸先要确保调度后该节点上所有Pod的CPU和内存的Requests总和，不超过该节点能提供给Pod使⽤的CPU和Memory的最⼤容量值。

#### QOS



## service、网络：

### service是什么 必会

答：Pod每次重启或者重新部署，其IP地址都会产⽣变化，这使得pod间通信和pod与外部通信变得困难，这时候，就需要Service为pod提供⼀个固定的⼊⼝。

Service的Endpoint列表通常绑定了⼀组相同配置的pod，通过负载均衡的⽅式把外界请求分配到多个pod上

### k8s是怎么进⾏服务注册的？ 必会

Pod启动后会加载当前环境所有Service信息，以便不同Pod根据Service名进⾏通信。

### service类型

NodePort:集群外部访问内部的（网站、API、数据库）；在Node上kube-proxy通过设置的iptables规则进⾏转发；

ClusterIP:集群内部的网络通信（redis、rabbitMQ、内部的API）

LoadBalancer：云提供商的负载均衡器在集群外部可用的服务

headless：

#### 分发策略

RoundRobin：默认为轮询模式，即轮询将请求转发到后端的各个Pod上。

SessionAffinity：基于客户端IP地址进⾏会话保持的模式，即第1次将某个客户端发起的请求转发到后端的某个Pod上，之后从相同的客户端发起的请求都将被转发到后端相同的Pod上。

### 网络模型

Kubernetes⽹络模型中每个Pod都拥有⼀个独⽴的IP地址，并假定所有Pod都在⼀个可以直接连通的、扁平的⽹络空间中。所以不管它们是否运⾏在同⼀个Node（宿主机）中，都要求它们可以直接通过对⽅的IP进⾏访问。设计这个原则的原因是，⽤户不需要额外考虑如何建⽴Pod之间的连接，也不需要考虑如何将容器端⼝映射到主机端⼝等问题。

同时为每个Pod都设置⼀个IP地址的模型使得同⼀个Pod内的不同容器会共享同⼀个⽹络命名空间，也就是同⼀个Linux⽹络协议栈。这就意味着同⼀个Pod内的容器可以通过localhost来连接对⽅的端⼝。

在Kubernetes的集群⾥，IP是以Pod为单位进⾏分配的。⼀个Pod内部的所有容器共享⼀个⽹络堆栈（相当于⼀个⽹络命名空间，它们的IP地址、⽹络设备、配置等都是共享的）。

#### CNI模型

CNI提供了⼀种应⽤容器的插件化⽹络解决⽅案，定义对容器⽹络进⾏操作和配置的规范，通过插件的形式对CNI接⼝进⾏实现。CNI仅关注在创建容器时分配⽹络资源，和在销毁容器时删除⽹络资源。在CNI模型中只涉及两个概念：容器和⽹络。

- 容器（Container）：是拥有独⽴Linux⽹络命名空间的环境，例如使⽤Docker或rkt创建的容器。容器需要拥有⾃⼰的Linux⽹络命名空间，这是加⼊⽹络的必要条件。
- ⽹络（Network）：表示可以互连的⼀组实体，这些实体拥有各⾃独⽴、唯⼀的IP地址，可以是容器、物理机或者其他⽹络设备（⽐如路由器）等。

对容器⽹络的设置和操作都通过插件（Plugin）进⾏具体实现，CNI插件包括两种类型：CNI Plugin和IPAM（IPAddress Management）Plugin。CNI Plugin负责为容器配置⽹络资源，IPAM Plugin负责对容器的IP地址进⾏分配和管理。IPAM Plugin作为CNI Plugin的⼀部分，与CNI Plugin协同⼯作。

#### ⽹络策略

为实现细粒度的容器间⽹络访问隔离策略，Kubernetes引⼊Network Policy。

Network Policy的主要功能是对Pod间的⽹络通信进⾏限制和准⼊控制，设置允许访问或禁⽌访问的客户端Pod列表。Network Policy定义⽹络策略，配合策略控制器（Policy Controller）进⾏策略的实现。

Network Policy的⼯作原理主要为：policy controller需要实现⼀个API Listener，监听⽤户设置的Network Policy定义，并将⽹络访问规则通过各Node的Agent进⾏实际设置（Agent则需要通过CNI⽹络插件实现）。

#### flannel

- 它能协助Kubernetes，给每⼀个Node上的Docker容器都分配互相不冲突的IP地址。
- 它能在这些IP地址之间建⽴⼀个覆盖⽹络（Overlay Network），通过这个覆盖⽹络，将数据包原封不动地传递到⽬标容器内。

#### Calico

Calico是⼀个基于BGP的纯三层的⽹络⽅案，与OpenStack、Kubernetes、AWS、GCE等云平台都能够良好地集成。

Calico在每个计算节点都利⽤Linux Kernel实现了⼀个⾼效的vRouter来负责数据转发。每个vRouter都通过BGP协议把在本节点上运⾏的容器的路由信息向整个Calico⽹络⼴播，并⾃动设置到达其他节点的路由转发规则。

Calico保证所有容器之间的数据流量都是通过IP路由的⽅式完成互联互通的。Calico节点组⽹时可以直接利⽤数据中⼼的⽹络结构（L2或者L3），不需要额外的NAT、隧道或者Overlay Network，没有额外的封包解包，能够节约CPU运算，提⾼⽹络效率。

### Ingress

两者结合并实现了⼀个完整的Ingress负载均衡器。使⽤Ingress进⾏负载分发时，Ingress Controller基于Ingress规则将客户端请求直接转发到Service对应的后端Endpoint（Pod）上，从⽽跳过kube-proxy的转发功能，kube-proxy不再起作⽤，全过程为：ingress controller+ingress 规则 ----> services。

同时当Ingress Controller提供的是对外服务，则实际上实现的是边缘路由器的功能。

- 运维外部访问将流量路由到适当的服务（公开 集群内的Web 应用程序、简化外部访问，管理 API 网关，伪集群提供单一入口、终止 SSL/TLS 连接、与实施身份验证和授权集成（OA、OpenID等）、
- 可以扩展以处理高流量负载（更具HAP自动扩缩容）autoscaling、Deployment、StatefulSet）

**Egress**：安全性增强（限制集群内对外部的访问）、网络可见性（监视和控制集群内 Pod 的出站流量，统计各个应用的流量信息）

### Kubernetes Headless Service 无头服务

一种特殊的服务类型，它不为其后端 Pod 分配集群 IP 地址。相反，无头服务通过 Pod 的名称或 IP 地址直接访问后端 Pod。

优点

- 更好的可扩展性：无头服务不会消耗集群的 IP 地址，因此非常适合大规模的微服务架构。
- 简化的 DNS 管理：无头服务使用 DNS 名称来解析后端 Pod，从而简化了 DNS 管理。
- 更安全的通信：无头服务通过 Pod 名称或 IP 地址直接访问后端 Pod，从而可以防止外部流量进入集群

缺点

- 需要额外的网络配置：无头服务需要额外的网络配置，例如主机网络或服务网格，以确保 Pod 之间可以相互通信。
- 有限的故障转移能力：如果无头服务的某个后端 Pod 故障，则该 Pod 将无法通过服务名称或 IP 地址访问。

场景：

- 微服务架构：在微服务架构中，无头服务可用于将多个微服务连接在一起，而不会消耗集群的 IP 地址。
- 内部服务：无头服务可用于公开仅供集群内部访问的内部服务。
- 服务发现：无头服务可用于服务发现，允许 Pod 通过服务名称或 IP 地址直接相互通信



## 存储

### Kubernetes共享存储的作⽤

Kubernetes对于有状态的容器应⽤或者对数据需要持久化的应⽤，因此需要更加可靠的存储来保存应⽤产⽣的重要数据，以便容器应⽤在重建之后仍然可以使⽤之前的数据。因此需要使⽤共享存储。

```sh
临时卷：empytDir
本地卷：hostPath, local 
网络卷：nfs, ...
特殊卷：configMap，secret, downwardAPI
卷扩展：CSI
```

#### EmptyDir

（空⽬录）：没有指定要挂载宿主机上的某个⽬录，直接由Pod内保部映射到宿主机上。类似于docker中的manager volume。

- 场景：
  - 只需要临时将数据保存在磁盘上，⽐如在合并/排序算法中；
  - 作为两个容器的共享存储。
- 特性：
  - 同个pod⾥⾯的不同容器，共享同⼀个持久化⽬录，当pod节点删除时，volume的数据也会被删除。
  - emptyDir的数据持久化的⽣命周期和使⽤的pod⼀致，⼀般是作为临时存储使⽤。

### Hostpath

将宿主机上已存在的⽬录或⽂件挂载到容器内部。类似于docker中的bind mount挂载⽅式。

特性：增加了Pod与节点之间的耦合

### configMap

配置中心



### secret 必会

Secret对象，主要作⽤是保管私密数据，⽐如密码、OAuth Tokens、SSH Keys等信息。将这些私密信息放在Secret对象中⽐直接放在Pod或Docker Image中更安全，也更便于使⽤和分发。

#### Secret有哪些使⽤⽅式 必会

创建完secret之后，可通过如下三种⽅式使⽤：

- 在创建Pod时，通过为Pod指定Service Account来⾃动使⽤该Secret。
- 通过挂载该Secret到Pod来使⽤它。
- 在Docker镜像下载时使⽤，通过指定Pod的spc.ImagePullSecrets来引⽤它。

### downwardAPI

给容器注入元数据



### Kubernetes PV和PVC  必会

- PV是对底层⽹络共享存储的抽象，将共享存储定义为⼀种“资源”。
- PVC则是⽤户对存储资源的⼀个“申请”。

#### PV⽣命周期内的阶段 必会

某个PV在⽣命周期中可能处于以下4个阶段（Phaes）之⼀。

- Available：可⽤状态，还未与某个PVC绑定。
- Bound：已与某个PVC绑定。
- Released：绑定的PVC已经删除，资源已释放，但没有被集群回收。
- Failed：⾃动资源回收失败。

### Kubernetes的存储供应模式 必会

Kubernetes⽀持两种资源的存储供应模式：静态模式（Static）和动态模式（Dynamic）。

- 静态模式：集群管理员⼿⼯创建许多PV，在定义PV时需要将后端存储的特性进⾏设置。
- 动态模式：集群管理员⽆须⼿⼯创建PV，⽽是通过StorageClass的设置对后端存储进⾏描述，标记为某种类型。此时要求PVC对存储的类型进⾏声明，系统将⾃动完成PV的创建及与PVC的绑定。

### CSI

Kubernetes CSI是Kubernetes推出与容器对接的存储接⼝标准，存储提供⽅只需要基于标准接⼝进⾏存储插件的实现，就能使⽤Kubernetes的原⽣存储机制为容器提供存储服务。CSI使得存储提供⽅的代码能和Kubernetes代码彻底解耦，部署也与Kubernetes核⼼组件分离，显然，存储插件的开发由提供⽅⾃⾏维护，就能为Kubernetes⽤户提供更多的存储功能，也更加安全可靠。

CSI包括CSI Controller和CSI Node：

- CSI Controller的主要功能是提供存储服务视⻆对存储资源和存储卷进⾏管理和操作。
- CSI Node的主要功能是对主机（Node）上的Volume进⾏管理和操作。









## 安全

### 如何保证集群的安全性 了解

Kubernetes通过⼀系列机制来实现集群的安全控制，主要有如下不同的维度：

- 基础设施⽅⾯：保证容器与其所在宿主机的隔离；
- 权限⽅⾯：
  - 最⼩权限原则：合理限制所有组件的权限，确保组件只执⾏它被授权的⾏为，通过限制单个组件的能⼒来限制它的权限范围。
  - ⽤户权限：划分普通⽤户和管理员的⻆⾊。
- 集群⽅⾯：
  - API Server的认证授权：Kubernetes集群中所有资源的访问和变更都是通过Kubernetes API Server来实现的，因此需要建议采⽤更安全的HTTPS或Token来识别和认证客户端身份（Authentication），以及随后访问权限的授权（Authorization）环节。
  - API Server的授权管理：通过授权策略来决定⼀个API调⽤是否合法。对合法⽤户进⾏授权并且随后在⽤
- 户访问时进⾏鉴权，建议采⽤更安全的RBAC⽅式来提升集群安全授权。
- 敏感数据引⼊Secret机制：对于集群敏感数据建议使⽤Secret⽅式进⾏保护。
- AdmissionControl（准⼊机制）：对kubernetes api的请求过程中，顺序为：先经过认证 & 授权，然后执⾏准⼊操作，最后对⽬标对象进⾏操作。

### Kubernetes准⼊机制 了解

在对集群进⾏请求时，每个准⼊控制代码都按照⼀定顺序执⾏。如果有⼀个准⼊控制拒绝了此次请求，那么整个请求的结果将会⽴即返回，并提示⽤户相应的error信息。

- 准⼊控制（AdmissionControl）准⼊控制本质上为⼀段准⼊代码，在对kubernetes api的请求过程中，顺序为：先经过认证 & 授权，然后执⾏准⼊操作，最后对⽬标对象进⾏操作。常⽤组件（控制代码）如下：
- AlwaysAdmit：允许所有请求
- AlwaysDeny：禁⽌所有请求，多⽤于测试环境。
- ServiceAccount：它将serviceAccounts实现了⾃动化，它会辅助serviceAccount做⼀些事情，⽐如如果pod没有serviceAccount属性，它会⾃动添加⼀个default，并确保pod的serviceAccount始终存在。
- LimitRanger：观察所有的请求，确保没有违反已经定义好的约束条件，这些条件定义在namespace中LimitRange对象中。
- NamespaceExists：观察所有的请求，如果请求尝试创建⼀个不存在的namespace，则这个请求被拒绝。

### RBAC访问控制  必会

RBAC是基于⻆⾊的访问控制，是⼀种基于个⼈⽤户的⻆⾊来管理对计算机或⽹络资源的访问的⽅法。相对于其他授权模式，RBAC具有如下优势：

- 对集群中的资源和⾮资源权限均有完整的覆盖。
- 整个RBAC完全由⼏个API对象完成， 同其他API对象⼀样， 可以⽤kubectl或API进⾏操作。
- 可以在运⾏时进⾏调整，⽆须重新启动API Server。

#### Kubernetes PodSecurityPolicy机制  必会

Kubernetes PodSecurityPolicy是为了更精细地控制Pod对资源的使⽤⽅式以及提升安全策略。在开启PodSecurityPolicy准⼊控制器后，Kubernetes默认不允许创建任何Pod，需要创建PodSecurityPolicy策略和相应
的RBAC授权策略（Authorizing Policies），Pod才能创建成功。

模式：

- 特权模式：privileged是否允许Pod以特权模式运⾏。
- 宿主机资源：控制Pod对宿主机资源的控制，如hostPID：是否允许Pod共享宿主机的进程空间。
- ⽤户和组：设置运⾏容器的⽤户ID（范围）或组（范围）。
- 提升权限：AllowPrivilegeEscalation：设置容器内的⼦进程是否可以提升权限，通常在设置⾮root⽤户（MustRunAsNonRoot）时进⾏设置。
- SELinux：进⾏SELinux的相关配置。

## 监控

### 健康检查



#### Kubernetes Metric Service

在Kubernetes从1.10版本后采⽤Metrics Server作为默认的性能数据采集和监控，主要⽤于提供核⼼指标（CoreMetrics），包括Node、Pod的CPU和内存使⽤指标。

对其他⾃定义指标（Custom Metrics）的监控则由Prometheus等组件来完成。



PV/PVC

## Vxlan和IPIP的区别



CoreDns 三个参数

优先coredns---宿主机DNS

优先宿主机----使用场景当Pod使用宿主机网络时

