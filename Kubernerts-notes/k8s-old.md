默认创建的Pod 都无法容忍Master节点上的污点





## 快速入门

Kubernetes编排：开源的容器编排平台
        Images：layers 只读
Kubernetes：声明式API

​		两类节点：

​					控制平面

​					 工作节点 

Pod：容器集
	    容器运行时：container runtime
		CRI: Container Runtime Interface >> 对接第三方
		        Kubernetes自己并没有提供容器运行时，任何第三方组织的容器运行时只要能够遵循CRI规范，都可以被K8s调用 编排
		CR：容器运行时的具体实现
	    	     Docker-CE

​				     1、kubelet -- docker-shim --docker-ce  开始docker很流行且唯一 k8自己写代码 去兼容 docker 后来docker-shim被废除 

​                     2、kubelet -- cri-dockerd -- docker-ce   docker被收购创建了新项目 cri-docker 

​			      Containerd

Kubernetes集群:

​        master节点：

​				kube-apiserver

​								声明式-api  http/https  RESTful 的数据格式内置了多种 == 资源类型（pod  temple）

​								资源类型就是 长方形   对象就是我告诉资源类型我要5cm的长方形

​				kube-scheduler：调度pod

​				kube-controller-maragger

​				etcd：集群的状态存储

​        worker节点：

 		 		kubelet:控制器  管理pod

​							CRI: 容器运行时

​							CNI: 网络插件

​									给pod提供一个虚拟的网卡、分配IP、接入虚拟网络、创建虚拟网络、将虚拟网络接入外部

​							CSI：对接第三方存储

​		  		kube-proxy：将每个节点设定为一个可编程的负载均衡器 对于每个Service 节点上的kube-proyxy都会转换为该节点上的ipdables ipvs规则

   

运行工作负载:
			日常任务:部署、变更、更新、扩容、缩容、下线;

​					负责人:运维工程师、SRE
​			Kubernetes:编排运行应用

​						编排:工作负载型控制器（代码化了的运维工程师）

​									Deployment;编排无状态应用

​											HPA/VPA
​											关键组件
​											Pod Template
​											Replicas
​											Selector
​									statefulSet:有状态应用DaemonSet:系统类应用Job:
​											CronJob:
​									Service Discovery and LB: Servie
​									kube proxy:
​												iptables
​												ipvs
​															依赖内核中的网络栈中的netfilter
​									Service类型
​												ClusterIp
​												NodePort



Kubernetes.
			编排运行容器化应用的平台
			声明式API接口
						依赖于后端Controller支撑实现

​			控制器模式
​						Concilation Loop:确保实际状态无限接近或完全等同于期望状态



删除Pod Deployment控制器会自动创建，每次重构IP和Pod名称都会改变所以用ip访问pod，不是一个很好的方案，因此我们应该给Pod一个固定的点，这样我们客户端访问Pod上的服务只需要访问固定端点，这个固定端点由Service资源负责创建。

默认创建的（ClusterIP）一般是给pod作为客户端连接另一个pod

可以直接在节点内部用 Service名称访问 但是要把默认的DNS服务器改成CoreDns（pod中Dns地址就是Core）所以是Pod与Pod互相访问用的

通过标签和标签选择器和pod绑定 做好和pod端口映射 就可以实现给pod一个固定端点 即使pod删除重构我依然可以通服务名访问到pod上的服务，因此我们不用关注pod （ip 名字 节点）我们只需要关注Service他会用iptables/ipvs技术把进入到指定IP端口的请求，转发到标签选择器关联到的pod

我们去访问Nginx.svc 这个服务名 对应的正确的IP才能被调度到背后正确的pod上的服务 这个对外映射的ip地址是可以修改的











核心资源对象

​	workload（工作负载型）：pod、Deployment、ReplicaSet、StatefulSet DaemodSet job Cronjob

​	服务发现 负载均衡：service、Ingress

​	配置与存储：Volume CSI 容器存储接口（第三方扩展存储）阿里云  aws块存储   ceth  nfs

​		ConfigMap、Secret

​		Downward API

​		有状态服务应用必然会用到 Volume

​		以及为了方便配置容器化的应用服务必然会用到的ConfigMap、Secret



​	集群级资源

​		Namespace、Node、Role、ClusterRole、Rolebinding、ClusterRolebinding

​	元素据资源  （自动调整其他对象的元数据）

​		HPA、PodTempale、LimtiRange



创建资源的方法：

​		apiserver只接收 JSON格式的资源定义，写起来太复杂了、用yaml提供配置清单、apiserveri自动转换为JSON执行

把API切分成了几个小组、每个组可以独立的迭代和更新、因此某个组要更新时不至于影响到其他组

大部分资源的配置清单都有五个基础字段 我们用声明式资源清单

```bash
			apiVersion：群组版本   #kubectl api-vsersion

​			kind：资源类别 (根据某个资源要实例化的对象)

​			metadata：元数据
				name: 同一命名空间不可以重名

​			    namespace：

​				labels：
				anntations

​					每个资源的引用PATH

​			spec：对象实例化的目标状态 期望状态 

​			status： 当前状态无限先spec接近  这个字段不是人为定义的
```

一个Pod中两个容器 文件系统是隔离的 nginx有路径 Busybox没有nginx路径 如果都是Nginx就有相同路径

实际上 我们一般创建一个Vloume 然后把两个容器挂上去

spec： 内嵌了很多字段  给这些属性赋值以后 特定实例化的对象   

其中有很多字段都是可省的  系统通过提供默认值的方式 维护、当然也有很多必选的字段container

创建出来的Pod状态可能和我们定义的属性有细微的差别 通常都应该能够被K8s发现 让其从所谓的当前状态无限接近期望目标状态





![image-20240120141337748](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240120141337748.png)





```bash
Pod.spec.containers  <[]object>  对象列表
 -name
  image
  imagepullPolicy:
  		Always Never IfNotPresent 
#Always总是  每次都到仓库下载
#Never 从不  有就用没有就拉到
#IfNotPresent 有就用 没有就下载
#如果标签是Lates是就Always 因为本地最新和远程最新可能不一样

#command 默认不会运行在sh中必须要指定,如果没有提供command Docker images有ENTRYPOINT 那么他就会运行自己的命令
#args 如果我们手动指定的args 那么images中的cmd 后面指定的参数将替换成我们args的值
#如果我们只定义了command 就只有command生效 
#如果我们只定义了args 代表images中的cmd不在生效  自带entrypoint生效并且args作为参数镜像的CMD不在生效
```



## Pod控制器应用进阶

镜像名/镜像仓库

镜像获取策略（每次都下载）、（有就用没有不管）、（有就用没有就下载）

如果本地是latest默认就是Always

ports字段定义 仅仅是显示信息 、写这里只是看到这个文件知道pod中容器应用暴露的端口 并没有实际绑定端口的作用



### command

如果没有提供command 和 args 就使用docker 镜像中的Entrypoint 和 cmd

如果我们提供了command 没提供 args 只运行command  镜像中的Entrypoint和cmd都忽略

如果我们只提供了 args  就把args当作命令传给Entrypoint 

如果我们提供了args 也提供了 command 就用他俩

### Labels

标签就是附加在资源对象上的 键值对  帮助我们分类区分便于 管理

一个资源对象可以拥有多个标签  一个标签也可以被多个资源对象使用

**标签可以写在配置清单中  如果后续想要管理也可以用命令进行更改**

常用标签区分版本  版本  环境   应用类

```bash
#长度小于63字符 (key)字母数字开头 下划线连接线
key=value(可以为空)字母数字开头 结尾字母数字

#查看标签
kubectl get pods --show-labels 
kubectl get pods -L app #显示拥有次标签的pod后打印他的值 
kubectl get pods -l app 
kubectl label pods pod-name app=v1.24bata #打标签
kubectl label pods pod-name app=v1.24 --overwrite #更改标签

kubectl get pods -l app=v1.24，bata!=true #逻辑与 并且关系
```



一个资源可以存在多个标签 同一个标签也可以给多个标签用

每一个标签都可以被标签选择器进行匹配度检查 

可以使用标签进行标签分组筛选



标签选择器：

​		等值关系：=  ==  !=  等于 等于 不等于 

​        集合关系：

​			key in (value1,value2,value3)   

​			key notin (1,2,3) 隐含关系 有这键且他的值不能是1，2，3  没这个键也会显示

​       	 !key

​			kye 有这个key就行

许多资源支持内嵌字段定义标签选择器：Pod control  Server 关联标签pod时用到的选择器

​			matchLabels; 直接给定键值	

​           matchExpressions: 基于给定的表达式来定义使用的标签选择器 {key：“KEY”，operator:  , Values:[1,2,3]}

​			操作符：in   notin（必须为非空列表）  

​			 Exists NotExists（必须为空列表）

**`in` 和 `notin` 操作符：**

- `in` 操作符要求提供一个非空列表，以确保对象至少匹配列表中的一个值。
- `notin` 操作符也要求提供一个非空列表，以确保对象的属性不匹配列表中的任何一个值。

**`Exists` 和 `NotExists` 操作符：**

- `Exists` 操作符要求值列表为空，表示选择那些具有指定键的对象，而不考虑其具体值。
- `NotExists` 操作符也要求值列表为空，表示选择那些不具有指定键的对象。

```yml
matchExpressions:
  - key: app
    operator: In
    values:
      - frontend
      - backend
      
matchExpressions:
  - key: environment
    operator: NotIn
    values:
      - production

```



节点标签选择器 

节点也可以打标签 nodeSelector 从而确定这个Pod运行在哪个节点或者那类节点

nodeName 集群中node名字不能重名 就定于指定运行在某个节点

annotations：他不能被标签选择器 选择 仅仅作为对象提供元数据 键值长度不受限制

```bash
kubectl label nodes node01 disk=SSD
```





### Pod生命周期

 mian Container来之前，会启动一个init容器做环境初始化 初始化容器可以有多个，并且他们是串行运行的

初始化完成之后自动结束退出。

主容器启动后和退出前有两个钩子函数 他用来执行启动前命令和容器结束前命令不过我们一般不使用postStarst 

1. postStart 命令和镜像命令容器出现逻辑错误导致执行失败 容易阻塞  2. 我们有init容器

1. preStop **优雅终止** **等待连接关闭** **数据持久化：** 在容器终止前，可能需要确保某些数据被持久化到存储系

使用 `preStop` 钩子有助于确保容器在终止时能够完成必要的清理和终止工作，使容器的终止过程更加可控和健壮。

![image-20240120210146005](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240120210146005.png)

在容器创建出来后会有两个健康性检测和一个启动探测

检测都有三种检测方式   

容器探针：1 exec  2 httpGet 3 tcpSocket 

​		容器探测： 

​					livenes    存活状态检测

​					readiness  就绪状态检测

​      

容器重启策略：必须重启、只有状体为错误的时候重启、不重启

![image-20240120164255350](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240120164255350.png)

### Pod 探针

1. **livenessProbe（存活性探针）：**
   - **用途：** 用于检测容器内的进程是否处于运行状态。如果 livenessProbe 失败（返回非零状态码或超时），Kubernetes 将认为容器内的应用程序不再正常运行，会尝试重新启动容器。
   - **触发时机：** 定期执行，如果失败则触发容器的重新启动。
2. **readinessProbe（就绪性探针）：**
   - **用途：** 用于检测容器是否已经准备好接收流量。如果 readinessProbe 失败，Pod 将被从服务的负载均衡器中剔除，不再接收新的请求，但已有的连接不受影响。
   - **触发时机：** 定期执行，如果失败则从服务中移除，直到下一次成功为止。
3. **startupProbe（启动探针）：**
   - **用途：** 用于检测容器是否已经启动完成。与 livenessProbe 不同，startupProbe 可以在容器启动时的一段时间内进行探测，直到成功或超时。它用于处理一些特殊情况下应用程序启动慢的场景。
   - **触发时机：** 在容器启动后的初始一段时间内定期执行，直到成功或超时。一旦成功，后续将由 livenessProbe 接管。

总体来说，这三种探针的区别在于它们的用途和触发时机。livenessProbe 用于监测容器的运行状态，readinessProbe 用于决定容器是否可以接收流量，而 startupProbe 专注于应对容器启动阶段的延迟情况。通过合理配置这些探针，可以提高容器的可靠性和稳定性

状态：

   pendling  调度未完成 没有满足该Pod 条件的运行环境 所以就挂起了

​	Runing，

​	failed，失败

​	Succeeded

Pod 退出：第一次发送停止信号 给pod中所有容器一个宽限期（默认30s 可以指定） 到时间了 直接杀掉

PostStart：容器被创建出来后立即执行的操作，如果操作失败会重启（根据策略）我们一般不在这里做操作一般是在init容器中做  这里执行的命令和容器执行命令不分先后 有时候容器先执行有时候postStart先执行

PreStop：pod被终止前要执行的命令

#### Pod 重启策略

```yml
apiVersion: v1
kind: Pod
metadata:
  name: example-pod
spec:
  restartPolicy: Always(Default)  OnFailure（仅在失败时重启） Never 
  containers:
  - name: my-container
    image: my-image
 #后续详情在yaml文件中
 failureThreshold 连续探测几次失败 标记为不可用
 periodSeconds  每一次的探测间隔是
 timeoutSeconds  我发出探测我等多久 超时时间
 
 initialDelaySeconds  第一次启动时 不能在容器起来后立即对它做探测，因为它可能没初始化完成这时候我们去探测他肯定没起来
 
 存活未必就绪 如果不就绪就会从Service上标记为不可用就不会掉地到此Pod
 使用http 请求响应码 200 300 正常
```

 ![image-20240120180523940](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240120180523940.png)



当我们创建好Svc 并根据标签选择器 把一些pod纳入进来

如果我新创建的Pod 满足被此Svc选择的条件那么也会被纳入此 SVC 

启动后就立刻被纳入并且接收请求 但事实是Pod READY并不代表Pod中的服务READY 所以此时用户访问必然是有问题的 

Svc 是一个固定入口 我们为动态的有生命周期的Pod资源提供了一个固定入口 这后面可以是多个Pod

客户端不用 也不能直接访问Pod 而是先访问Svc 是通过MatchLabels关联到某些Pod

比如我们又创建了一个新Pod 而且她也否和此Svc的选择条件一旦满足条件 将立刻被纳入到此SVC后端[Pod 

一创建成功就被关联到SVC 但Pod中的服务很可能还没有就绪，因为服务起来初始化要加载文件，这时候用户访问必然是失败的  应该是但Pod中服务就绪了 部署好了  SVC在把流量调度到此Pod

必须要做 就绪探测和生命探测

 kubectl exec -it readiness-httpget -c readinessrobe-http  -n myapp -- /bin/sh

**小总结**

```
spec:
	containers:
		nodeSelector
		restartPolicy:
			Allways,Neverm,OnFailure
		name
		image
		imagePullPolicy: Always, Never, IfNotPresent
		livenessProbe
		readinessProbe
		liftcycle 钩子

ExecAction;exec
TCPScoketAction:
httpget
```









## Pod 控制器

自助式Pod不受 控制器管理 删除不会重建

**DaemonSet :** 用于确保集群中的每一个节点只运行 一个特定的Pod副本 (用来实现系统级的后台任务)

 	当我们向集群中加入一个新节点 DaemonSet会确保每一个节点精确运行一个特定Pod副本

​	定义DaemonSet时他的数量取决于节点数量 

​	需要标签选择器：

​	根据需求在集群中的部分节点监控 比如监控只在有GPU节点上部署一个DaemonSet Pod副本

​	这种服务必须时守护进程类的 不能中止

 DaemonSet：pod分配到每个Node节点上 pod中的日志和Node日志都存在Node中 所以我们要在节点上部署一个日志监控系统 但是这个存在单点问题 没法在同一个节点上部署两个一样的服务  用DaemonSet部署 坏了自动拉起一个 而且集群内加入新的Node 直接自动部署 很省事

每个节点会运行多个Pod  因此我在每个节点部署一个日志agent 来监控他们 没必要部署俩一个节点一个就够了因为他要收集这个节点上所有Pod的日志以及当前节点自身的日志 应该部署到节点上 并发送到日志管理服务器

Deployment运行的容器在那个节点上都有可能一个节点还会有两个   我的目的是集群每个节点都要部署且只有一个 我们用DaemonSet 实现 



不用后台一直运行

**job**  只做一次 正常执行完成就退出，如果任务因为某些原因没完成  此时就会重构

**cronjob** 周期进行任务   如果上次任务没结束 下次任务开始 就直接执行新的任务



**Deployment：**无状态应用

比如我养了一群鸡 我今天宰一只吃了     大家会觉得无所谓吃就吃了还有一群 小鸡还会长成大公鸡又能吃了

如果你养了两只宠物狗  假如我的宠物狗被宰了吃了 你是否会觉得无所谓呢  因为养宠物是投入感情的所以不是随随便便一个宠物狗就能替代的  你的有状态服务就相当于你投入精力感情挂了拉一个新的Pod和以前不一样

个体和群体的区别

假如你管理的是 redis Cluster 他们是分配的槽位是固定的 他们都不能取代对方 新的进来没有数据

关注个体 每个个体都是要被独立对待的 独立管理的

我们运行了三个nginx 配置文件重新加载 他还是会调度到后台服务器随便被取代



用户帮我们管理pod、并帮我们确保Pod始终处于我们所期望的状态

​			ReplicaSet：副本数  标签选择器	（如果Pod小于期望的副本数）根据pod模板创建

代用户创建指定数量的副本，并确保Pod副本一直处于满足用户期望的状态和数量 多退少补并且支持滚动更新和回滚 自动扩缩容



Deployment：更新  比如有四个 v1  停掉一个V1   启动一个V2   然后再停掉一个 V1   再启动一个V2 知道所有V2更新完毕  这个过程是自动完成的 而且更新后不会删除副本 默认保留十个旧版本

如果现在客户访问四个pod正好满足负载 这时候我们删一个就会导致 服务崩掉

不删又不更新  所以我们需要临时加几个 怎么加我们可以定义  多出最多期望的1个 最少能少于期望副本数多少个

假如我们期望的副本是 5个  定义最多多1个  最少不能少 先加一个新的删一个老的  可以控制更新粒度

我们这时候只能先加     比如有四个 v1  启动一个V2  然后再停掉一个 V1  这样就OK了

![image-20231220230324402](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20231220230324402.png)



假如我们现在5个Pod   前面有一个Svc 我们想更新但是此时必须删一个 新建一个才能达到更新的目的

如果现在访问量很大 5个Pod负载都很高 我们删一个 服务直接崩了  不删又不更新

我们可以先临时多加一个在删除一个旧的以达到更新的目的

但加一个又会违反Pod管理机制 精确副本数就是5 

Deployment 支持定义 最多 多几个副本  最少少几个副本两个维度控制更新

假如我们有5个Pod副本

如果我们定义好最多多一个  最少不能少

那么他的更新节奏就是 加一个 删一个 

如果我们定义最多多两个 

两两更新

如果我们定义最少少一个 不能多

先删一个旧的在加一个新的



我最多允许多1个 最少允许少一个

6     4     加一个删俩  

实现蓝绿 我允许最多多5个 但是不能少 一下就变成10 删除另外五个旧的 



```
strategy 更新策略
如果使用Recreate 那么rollingUpdate就没用了
如果type 是RollingUpdate可以使用这个字段定于滚动更新的策略
paused  暂定更新
kubectl  rollout  undo  默认滚回前一个 --to-revision=?	


```



MaxSurge  超出副本数多少

MaxUnavailable  最少有几个不可用

一般情况下不能同时为0 

revisonHistoryLimit  保存多少历史副本 默认10个

kubectl rollout history  【name】

Deployment 创建的Rs 值是模板的哈希值 只有最后的才是随机的

![image-20240121095752166](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240121095752166.png)





**StatrfulSet**:

每一个应用每一个Pod副本都是被单独管理的 独有的标识 独有的数据集

 如果我们有一个readis 为了确保每个节点挂了数据不丢失 我们做主从配置  当其中某个节点挂了 我们要提升某个节点为新主 而且还要恢复坏掉的节点 这其中有很多运维任务  很麻烦

 

去管理Mysql、reids、主从 配置是不一样的没有什么共性，没有任何共同的规律

它只是提供了封装的控制器，把我们手动执行的操作封装成脚本的方式，放在它定义pod模板中，每次节点故障后能通过执行脚本恢复，我们的脚本未必能考虑到所有情形 每个有状态服务都需要一套脚本 它们都没有什么共性都要重写   有状态应用托管在k8s中是很麻烦的。



模板中定义的标签必须符合标签选择器的键值 不然他会创建但是创建出来的又不满足标签 就会死循环



![image-20240120230201645](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240120230201645.png)



如果定义的副本数是2   但是实际满足其控制的Pod有三个 他就会随机杀一个 如果是无状态的无所谓有状态的就很危险了
因此我们定义有状态服务的标签选择器时尽量要复杂一些



控制器创建Pod 

要想让用户不受Pod生命周期影响的访问  

首先我们应该知道Pod故障重建 IP会变名称也会变

所以我们要添加一个固定的断点   就是Server  和我们控制器选择的标签应该时同一个

Server和控制器并没有直接关系  Server后端的Pod可能来源于多个控制器所控制的Pod

更新升级  edit  副本  或者镜像版本 并不会直接生效 重建新的Pod才会基于更改的镜像创建完成升级

![image-20240120231202060](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240120231202060.png)

![image-20240120232130653](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240120232130653.png)







## service

在Kubernetes 这个管理平台之上，Pod是有生命周期的一旦这个Pod挂了 重建那么他的IP 名字将会改变这对用户来说时候非常头疼的， 所以为了能给客户端一个固定的访问入口，因此我们在客户端可以Pod服务端之间添加了一个固定的中间层，Service 但SVC也严重依赖于集群之上部署的一个附件 CoreDNS



Node network、Pod network、Cluster network(virtual IP) 这IP并不实际存在 只是在存在于SVC的规则中

在每个工作节点都有一个组件Kube-proxy 将始终监视着apiServer有关service资源的变动信息

一旦获取到有关自己节点上的Svc信息Kube-Proxy就会把他转换为当前节点的iptables 或者 ipvs 规则

工作模式

#### user space

![image-20240121111550111](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240121111550111.png)

Pod 或 客户端 请求到达Service 先转到监听Svc端口用户空间运行的kube-proxy由Proxy处理完在代理至相关联的各个Pod （效率很低）

![image-20240121112106060](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240121112106060.png)

Kube-proxy 监视着aptServer 有关于当前节点相关的SVC规则就添加

用户访问Service 直接调度到后台Pod  

第三种把iptabls 换成ipvs



Svc有三个端口 Nodeport   targetPort   Port     type=Nodeport时定义 Nodeport端口时时才生效不然是没用的

protocol  默认tcp

**请注意，手动指定** `clusterIP` 的做法需要小心，确保不会导致 IP 地址冲突。最好让 Kubernetes 自动分配 `clusterIP`，以减少潜在的配置错误。

只要集群上的addang DNS存在  那么我们就可以直接解析他的服务名 每一个服务创建完 都自动在集群DNS中添加一个动态的资源记录

redis.default.svc.cluster.local

指定NodePotr 保证节点端口不会冲突





我们集群中有个Pod 要调用集群外的Mysql 拿数据

Pod用的都是私网地址就算请求路由出去 对方也没办法响应

ExternalName就用于实现

我们在集群中建一个Service 他关联的后端不是本地Pod 而是互联网上的某个服务

当我们Client Pod 访问次SVC时 由Svc通过层级转换到Nodeport请求到外部服务 通过Node节点的Snat 和我们路由上网的道理时一样的

外部服务响应我们先到达NodeIP ----SVCIP ----Pod  IP    CNAME

sessionAffinity    Cluster IP  基于IP调度会话保持

![image-20240121121231828](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240121121231828.png)







Headless Service   不用指定Service IP映射  直接访问后端podIP  有状态应用会用到


Headless Service 是 Kubernetes 中的一种服务类型，它与普通的 ClusterIP Service 不同。Headless Service 的主要特点是它没有 Cluster IP（虚拟 IP 地址）。相反，它通过返回与 Service 匹配的所有 Pod 的 DNS 记录来实现服务发现。

具体来说，Headless Service 的特点包括：

1. **Cluster IP 为 None：** Headless Service 的 Cluster IP 被设置为 None，表示没有分配虚拟 IP。
2. **每个 Pod 都有 DNS 记录：** 对于该 Headless Service 中的每个 Pod，都会有一个对应的 DNS 记录，其格式为 `<pod-name>.<service-name>.<namespace>.svc.cluster.local`。
3. **没有负载均衡：** 与普通的 ClusterIP Service 不同，Headless Service 不提供负载均衡功能。请求直接通过 DNS 解析转发到后端 Pod，没有中间的负载均衡器。

Headless Service 在一些特定的应用场景中非常有用，特别是对于需要直接与每个 Pod 通信的服务发现。例如，StatefulSets 常常使用 Headless Service，因为它们需要稳定的网络标识符来与每个副本进行交互



Service 是4层负载 如果我们要基于https访问的话那么我们后端所有Pod  都要配置https

4层无法卸载https包	



![image-20240101215332638](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240101215332638.png)

内核功能必须开启IPVS 模块 否则自动降级	



​	内核优化：ip_vs相关的要添加

​		模型：usernamespace   iptables   ipvs

​	ClusterIP 集群外部无法访问  

​	NodePort 	NodePort Client ------> 先到达 Node IP:NodePort ----> 然后到Service空间的Clusterip  ------> 到 PodIP



Service  模型

​		userspace、iptables、

​	ipvs (内核中支持) ip_vs ip_vs_rr ip_vs_wrr ip_vs_sh



Cluster IP  NodePort

Client ----- NodeIP:NodePort ------ Cluster IP Port ----pod ip   containerProt 

无头服务



## ingress

引入集群外部流量 ingress 7层调度器

Service 是四层代理他有个缺点就是无法卸载https

如果我们想把我们某个Pod中的服务增强至https 那么我们就需要在后端所有Pod都要配置一遍证书和私钥



客户端来访问的时候，域名访问解析的IP是调度器的IP 而不是后端主机的IP

客户端来请求与Lvs建立连接解析的IP是调度器的IP   SSL会话和后端主机连接

证书中要配VIP

又贵又慢 ssl会话我们做一次就行 在前端调度器完成https会话  后端reloServer是内网安全的使用http

![image-20240121134513732](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240121134513732.png)



Kubernetes提供了一种独特的解决方式 加一层

我们在整个集群进行调度时后端被代理的Pod是不配置https的，使用一个独特的Pod这个Pod是一个运行在用户空间也就是7层的应用 nginx eny   

当用户试图访问某个服务时 我们让请求先到达这个7层负载均衡Pod 再由此Pod直接调度到后端Pod服务 

这个7层Pod自身怎么接入外部流量呢  Nodeport  但nodePort负载太高所以集群外的负载均衡要代理到后端多个nodePort

![image-20240121135703230](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240121135703230.png)

这中间调度的层级太多了  1 2 3 4 5 性能太差了

我们可以让7层Pod直接共享Node节点的网络名称空间  减少两层 提高性能

但是这个Pod要监听节点的网络名称空间 因此避免端口冲突每个节点只能运行一个

和svc不一样 svc你访问那个节点的NodePort svc都能通过ClusterIP送达到后端的Pod上，每个Node节点都有30002这个端口所以我们访问任意节点的30002都能命中SVC的规则

但现在此Pod要监听节点的网络 你访问那个节点就是那个节点 别的节点没有存在单点问题

DaemonSet每个节点上都运行一个 但如果有100个节点我们要运行100个嘛DaemonSet可以支持只在有限的节点上不用非得是全部也可以时100个中的10个 给这10个打上污点让别的Pod都调度不上来 再Daemon上配置容忍调度到这三个Pod上



![image-20240121135904701](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240121135904701.png)



### Ingress Controller

此控制器和 Deployment  DaemonSet  replicas StarfuSet 不一样 他们时作为Controller - manager 的一部分存在  自己运行的一个Pod 或一组Pod  他通常是一个应用程序 

1 Envoy 2 nginx  3 HAproxy 4 Traefik

![image-20240121143256966](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240121143256966.png)

前端有一个Pod 7层代理服务器   后端有多组Pod  每组都是不同的服务 如何配置呢

写四个Server 虚拟主机 每个Server对应一组Pod 但这就要求我们拥有很多域名 

假如我们就一个主机名  可以写多个loation URL匹配不同的请求

![image-20240121144019972](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240121144019972.png)



但是Pod是有生命周期的，我们在nginx定义的UPstarm sverver 指定Pod ip  但是Pod重建IP就变动了 调度失败了假如我们扩容了怎么办 UPstarm Server要手动添加pod地址进去 那我们要是缩容了呢 再删掉？？？

nginx的配置会变得非常麻烦，Service是通过标签选择器 关联满足自己标签的Pod 而且Service始终watch这apiServer 始终观察者标签选择器对应的Pod是否发生变动了

我们可以定义一个SVC帮我们分组 监视这个后端Pod 实施更改，多一个少一个都不变都能添加到这个svc中

Ingress Controller 监视这个 Svc  如果有主机发生变化就把这个主机名写到配置文件中的UpstarmSverver

Ingress 如果帮我们建立一个前端主机 又要定义后端 UPstarm  有多少个主机 通过svc得到

![image-20240121150047257](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240121150047257.png)

`kubernetes.io/ingress.class` 注解用于指定使用哪个 Ingress 控制器处理当前 Ingress 资源。在你的例子中，它设置为 "nginx"，表示该 Ingress 资源由 Nginx Ingress Controller 处理。如果你使用的是其他 Ingress 控制器，你需要相应地设置该注解。

具体ingress怎么用 请看笔记yaml文件













## 存储卷

Pod运行时在某个节点，只要不出故障就一直运行，有故障重启，除非Node节点出问题了才会调度到其他节点

pod重建数据就没了 所以我们不能把数据放在Pod中，我们可以放到节点上把Pod中某个存储路径和节点上路径建立关联关系或映射关系，随后容器中存储的数据都存到节点上了，只要节点没问题，Pod重建重新挂载，也可以做到一定程度上的数据持久化

但是如果节点出问题了，或者我们人为删除，k8s会重新调度一旦调度到其他节点上，以前节点上的数据就无法挂载

为了实现真正意义上的数据持久化，我们应该使用脱离节点的共享存储设备 

同一个Pod内的多个容器 可以共享访问同一个存储卷，存储卷不属于容器，属于Pod单位



我们可以把容器挂载到宿主机的一个目录下，而宿主机的这个目录时挂载到网络存储设备上的 比如NFS saiF 

但我们要确保我们每一个节点能够驱动相应的存储设备  比如你要用NFS 要apt install NFS



![image-20240121165959252](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240121165959252.png)



支持的存储卷

​	 emptyDir   映射到宿主机某个目录但随着容器删除此目录也会被删除

​	 hostPath   直接挂载到宿主机的某个目录下

​	  SAN:ISCISI

​	  NAS:NFS CIFS

​	 分布式存储：ceph rbd  cephfs

​	 云存储：EBS  Azure Disk



用户使用K8s 创建Pod时 为了实现持久能力，我们得在Pod中定义存储卷 

pod中定义要使用那个PVC  而且在当前命名空间下要由实际存在的PVC只是申请  要与 PV建立关系与实际存储关系

由专门管理存储的工程师创建出PV   我们运维就直接创建PVC用即可

我们能用Pvc调用PV  前提是要有PV 要提前和管理存储工程师请求

但如果是公有云 有很多租户 我们压根不知道租户啥时候常见PVC 

我们把所有的存储空间抽象成存储类，当用户需要创建存储卷pvc是 向存储类发出申请，存储类会帮用户创建出符合需求的PV



我们在Pod中创建两个容器 一个主容器一个边车容器  边车容器负责每隔一段时间向共享存储中生产一个网页文件

我们的主容器把共享存储挂载到网页路径下 加载共享存储边车容器生成的页面响应给请求者

![image-20240121175859812](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240121175859812.png)

** :** 如果指定的路径不存在，将会被创建。这是默认的 `type`，当你不指定 `type` 时，Kubernetes 将默认使用 `DirectoryOrCreate`。这意味着如果路径不存在，将会被创建，如果路径已经存在，则会被使用。

**Directory:** 仅在指定的路径已经存在时使用，如果路径不存在，Pod 将无法成功调度。

```yaml
volumes:
- name: my-volume
  hostPath:
    path: /path/on/node
    type: DirectoryOrCreate
```





在Pod中我们只需要定义我要用多大的空间 这种存储卷就叫PVC，而Pvc类型的存储卷必须与当前命名空间下的pvc建立直接绑定关系 ，pvc必须与pv绑定，pv是后端真实的存储 任意类型

存储工程师是把存储做出来，运维把存储映射到K8s集群中也就是做成PV

创建出PV pvc是没有实际作用的   什么时候有用呢，绑那个pv?  用户在Pod中定义了PVC 类型的存储卷  PVC根据用户请求的空间大小去绑定对应的PV 



首先 我们系统上应该是有一个存储设备由我们的存储管理员划分好存储空间

我们的集群管理员 把这些划分好的存储空间 都引入集群中做成PV

随后我们的用户，假如要创建Pod  在创建Pod之前他得先创建PVC就是要在当前集群中找一个能符合我们条件的存储空间，而后我们的pvc就要申请找 

pvc和pv是一 一对应的，一旦绑定就不能被其他pvc所绑定了 显示状态时banding

但是一个PVC在创建并绑定pv后 他就时一个存储卷了  存储卷却可以被多个Pod所访问不过我们可以定义访问规则来限制是否能被多用户同时访问或者同时只能读 

![image-20240121200234946](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240121200234946.png)





如果懂存储直接用   不懂就抽象成 PV  然后直PVC接申

pv 是整个集群的资源

pvc

##### **存储类 自动申请**

在pv 和pvc使用过程中存在一个问题，就是pvc申请的时候未必就有现成的PV 能够匹配我们的条件，

能够让Pvc在申请P时，不针对某个pv，我们可以针对某个存储类， 

StorageClass 我们可以事先把众多的存储设备， 定义成存储类，我们不做pv了因为我们并不知道将来Pvc要申请多大空间，所以我们用定义成StroageClass分类

存储设备必须支持reus fang 风格的API接口	

我们只提供存储集群   efth 就支持

比如我们只提供一块硬盘 在硬盘前面搞一个K8s支持的接口。认证，存储类自己创建、划分，并且修改/etc/export挂载配置文件把空间挂出去 并且定义好pv 供pvc使用  

![image-20240121204236836](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240121204236836.png)



emptyDir   可以直接定义宿主机的 内存或Disk 做存储卷   pod删除数据全丢

hostPath  主机目录共享

configmap 是靠env

StatefuSet：三个要求  无头服务   pvc模板  



配置容器化应该用的方式

​	1 自定义命令行参数; command   args 

​	2 做镜像时把配置文件写进去 nonono

​	3  环境变量  应用程序支持

​	通过entryPoint 脚本预处理配置文件中的配置信息、或环境变量

​	4、存储卷 (很笨重 要准备不同的存储卷 事先规定好存储卷 制作pvc pv  hostpas调度到其他节点还得重新整)





**ConfigMap** 解耦

从外部像镜像内部注入配置信息

我们不把配置信息写死在镜像中，而是引入一个新的资源

假如我们现在要启动Pod  可以把ConfigMap 关联到此Pod上去 从里面读一数据传递给Pod中的环境变量

也可以直接把ComfigMap 作为存储卷类型的配置文件挂载到应用引用配置文件的目录下

可以动态修改的 修改完同步给使用此ConfigMap 的Pod

简单来说ConfigMap 就是多个配置信息的集合，且有两种注入方式  1 通过env Valuefrom    2 存储卷挂载

键值对数据



![image-20240121221933241](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240121221933241.png)

如果是这样创建  应用的文件名就是 key  文件内容就是 values

如果我们要通过环境变量的方式注入配置信息那么你必须确保环境变量可以被容器所引用

如果用环境变量的方式 不能实时更新修改



如果我们以存储卷的方式挂载ConfigMap Key就是文件名 Value 就是文件内容

先关联到Pod   要在Container中把整个存储卷也就是ConfigMap挂载到容器某个路径下，那么整个存储卷也就是ConfigMap所有的键值统统以文件的形式  基于存储卷形式的挂载配置文件是可以实时更新同步到pod中容器





```bash
kubectl create configmap my-configmap --from-file=www.zed.org.conf=path/to/your/file.conf
```

如果你想使用 YAML 文件来声明这个 ConfigMap，可以创建一个文件，比如 `configmap.yaml`

```yml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-configmap
  namespace: your-namespace
data:
  www.zed.org.conf: |-
    {{ .Files.Get "path/to/your/file.conf" | nindent 4 }}
    
如果我们的configMap中有多个Kye  我们可以用items指定我们只挂载某个Key 自己指定文件名和Key名 
Mode 777 加权限
```



**Secret**

​	docker-registry     在节点运行Pod 他得把Pod依赖的镜像拉下来  如果是私有仓库 必须要提供密码

​	 Por要和获取镜像 但获取镜像的仓库必须要提供认证的时候这个node节点上的 kubelet要能自动认证到这个私有仓库    我们在Pod中定义 imagePullSecrets  而这个se'crt 包含了认证密码 而且他的类型必须此类



​	generic   密码

​	tls            证书



base64 编码



#### StatfulSet

​	1 稳定且需要有唯一的网络标识符

​	2 稳定且持久的存储

​	3 有序平滑的部署和扩展

​	4 有序平滑关闭

​	5 有序的滚动更新

headless  server 、statfulset、volumeClaimTemplate







因为

有状态集群

每个pod都要有自己专用的存储卷 









## 认证安全

整个 k8s 



认证: 账号是否存在  是不是合法账号  预密钥登录   SSL(双向证书认证)K8s也要认证客户端身份

授权: 授权检查 RBAC   

准入控制:  授权没问题但是 你修改的文件依赖因一个文件是否可以控制 进一步完善了授权





只检查一次通过 就不检查后续插件了 没通过在检查第二种

许可授权 默认都是拒绝的





客户端----> API server

​	 username uid   

group    

extra

API ：用户一定是请求某个特定Api资源  k8s Api是分组的  你到底要向API那个版本 哪个组的那个资源发出请求

只要不是核心群组都要写  apis/apps



Kubernetes中的ServiceAccount用于为Pod中的进程提供身份验证信息。每个Pod都会自动关联到一个ServiceAccount。默认情况下，每个Namespace都有一个名为"default"的ServiceAccount，该ServiceAccount关联到一个Secret，其中包含与该ServiceAccount相关联的身份验证令牌。

这个Secret的类型通常是"kubernetes.io/service-account-token"，而不是"Opaque"（Secret的一般类型）。它包含了身份验证令牌和其他相关的信息，用于在Pod内部进行身份验证和与Kubernetes API服务器进行通信。

但是这个默认的账号权限比较小 一般只能查看关于Pod自身的 如果我们要运行一个管理类的Pod 我们就必须手动创建一个Service Account 并赋予管理权限 并附加到Pod上

我们不能改默认账号 不然此命名空间下的所有Pod 都有很大的权限，因此我们必须手动创建一个专用账号

不过只是一个账号，后续我们要创建角色并绑定此账号

```bash
kubectl  get  pods  name  -o yaml --export
kubectl config
```

![image-20240123195842379](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240123195842379.png)

可以在Service Account上直接添加 镜像仓库的认证信息

1. 在pod上直接使用imagePullSecret字段
2. 在Pod自定义ServiceAccouont 在SA上符加imagePullSecret



/etc/kubernetes/pki    ca.key  ca.crt  可以用再带的证书签发认证文件  ，认证不一定有权限

签发证书时 申请文件中的sbjkt 就是用户名 以前写域名的地方 写用户名 

```
1 生成私钥
2 openssl req -new -key zed.key -out zed.csr -subj "/CN=zed" 用户名 
```

![image-20240123202436943](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240123202436943.png)

![image-20240123202953513](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240123202953513.png)

![image-20240123203204251](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240123203204251.png)

















​	Request Path

​	http://172.20.0,70:6443/apis/apps/v1/namespaces/default/deployments/myapp-deploy/

HTTP request verb：

​		get  post  put  delete

通过http URL发送请求 指定方法  HTTP 请求方法要转换成Api server 解析的

Api requets  verb：

 		get、list、create、updata、watch



Api server 客户端：

​			集群外部   集群内部 Pod、集群外部图形界面(通过它增删改查)

​			人类实际账户   Pod服务账户

每一个命名空间下都一个默认的token 用存储卷的形式 加载给pod使用 所有pod可以连接 api server

创建serveraccount  通过ServeraccoountName加载

创建一个自定义serveraccount会自动生成一个token 只是用来认证这个账号可以连接到Api server 并没有权限 



Pod要使用四仓拉去镜像的时候 可以直接定义 image pull secrets

也可以在Pod中定义Serveraccount 在Serveraccount中定义 image pull secrets

也可以 image pull sercrets 账户一起定义在 serveraccount 上可以实现一起认证私仓

![image-20240101143302108](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240101143302108.png)





Curl 命令请求  Api server是用https服务 他要做双向证书认证   Curl没有认证

之所以我们用Kubuctl 直接访问API server 不用认证 是因为我们初始化生成了 认证文件  拷贝到任意主机  Kubuctl 用这个认证文件就可以连接到 API server		

Kubectl proxy --port=8080 本地启动代理  让Curl 访问Kubectl proxy 通过它反向代理到 api server



![image-20240101124330790](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240101124330790.png)





我们连接Api server 基于kubeconfig 认证 这个文件要包含

​			连接的集群、提供账号、证书、私钥 、token



上下文

当前使用那个账号访问那个集群

Clusters：用来定义集群列表  比如我们可能有多个集群都要定义在这里

Context：比如我们有多个集群和账号 它用来定义 那个账号访问那个集群  

例如：我们有个集群 A   我们有三个账号 user1 user2 user3 我们就可以定义好 user1 来 访问A集群

![1704093164660](C:\Users\50569\Desktop\运维笔记\笔记图片\1704093164660.jpg)



![image-20240101151307152](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240101151307152.png)



用这种方式连接Api server  我们要认证api server 的证书  api 为了确定身份也要认证我们的证书

为了确保身份认证成功 我们要用Api server 信任的CA 签发证书   初始化安装的时候 会自动建立CA 用k8

自带的Ca 签署证书即可  要注意subject CN 是用户名称

自建账户 文件不使用默认的 



Object URL:

​		/apis/<GROUP>/<VERSION>/namespaces/<NAMESPACE_NAME>/<KIND>[/0BJECT_ID])

### RBAC

授权插件: Node 、ABAC、RBAC 、Webhook

​		Role-based AC

​		角色：(role)

​		许可：(permission')

基于角色访问控制

让用户扮演某个 ----- > 角色 （permission）

在 restfor风格接口 一切皆对象   我们定义 能对这个对象做什么操作  对这个对象做出的行为 就等于 许可 

随后把这个许可绑定到某个角色   用户扮演这个角色就和获取到了权限

![image-20240101161025333](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240101161025333.png)



Role :

- poerations
- objects

Rolebinding

- user account OR  service account 
- role [角色名]



ClusterRole、ClusterRolebinding



我们可以在一个命名空间定义多个Role 每个Role有不同的权限，当我们把某Role 绑定到某个用户上 他就可以在这个名称空间下扮演这个角色，并且获得他的权限（应该也可以扮演多个角色）

**ClusterRole、Role 生效范围不同**

**Cluster Rlole 权限 只针对Rolebinding 所在的命名空间生效**

比如我们定义Role 定义权限  get Pods 但他只能查看当前名称空间下的所有pod

如果我们定义ClusterRole  定义权限 get pods  它查看的是集群全部Pod



**只要是RoleBinding 就限制在命名空间内生效**

比如我们定义  ClusterRole   定义权限  get pods

当User1通过 ClusterRolebinding 绑定ClusterRole  它就可以查看所有集群的Pods

当User1通过 Rolebinding 绑定ClusterRole  即使是集群级别角色权限   但它也只能在命名空间内生效



我想授权一个user1 对当前命名空间有管理权限，如果我有100个命名空间(定义role rolebinding  n次)

比如我们有100命名空间，每个命名空间都需要一个管理员，他们的权限都一样 

如果定义Role 然后用Rolebinding ( 它只能用于当前命名空间 别人不能用 )  所以我们要定义100次Role

如果我们定义ClusterRole  然后 rolebinding，我们只需要定义一次ClusterRole  因为ClusterRole 对所有命名空间都有这个权限  我们只需要用 Rolebinding  去限定某个角色在用ClusterRole时的生效范围只能时命名空间



![image-20240101164015031](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240101164015031.png)



比如说我们有10个命名空间   每一个命名空间都需要一个账户  Role 只有命名空间级别的权限

如果我们用Role 和Rolebinding 我们在10个命名空间中都要 定义 Rloe 和Rolebanding  重复十次



如果我们定义一个ClusterRole  使用Role banding  ，ClusterRole 拥有所有权限 但使用Rolebanding他就在命名空间生效

所以我们只需要定义一次 ClusterRole  在每个命名空间下用Rolebanding 

就可以达到 既能控制生效范围在命名空间  也能减少重复工作次数

ClusterRole 本来是集群范围的角色 但是使用Rolebanding 就生效于 Role 所在的命名空间

![image-20240123211007358](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240123211007358.png)



创建Role  然后 rolebinding

限定范围 ： 资源类别 资源名称

![image-20240123214042193](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240123214042193.png)

用马哥这个账号  RoleBinding  ClusterRole       马哥只拥有Rolebanding所在的命名空间下的权限



可以绑定到 单个用户

也可以绑定到一个组，组内用户全部应用



创建Pod 可以指定 service AccountName  如果们把这个service account 授予的特殊权限 那么用了service account的 pod 都拥有这个特殊权限

![image-20240123215850802](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240123215850802.png)







### dsahboard 认证分级、分级授权

我们要用K8s自带的CA 签署一个证书给 dashboard用 如果我们自己不创建的话他自己会生成一个 但是这个证书k8s不信任



```
(umask 077; openssl genrsa -out dashboard.key 2048)
openssl req -new -key dashboard.key -out dashboard.csr -subj "/O=zed/CN=dashboard"
openssl  x509 -req -in dashboard.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out dashboard.crt -days 365
kubectl create secret generic dashboard -n kube-system --from-file=dashboard.crt=./dashboard.crt --from-file=dashboard.key=./dashb
oard.k
```



dsahboard 在本地登录  用https 登录时需要认证 认证可以使用  kubeconfig  中的账号必须是 Service Account

Service Account     dsahboard 本身是个Pod 去找Api server



我们要通过 dashhboard 创建的Pod 去访问Api Server ，他去访问Api-Server就必须有个账号可以认证到Api

# #问题 为什么访问不了dashboard

```yaml
#这个账号用来管理集群的 所以绑定了集群admin
apiVersion: v1
kind: Secret
metadata:
  name: dashboard-admin-token
  namespace: kubernetes-dashboard
type: Opaque
data:
  token: eW91ci1hY3R1YWwtdG9rZW4tdmFsdWU=

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: dashboard-admin
  namespace: kubernetes-dashboard
  annotations:
    kubernetes.io/service-account.name: dashboard-admin
    kubernetes.io/service-account.secret.name: dashboard-admin-token

---

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: my-dashboard
  namespace: kubernetes-dashboard
subjects:
- kind: ServiceAccount
  name: dashboard-admin
  namespace: kubernetes-dashboard
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
  

修改默认监听端口 不然我们访问不了
kubectl  patch svc kubernetes-dashboard -p '{"spec":{"type":"NodePort"}}' -n kubernetes-dashboard
```



基于conf文件认证登录 可以使用token 或者 ca   获取token 后 解密 然后放在配置i文件中

1. 部署

2. 将Service 改为 Node Port 

   kubectl  patch svc kubernetes-dashboard -p {“spec”：{“type”：“Nodeprot”}} -n kube-system

3. 认证

   认证时的账号必须为ServiceAccount：被dashboard   pod 拿来由kubernetes认证

   token：

   ​		创建 ServerAccount，根据其管理目标，使用role rolebinding 或 culsetrole  clusterrolebinding

   ​		获取到此ServiceAccount的secret，查看secret的详细信息，其中就有token;

   kubeconfig：把ServiceAccount的token 封装成kubeconfig文件

​				创建 ServerAccount，根据其管理目标，使用role rolebinding 或 culsetrole  clusterrolebinding

![image-20240101201725703](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20240101201725703.png)



管理方式

​	命令   ctreate   run     edit

​	命令式配置文件   create -f

​	声明式配置文件   apply   -f 









### 配置网络插件flannel



 1 容器间的通信：同一个pod中多个容器通信 lo

 2 pod通信 pod ip  ---  pod ip

 3 pod与serveice通信： pod ip --- cluster ip

 4 service 与外部集群客户端通信；



CNI:

​     flannel（不支持网络策略）

​					VxLAN   1. vxlan隧道   2. 直接路由 Directrouting

​					host-gw 

calico、canel、kube-router

 解决方案：

​           虚拟网桥、多路复用：MacVLAN 、硬件交换：SR-IOV

   kubelet  直接加载配置文件所谓网络插件 /etc/cni/net.d/

​	 

任何一个部署Kubelet节点都需要部署 CNI、因为kubulet要用它为pod设置网络接口分配网络等（它必须共享宿主机的网络名称空间）





## 调度器 预选策略  优选函数

master 本身是不会运行工作负载的，master就是控制平面，我们的工作节点才是真正意义上的运行工作负载型Pod， 用户在运行Pod时只把请求提交给Api  server，其他的什么都不用关心，因为我们的工作节点被k8s虚拟成了一个庞大的资源池，那么由谁来决定Pod调度呢， 是由master节点上的 Scheduler ，很多调度算法，只不过我们用的是默认的，



用户发起请求创建Pod时，apiserver 确定权限没有问题后，他会把请求交给Scheduler（支持多种调度算法）决定调度到某个节点运行 ，尝试从众多节点中挑选一个合适的节点 结果发给api  然后存到etcd

节点上的kubelet会一直监听api 如果有关当前节点的事件任务且隶属我，尝试着获取api server 定义Pod的yaml文件 配置清单，由api server 去etcd 拿出数据发送给 kubelet ，kubelet去调运行时 runc 构建容器，其中还要考虑我们定义的 镜像拉取策略 ，仓库认证啊 如果由必要还要挂载 volumes

Pod在创建或运行时，是有生命周期的，所以必要的时候我们会给它加上一个SVC，以提供固定的访问入口，SVc实际上并不是一个实实在在的组件，他只是所有节点上相关的IPtables | ipvs

在我们创建Svc时，api 要检查授权，创建sec 依然会存入etcd ，由节点上的Kubeporxy 来他把转为节点上的 ipvs tab 规则



我们的scheduler 必须从节点列表中挑选出一个最佳节点来运行Pod，如何评判最佳

1 Scheduler 节点预选

​			先排除不满足条件的   （资源需求 (最小要求)、资源限额 ） 资源下限，资源上限

​													三种状态，最低，当前，最高，

第一阶段完成后可能还由一堆节点

 2 Scheduler 节点优选

​			根据算法找到优先级找到最佳匹配 

3 select 



比如说有些pod必须运行在满足某些特定条件的节点上(1节点 2节点 3节点) 2节点有SSD

我要把pod运行到节点2上 



节点亲和力（pod调度的时候 更倾向于2节点SSD ）NodeSelect实现

pod亲和力 pod反亲和力 (调度一些pod 我希望这些pod能运行在一起 pod2 和pod1 有亲和力 我就可以跟着他一起去 pod1 )



上述是Pod选择Node   

污点，容忍度是Node可以限定那些Pod可以运行在我这里

可以在某些Node打上污点(这个Node是个罪犯)  

定义Pod容忍度  如果Pod能容忍他是罪犯就可以调度到这里(不容忍的调度不了)

刚开始Node1是罪犯 然后它又变成强奸犯了(Pod 有两种选择 留下、驱逐 )

实现Pod可以满足条件在这里运行但是后来我们又新加了污点Pod 有两种选择 留下、被驱逐（驱逐timeout）

**PodtoleratesNodeNoExecuteTaints：**节点有污点 Pod容忍 就可以调度后来改了 本来可以容忍这些污点 但是Node又设置了新的污点，但Pod不容忍这些新设置的污点 默认继续运行下去 **NodeNoExecuteTaints**就是节点发现Pod容忍不了这些新的污点 会驱逐Pod 调度上去随时会被驱逐  如果pod能容忍被驱逐就调度





污点、容忍度





**虽然数在代码中定义了多种预选策略，但不是每种预选策略都会被使用的，比如他定义了20种但默认就用了10种 可以在安装或者配置Scheduler时启用其他的调度策略**

常见预选策略：

​			CheckNodeCondition：

​			GeneralPredicates：（说是通用但其实它包含多种）

​						HostName：如果我的pod定义了这个 就检查我的node HostName是否和定义的值匹配（次选项不会决定pod调度、我调度到这个节点上这个pod名称没有被占用）

​						PodFitsHostPorts：如果Pod的容器定义了Hostports 绑定在节点某个端口  如果节点上这个端口被占用了就不在这里调度

​						MatchNodeSelector：Node的标签是否能被Pod上Select选择到

​						PodFitsResources：检查Pod的资源需求、节点是否能满足

​			NoDiskConflict(默认不启用)：检查磁盘冲突（pod依赖的存储卷 在此节点是否可用）

​			PodToleratesNodeTaints：检查Pod上Spec.tolerations.它所容忍的污点是否包含节点的全部污点

​			PodtoleratesNodeNoExecuteTaints(默认不启用)：

​			CheckNodeLablePresence(默认不启用)：检查节点上标签是否存在

​			CheckServiceAffinity(默认不启用)：根据当前Pod所属的Servers 已有的其他Pod  把后面的Pod也调度到相同的节点 	

​			比如 servers1 中包含 pod1 pod2 pod3 他们分别在  Node1  Node2  Node3   

​			Node4 Node5 Node6 并没有运行Pod 且属于servers1

​            有两类1.运行server1 pod 的node    2. 没运行server1 pod 的node

​			我们新创建的Pod属于这个Servers1  它就会根据 已有的Pod且他们都属于同一个Servers1

​			此时我运行pod4且属于servers1  它会根据 其他Pod(且同一个servers) 运行的节点 运行那么pod4 就可能运行在node1 node2 node3 上 因为 node4 ... 上没有相同servers的pod

​			将相同Servers的pod对象 尽可能运行在同一个节点

​			MaxEBSVolumeCount：如果你的k8s用到了EBS 

​			CheckVolumeBinding： 检查Pvc绑定

​			NoVolumeZoneConflict：

​			CheckNodeMemoryPressure：检查Node 内存资源是否存在压力过大

​		   CheckNodePiDpressure： 检查Pid资源数量是否不够

​			CheckNodeDiskPressure; 检查节点磁盘IO压力是否过大

​			MatchInterPodAffity：检查节点是否亲和pod



如果调度的时候 第一个预选策略满足 会检查别的预选策略吗  会  要检查所有预选策略满足所有预选策略才可以 有一个不满足就不会选择Node



优选函数：

​		LeastRequested：(CPU(capacity-sum(requested))*10/capcity)









### 高级调度

**污点容忍 亲和反亲和**

​		节点选择器：

​		节点亲和力调度：

affinity  

​		nodeAffinity： 硬亲和  软亲和

​		podAffinity ：我们的目的是把一些pod运行在一起其实我们通过节点亲和力就可以运行在一起 通过节点标签和pod选择。pod和node 标签得完全匹配到 精心布局节点标签

第一个无所谓  第二个Pod根据第一个pod调度 而不是根据我们事先布局好进行调度 这就使我们编排好第一个 其他pod都按照第一个调度即可

把一些pod运行在一起用节点亲和力就能做到但是为了做到我们不得不1精心编排节点2 

以现存的节点作为评判后续pod调度的策略



**在定义PodAffinity和Pod-Anti-Affinity时，必须要有一个判断前提，Pod和Pod在不在同一位置的判断标准**

如果以节点名称为判断标准，每个节点的名字都不一样，亲和 所有Pod都会在一个节点，反亲和 每个节点都会有

如果以地区为判断标准，第一组Pod 运行在北京，以这组Pod定义Anti-affinity为基准，那么pOD就不能运行在Bj



这样会衍生出新的问题，怎么判断后续Pod和第一个Pod在同一个位置或不同位置呢(还是要组织选择器判断)

两个Pod在一个机柜OK  两个Pod在一个服务器OK  在一个地区OK

上面三种都满足亲和力 那我们用那种 必须定义Pod 和pod 在一起亲和力的标准是什么  

**什么叫同一个位置  什么叫不同位**置  pod都运行在一个

比如 我们以节点名称为标准  每个节点的名称都不一样 那就是四个不同位置  所有pod就一定会运行在同一个名节点中

如果以节点名当位置  节点一 name = A     Pod1 运行在A    Pod2也运行在name=A 才满足Pod亲和力   	

如果我们以标签zone=rack

![image-20231231145631000](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20231231145631000.png)



​	podantiAffinity







taint的**effect定**义对Pod排斥效果：effect 当Pod不容忍taints时我们采取什么行为

​		NoSchedule：只影响调度过程对现存的的Pod不造成影响

​		NoExecute：不仅仅影响调度过程，还影响现存Pod，不容忍新污点将被驱逐

​		PreferNoSchedule：不容忍不调度  实在没地方运行也可以调度过来







污点，让节点也可以选择Pod，我提前打个污点，你必须容忍我的污点才能来我这运行

```bash
kubectl explan nodes.spec
kubectl taint --help
kubectl taint node node01  type=GPU:NoShedule
#取消污点
kubectl taint node node01  type-
```



在Pod上定义容忍度有两种形式

​		等值比较  存在性判断

1 比如在Pod 10个 容忍， 节点上有五个污点，必须先检查 10容忍里是否包含节点5个污点，也能有10个容忍 都不匹配节点上的污点，那么就不会调度到该节点上，每一个污点都要被容忍。

```yaml
  spec:
    containers:
    - name: myqpp
      image: busybox:3.19
      ports:
      - name: http
        containerPort: 80
    tolerations:  
    - key: "type"
      operator: "Equal" 
     #operator: "Exists" 只要Key 存在就行
     #value: ""
      value: "GPU"
      effect: "NoSchedule"
      effect: ""
      #tolerationsSeconds: 3600  #要使用这个就必须要用Exists
      
      

#即使我们使用的时Exists 而且Key都完全匹配，但是 effect 不一样也会影响调度结果
比如node1 tyep=1：Noschedule   node2 tyep=2：NoExecute
#我就是要容忍type这污点，不考虑值是什么，也不考虑effect 我都能容忍
节点上只有有type这个Key，value是啥我都容忍，effect效果是啥我也能容忍
```










## 资源限制

容器的资源需求、资源限制

​			requests：需求 最低要求 （至少需要多少）  我要到这里运行你至少有这么多  limits 不管我怎么运行最多都不能超过限制 防止某些进程Bug 吃掉过多资源

​			limits：限制

CPU ：单位指标

​	 一颗逻辑CPU  1CPU=1000 millicores   	500m=0.5核心 

内存：

​		E、P、T、G、M、K	一般都要在这些单位后面加i   i代表1024

​		Ki、Mi、Ti



Pod的资源最低要求requests，节点上必须要满足最低要求Pod才能调度过去。最低要求并不代表我实际运行占用



当Pod先择某个Node 它必须满足我们定义的cpu.requests=200m  不满足limits也可以调度 

Node 把自己运行的所有Pod的requests值 加起来 算出已分配出去的配额

#### requests是定义了能够被调度器作为基本衡量条件的调度值使用的

​	调度器会根据定义的requests资源判断那些Node节点满足此条件





容器中可见资源量、和可用资源量 不是一回事 在容器中看到的是宿主机的资源 而不是限定容器的



Qos Class 自动分配类别

​			Guranteed： Pod中每个容器同时设置了CPU和内存的requests 和 limits 且值一样

​									cpu.limits=cpu.requests       momory.limits=momory.requests  这样设置会自动给归类到Guranteed  而且优先级最高  当系统内资源不够会优先运行这类容器

​			Burstable：

​						Pod至少有一个容器设置了CPU或内存的requests属性 （中等优先级）

​			BestEffort：

​						没有任何一个容器设置了requests 或 limits 属性  （最低优先级）

​	







当系统资源紧缺的时候 BestEffort类别的容器会被优先停止 因为没有限制资源会吃掉系统很多资源

、如果系统资源紧缺且没有BestEffort类别资源优先杀Burstable类Pod  但 Burstable类Pod 特别多 我们先杀 Burstable类Pod中的那个 ？？

已占用和需求的比例  比例大就会优先干掉

##当Pod中有多个容器 只有一个容器设置了资源限制 那其他容器也和这个设置的容器变成一类Qos Class



查看 pod cpu内存存储用量  kubectl  top  pod

我们需要一个运行在集群级别的 角色 替我们采集的pod资源用量等其他信息 top命令是根据这个角色采集的信息所显示 

cAdvisor现在集成在kubelet中  它负责采集单个节点的信息 只能但节点查看

HeapSter 授权

我们在主节点部署一个HeapSter(收集工具 不能持久化------> InfluxDB )  <--- cAdvisor定期汇报给

![1704022390839](C:\Users\50569\Desktop\运维笔记\笔记图片\1704022390839.png)

HeapSter 被废弃了   



#### 资源指标API

1.8以后 资源指标也是API 直接从接口获取  

以前获取资源 通过API server  但 资源指标只能通过 HeapSter和 Cadvisor获取

现在Api Server中包含了这些 想获取资源指标直接请求Api server 即可



资源指标metrics-server

自定义指标：prometheus    k8s-promeetheus-adapter

​			核心指标流水线 ：kubelet、metrics-server、api server  提供的api：CPU内存 pod资源占用 容器磁盘占用

​			监控指标流水线：用户从系统收集各种指标数据并提供给用户 HPA  非核心不能被k8s所解析

metrics-server 是一个外部 API server 和 k8s Api server不一样 它是负责资源指标的Api server 接口

如果用户向调用 他俩 就要在前面加一个聚合器 这样就可以一起调用了

![image-20231231221107920](C:\Users\50569\Desktop\运维笔记\笔记图片\image-20231231221107920.png)





![1704075902300](C:\Users\50569\Desktop\运维笔记\笔记图片\1704075902300.png)







#### Helm仓库   

​		Chart ====  配置清单  ---->   一个应用配置清单 

​		Repository：Charts仓库，https服务器

​		Release；基于某个Char t部署于目标集群上的实例

​		Chart --> Config (值文件)--> Release

程序架构：

​		helm：客户端 管理本地Chart仓库  与Tiller交互   安装查询卸载  

​		Tiller：服务端(部署k8s)  接受helm客户端发来的Chart与config 合并生成部署release 



模板文件	Vanliu文件

![1704079205882](C:\Users\50569\Desktop\运维笔记\笔记图片\1704079205882.png)







```
 Find more information at: https://kubernetes.io/docs/reference/kubectl/

Basic Commands (Beginner):
  create          Create a resource from a file or from stdin
  expose          Take a replication controller, service, deployment or pod and expose it as a new Kubernetes service
  run             Run a particular image on the cluster
  set             Set specific features on objects

Basic Commands (Intermediate):
  explain         Get documentation for a resource
  get             Display one or many resources
  edit            Edit a resource on the server
  delete          Delete resources by file names, stdin, resources and names, or by resources and label selector

Deploy Commands:
  rollout         Manage the rollout of a resource
  scale           Set a new size for a deployment, replica set, or replication controller
  autoscale       Auto-scale a deployment, replica set, stateful set, or replication controller

Cluster Management Commands:
  certificate     Modify certificate resources
  cluster-info    Display cluster information
  top             Display resource (CPU/memory) usage
  cordon          Mark node as unschedulable
  uncordon        Mark node as schedulable
  drain           Drain node in preparation for maintenance
  taint           Update the taints on one or more nodes

Troubleshooting and Debugging Commands:
  describe        Show details of a specific resource or group of resources
  logs            Print the logs for a container in a pod
  attach          Attach to a running container
  exec            Execute a command in a container
  port-forward    Forward one or more local ports to a pod
  proxy           Run a proxy to the Kubernetes API server
  cp              Copy files and directories to and from containers
  auth            Inspect authorization
  debug           Create debugging sessions for troubleshooting workloads and nodes
  events          List events

Advanced Commands:
  diff            Diff the live version against a would-be applied version
  apply           Apply a configuration to a resource by file name or stdin
  patch           Update fields of a resource
  replace         Replace a resource by file name or stdin
  wait            Experimental: Wait for a specific condition on one or many resources
  kustomize       Build a kustomization target from a directory or URL

Settings Commands:
  label           Update the labels on a resource
  annotate        Update the annotations on a resource
  completion      Output shell completion code for the specified shell (bash, zsh, fish, or powershell)

Other Commands:
  api-resources   Print the supported API resources on the server
  api-versions    Print the supported API versions on the server, in the form of "group/version"
  config          Modify kubeconfig files
  plugin          Provides utilities for interacting with plugins
  version         Print the client and server version information

Usage:
  kubectl [flags] [options]

Use "kubectl <command> --help" for more information about a given command.
Use "kubectl options" for a list of global command-line options (applies to all commands).
root@k8s-master01:~# 
```



```bash
kubectl describe  node  node1
```

