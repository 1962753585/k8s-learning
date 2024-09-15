# 部署Kubernetes集群(v1.29)

## 主机环境预设 

本示例中的Kubernetes集群部署将基于以下环境进行。

- OS: Ubuntu 22.04

- Kubernetes：v1.29.2

- Container Runtime（以下两种方式二选一）：  

- - Docker CE 25.0.3 和 cri-dockerd v0.3.10
  - Continerd.io 1.6.28

### 测试环境说明

测试使用的Kubernetes集群可由一个master主机及一个以上（建议至少两个）node主机组成，这些主机可以是物理服务器，也可以运行于vmware、virtualbox或kvm等虚拟化平台上的虚拟机，甚至是公有云上的VPS主机。

本测试环境将由k8s-master01、k8s-node01、k8s-node02和k8s-node03四个独立的主机组成，它们分别拥有4核心的CPU及8G的内存资源，操作系统环境均为最小化部署的Ubuntu Server 22.04.5 LTS，启用了SSH服务，域名为lxj.com。此外，各主机需要预设的系统环境如下：

（1）借助于chronyd服务（程序包名称chrony）设定各节点时间精确同步；

（2）通过DNS完成各节点的主机名称解析；

（3）各节点禁用所有的Swap设备；

（4）各节点禁用默认配置的iptables防火墙服务；

注意：为了便于操作，后面将在各节点直接以系统管理员root用户进行操作。若用户使用了普通用户，建议将如下各命令以sudo方式运行。

### 设定时钟同步  

若节点可直接访问互联网，安装chrony程序包后，可直接启动chronyd系统服务，并设定其随系统引导而启动。随后，chronyd服务即能够从默认的时间服务器同步时间。

  ~# apt install chrony

  ~# systemctl start chrony.service  

建议用户配置使用本地的的时间服务器，在节点数量众多时尤其如此。存在可用的本地时间服务器时，修改节点的/etc/chrony/chrony.conf配置文件，并将时间服务器指向相应的主机即可，配置格式如下： 

```
server CHRONY-SERVER-NAME-OR-IP iburst
```

### 主机名称解析

出于简化配置步骤的目的，本测试环境使用hosts文件进行各节点名称解析，文件内容如下所示。其中，我们使用kubeapi主机名作为API Server在高可用环境中的专用接入名称，也为控制平面的高可用配置留下便于配置的余地。

> 注意：172.29.7.253是配置在第一个master节点k8s-master01上的第二个地址。在高可用的master环境中，它可作为VIP，由keepalived进行管理。但为了简化本示例先期的部署过程，这里直接将其作为辅助IP地址，配置在k8s-master01节点之上。

| IP地址       | 主机名                            |
| ------------ | --------------------------------- |
| 172.29.7.253 | kubeapi.lxj.com kubeapi           |
| 172.29.7.1   | k8s-master01.lxj.com k8s-master01 |
| 172.29.7.2   | k8s-master02.lxj.com k8s-master02 |
| 172.29.7.3   | k8s-master03.lxj.com k8s-master03 |
| 172.29.7.11  | k8s-node01.lxj.com k8s-node01     |
| 172.29.7.12  | k8s-node02.lxj.com k8s-node02     |
| 172.29.7.13  | k8s-node03.lxj.com k8s-node03     |

> 提示：本示例后续的部署步骤中，并未使用k8s-master02和k8s-master03两个主机来部署高可用的master，只是为了便于后续为其设置高可用环境而保留的预设，因此，它们是可选的主机。

### 禁用Swap设备

部署集群时，kubeadm默认会预先检查当前主机是否禁用了Swap设备，并在未禁用时强制终止部署过程。因此，在主机内存资源充裕的条件下，需要禁用所有的Swap设备，否则，就需要在后文的kubeadm init及kubeadm join命令执行时额外使用相关的选项忽略检查错误。

关闭Swap设备，需要分两步完成。首先是关闭当前已启用的所有Swap设备： 

 ~# swapoff -a

而后编辑/etc/fstab配置文件，注释用于挂载Swap设备的所有行。另外，在Ubuntu 2004及之后版本的系统上，若要彻底禁用Swap，可以需要类似如下命令进一步完成。

~# systemctl --type swap

而后，将上面命令列出的每个设备，使用systemctl mask命令加以禁用。

~# systemctl mask SWAP_DEV

若确需在节点上使用Swap设备，也可选择让kubeam忽略Swap设备的相关设定。我们编辑kubelet的配置文件/etc/default/kubelet，设置其忽略Swap启用的状态错误即可，文件内容如下： 

```
KUBELET_EXTRA_ARGS="--fail-swap-on=false"
```

### 禁用默认的防火墙服务

Ubuntu和Debian等Linux发行版默认使用ufw（Uncomplicated FireWall）作为前端来简化 iptables的使用，处于启用状态时，它默认会生成一些规则以加强系统安全。出于降低配置复杂度之目的，本文选择直接将其禁用。

~# ufw disable

~# ufw status

## 安装程序包

**提示**：

- 以下操作需要在本示例中的所有四台主机上分别进行；
- ***以下两种容器运行时选择其一即可\***；

### 容器运行时一：docker-ce和cri-dockerd

#### 安装并启动docker-ce和cri-dockerd

首先，生成docker-ce相关程序包的仓库，这里以阿里云的镜像服务器为例进行说明：

  ~# apt -y install apt-transport-https ca-certificates curl software-properties-common

  ~# curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | apt-key add -

  ~# add-apt-repository "deb [arch=amd64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"

  ~# apt update

接下来，安装相关的程序包，Ubuntu 22.04上要使用的程序包名称为docker-ce。

  ~# apt install docker-ce

kubelet需要让docker容器引擎使用systemd作为CGroup的驱动，其默认值为cgroupfs，因而，我们还需要编辑docker的配置文件/etc/docker/daemon.json，添加如下内容，其中的registry-mirrors用于指明使用的镜像加速服务。  

```
{
"registry-mirrors": [
  "https://registry.docker-cn.com"
],
"exec-opts": ["native.cgroupdriver=systemd"],
"log-driver": "json-file",
"log-opts": {
  "max-size": "200m"
},
"storage-driver": "overlay2"  
}
```

> 提示：自Kubernetes v1.22版本开始，未明确设置kubelet的cgroup driver时，则默认即会将其设置为systemd。

配置完成后即可启动docker服务，并将其设置为随系统启动而自动引导：

  ~# systemctl daemon-reload

  ~# systemctl start docker.service

  ~# systemctl enable docker.service

#### 为Docker设定使用的代理服务（可选）

Kubeadm部署Kubernetes集群的过程中，默认使用Google的Registry服务registry.k8s.io上的镜像，例如registry.k8s.io/kube-apiserver等，但国内部分用户可能无法访问到该服务。我们也可以使用国内的镜像服务来解决这个问题，例如registry.aliyuncs.com/google_containers。

> 提示：若选择使用国内的镜像服务，则配置代理服务的步骤为可选。

这里简单说明一下设置代理服务的方法。编辑/lib/systemd/system/docker.service文件，在[Service]配置段中添加类似如下内容，其中的PROXY_SERVER_IP和PROXY_PORT要按照实际情况修改。

> 重要提示：节点网络（例如本示例中使用的172.29.0.0/16）、Pod网络（例如本示例中使用的10.244.0.0/16）、Service网络（例如本示例中使用的10.96.0.0/12）以及127网络等本地使用的网络，必须明确定义为不使用所配置的代理，否则将很有可能带来无法预知的本地网络通信故障。

```
# 请将下面配置段中的“$PROXY_SERVER_IP”替换为你的代理服务器地址，将“$PROXY_PORT”替换为你的代理服所监听的端口；
# 另外还要注意所使用的协议http是否同代理服务器提供服务的协议相匹配，如有必要，请自行修改为https；
Environment="HTTP_PROXY=http://$PROXY_SERVER_IP:$PROXY_PORT"
Environment="HTTPS_PROXY=http://$PROXY_SERVER_IP:$PROXY_PORT"
Environment="NO_PROXY=127.0.0.0/8,172.17.0.0/16,172.29.0.0/16,10.244.0.0/16,192.168.0.0/16,10.96.0.0/12,lxj.com,cluster.local"
```

配置完成后需要重载systemd，并重新启动docker服务：

  ~# systemctl daemon-reload

  ~# systemctl restart docker.service

#### 安装cri-dockerd

Kubernetes自v1.24移除了对docker-shim的支持，而Docker Engine默认又不支持CRI规范，因而二者将无法直接完成整合。为此，Mirantis和Docker联合创建了cri-dockerd项目，用于为Docker Engine提供一个能够支持到CRI规范的垫片，从而能够让Kubernetes基于CRI控制Docker 。

> 项目地址：https://github.com/Mirantis/cri-dockerd

cri-dockerd项目提供了预制的二进制格式的程序包，用户按需下载相应的系统和对应平台的版本即可完成安装，这里以Ubuntu 2204 64bits系统环境，以及cri-dockerd目前最新的程序版本v0.3.10为例。

~# curl -LO https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.10/cri-dockerd_0.3.10.3-0.ubuntu-jammy_amd64.deb

~# apt install ./cri-dockerd_0.3.10.3-0.ubuntu-jammy_amd64.deb

完成安装后，相应的服务cri-dockerd.service便会自动启动。我们也可以使用如下命令进行验证，若服务处于Running状态即可进行后续步骤 。

~# systemctl status cri-docker.service

### 容器运行时二：Containerd

Ubuntu 2204上安装Containerd有两种选择，一是Ubuntu系统官方程序包仓库中的containerd，另一个则是Docker社区提供的containerd.io。本文将选择使用后者。

#### 安装并启动Containerd.io

首先，生成containerd.io相关程序包的仓库，这里以阿里云的镜像服务器为例进行说明：

  ~# apt -y install apt-transport-https ca-certificates curl software-properties-common

  ~# curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | apt-key add -

  ~# add-apt-repository "deb [arch=amd64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"

  ~# apt update

接下来，安装相关的程序包，Ubuntu 22.04上要使用的程序包名称为containerd.io。

  ~# apt-get  install  containerd.io

#### 配置Containerd.io

首先，运行如下命令打印默认并保存默认配置

~# mkdir /etc/containerd

~# containerd config default > /etc/containerd/config.toml

接下来，编辑生成的配置文件，完成如下几项相关的配置：

1. 修改containerd使用SystemdCgroup

```
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
  SystemdCgroup = true
```

1. 配置Containerd使用国内Mirror站点上的pause镜像及指定的版本

```
[plugins."io.containerd.grpc.v1.cri"]
sandbox_image = "registry.aliyuncs.com/google_containers/pause:3.9"
```

1. 配置Containerd使用国内的Image加速服务，以加速Image获取

```
[plugins."io.containerd.grpc.v1.cri".registry]
[plugins."io.containerd.grpc.v1.cri".registry.mirrors]
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
    endpoint = ["https://docker.mirrors.ustc.edu.cn", "https://registry.docker-cn.com"]

[plugins."io.containerd.grpc.v1.cri".registry.mirrors."registry.k8s.io"]
endpoint = ["https://registry.aliyuncs.com/google_containers"]
```

1. 配置Containerd使用私有镜像仓库，不存在要使用的私有Image Registry时，本步骤可省略

```
[plugins."io.containerd.grpc.v1.cri".registry]
[plugins."io.containerd.grpc.v1.cri".registry.mirrors]
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."registry.lxj.com"]
    endpoint = ["https://registry.lxj.com"]
```

1. 配置私有镜像仓库跳过tls验证，若私有Image Registry能正常进行tls认证，则本步骤可省略

```
[plugins."io.containerd.grpc.v1.cri".registry.configs]
  [plugins."io.containerd.grpc.v1.cri".registry.configs."registry.lxj.com".tls]
    insecure_skip_verify = true
```

最后，重新启动containerd服务即可。~# systemctl daemon-reload ~# systemctl restart containerd 

#### 配置crictl客户端

安装containerd.io时，会自动安装命令行客户端工具crictl，该客户端通常需要通过正确的unix sock文件才能接入到containerd服务。编辑配置文件/etc/crictl.yaml，添加如下内容即可。

```
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: true
```

随后即可正常使用crictl程序管理Image、Container和Pod等对象。另外，containerd.io还有另一个名为ctr的客户端程序可以，其功能也更为丰富。

### 安装kubelet、kubeadm和kubectl

自 v1.28版本开始，Kubernetes官方变更了仓库的存储路径及使用方式（不同的版本将会使用不同的仓库），并提供了向后兼容至v1.24版本。因此，对于v1.24及之后的版本来说，可以使用如下有别于传统配置的方式来安装相关的程序包。以本示例中要安装的v1.29版本为例来说，配置要使用的程序包仓库，需要使用的命令如下。如若需要安装其它版本，则将下面命令中的版本号“v1.29”予以替换即可。

 ~# apt-get update && apt-get install -y apt-transport-https

 ~#  curl -fsSL https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.29/deb/Release.key |   gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

 ~# echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.29/deb/ /" |   tee /etc/apt/sources.list.d/kubernetes.list

 ~# apt-get update

接下来，运行如下命令安装kubelet、kubeadm和kubectl等程序包。

 ~# apt-get install -y kubelet kubeadm kubectl

安装完成后，要确保kubeadm等程序文件的版本，这将也是后面初始化Kubernetes集群时需要明确指定的版本号。

## 整合kubelet和cri-dockerd（仅cri-dockerd需要）

仅支持CRI规范的kubelet需要经由遵循该规范的cri-dockerd完成与docker-ce的整合。**该步骤仅使用docker-ce和cri-dockerd运行时的场景中需要配置。**

### 配置cri-dockerd

配置cri-dockerd，确保其能够正确加载到CNI插件。编辑/usr/lib/systemd/system/cri-docker.service文件，确保其[Service]配置段中的ExecStart的值类似如下内容。

```
ExecStart=/usr/bin/cri-dockerd --container-runtime-endpoint fd:// --network-plugin=cni --cni-bin-dir=/opt/cni/bin --cni-cache-dir=/var/lib/cni/cache --cni-conf-dir=/etc/cni/net.d --pod-infra-container-image=registry.aliyuncs.com/google_containers/pause:3.9
```

需要添加的各配置参数（各参数的值要与系统部署的CNI插件的实际路径相对应）：

- --network-plugin：指定网络插件规范的类型，这里要使用CNI；
- --cni-bin-dir：指定CNI插件二进制程序文件的搜索目录； 
- --cni-cache-dir：CNI插件使用的缓存目录； 
- --cni-conf-dir：CNI插件加载配置文件的目录； 
- **--pod-infra-container-image**：Pod中的puase容器要使用的Image，默认为registry.k8s.io上的pause仓库中的镜像；不能直接获取到该Image时，需要明确指定为从指定的位置加载，例如“registry.aliyuncs.com/google_containers/pause:3.9”。

配置完成后，重载并重启cri-docker.service服务。

~# systemctl daemon-reload && systemctl restart cri-docker.service

### 配置kubelet

配置kubelet，为其指定cri-dockerd在本地打开的Unix Sock文件的路径，该路径一般默认为“/run/cri-dockerd.sock“。编辑文件/etc/sysconfig/kubelet，为其添加 如下指定参数。

> 提示：若/etc/sysconfig目录不存在，则需要先创建该目录。

```
KUBELET_KUBEADM_ARGS="--container-runtime=remote --container-runtime-endpoint=/run/cri-dockerd.sock"
```

需要说明的是，该配置也可不进行，而是直接在后面的各kubeadm命令上使用“--cri-socket unix:///run/cri-dockerd.sock”选项。

## 初始化第一个主节点

该步骤开始尝试构建Kubernetes集群的master节点，配置完成后，各worker节点直接加入到集群中的即可。需要特别说明的是，由kubeadm部署的Kubernetes集群上，集群核心组件kube-apiserver、kube-controller-manager、kube-scheduler和etcd等均会以静态Pod的形式运行，它们所依赖的镜像文件默认来自于registry.k8s.io这一Registry服务之上。但我们无法直接访问该服务，常用的解决办法有如下两种，本示例将选择使用更易于使用的前一种方式。

- 使用能够到达该服务的代理服务；

- 使用国内的镜像服务器上的服务，例如registry.aliyuncs.com/google_containers等。

  > 若是在马哥教育私有云上部署，还可以使用registry.lxj.com/google_containers。

### 初始化master节点（在master01上完成如下操作）

在运行初始化命令之前先运行如下命令单独获取相关的镜像文件，而后再运行后面的kubeadm init命令，以便于观察到镜像文件的下载过程。

> 提示：若您选择使用的是docker-ce和cri-dockerd这一容器运行时环境，本文后续内容中使用的kubeadm命令，都需要额外添加“--cri-socket=unix:///var/run/cri-docker.sock”选项，以明确指定其所要关联的容器运行时。这是因为，docker-ce和cri-dockerd都提供了unix sock类型的socket地址，这会导致kubeadm在自动扫描和加载该类文件时无法自动判定要使用哪个文件。而使用containerd.io运行时，则不存在该类问题，因而无须明确指定。

~# kubeadm config images list 

上面的命令会列出类似如下的Image信息，由如下的命令结果可以看出，相关的Image都来自于registry.k8s.io，该服务上的Image通常需要借助于代理服务才能访问到。

```
registry.k8s.io/kube-apiserver:v1.29.2
registry.k8s.io/kube-controller-manager:v1.29.2
registry.k8s.io/kube-scheduler:v1.29.2
registry.k8s.io/kube-proxy:v1.29.2
registry.k8s.io/coredns/coredns:v1.11.1
registry.k8s.io/pause:3.9
registry.k8s.io/etcd:3.5.10-0
```

若需要从国内的Mirror站点下载Image，还需要在命令上使用“--image-repository”选项来指定Mirror站点的相关URL。例如，下面的命令中使用了该选项将Image Registry指向国内可用的Aliyun的镜像服务，其命令结果显示的各Image也附带了相关的URL。

~# kubeadm config images list --image-repository=registry.aliyuncs.com/google_containers

```
registry.aliyuncs.com/google_containers/kube-apiserver:v1.29.2
registry.aliyuncs.com/google_containers/kube-controller-manager:v1.29.2
registry.aliyuncs.com/google_containers/kube-scheduler:v1.29.2
registry.aliyuncs.com/google_containers/kube-proxy:v1.29.2
registry.aliyuncs.com/google_containers/coredns:v1.11.1
registry.aliyuncs.com/google_containers/pause:3.9
registry.aliyuncs.com/google_containers/etcd:3.5.10-0
```

运行下面的命令即可下载需要用到的各Image。需要注意的是，如果需要从国内的Mirror站点下载Image，同样需要在命令上使用“--image-repository”选项来指定Mirror站点的相关URL。

~# kubeadm config images pull --image-repository=registry.aliyuncs.com/google_containers

```
[config/images] Pulled registry.aliyuncs.com/google_containers/kube-apiserver:v1.29.2
[config/images] Pulled registry.aliyuncs.com/google_containers/kube-controller-manager:v1.29.2
[config/images] Pulled registry.aliyuncs.com/google_containers/kube-scheduler:v1.29.2
[config/images] Pulled registry.aliyuncs.com/google_containers/kube-proxy:v1.29.2
[config/images] Pulled registry.aliyuncs.com/google_containers/coredns:v1.11.1
[config/images] Pulled registry.aliyuncs.com/google_containers/pause:3.9
[config/images] Pulled registry.aliyuncs.com/google_containers/etcd:3.5.10-0
```

而后即可进行master节点初始化。kubeadm init命令支持两种初始化方式，一是通过命令行选项传递关键的部署设定，另一个是基于yaml格式的专用配置文件，后一种允许用户自定义各个部署参数，在配置上更为灵活和便捷。下面分别给出了两种实现方式的配置步骤，建议读者采用第二种方式进行。

#### 初始化方式一

运行如下命令完成k8s-master01节点的初始化。需要注意的是，若使用docker-ce和cri-dockerd运行时，则还要在如下命令上明确配置使用“--cri-socket=unix:///var/run/cri-dockerd.sock”选项。

```
~# kubeadm init \        
      --control-plane-endpoint="kubeapi.lxj.com" \
      --kubernetes-version=v1.29.2 \
      --pod-network-cidr=10.244.0.0/16 \
      --service-cidr=10.96.0.0/12 \
      --token-ttl=0 \
      --upload-certs
```

命令中的各选项简单说明如下： 

- --image-repository：指定要使用的镜像仓库，默认为registry.k8s.io；

- --kubernetes-version：kubernetes程序组件的版本号，它必须要与安装的kubelet程序包的版本号相同；

- --control-plane-endpoint：控制平面的固定访问端点，可以是IP地址或DNS名称，会被用于集群管理员及集群组件的kubeconfig配置文件的API Server的访问地址；单控制平面部署时可以不使用该选项；

- --pod-network-cidr：Pod网络的地址范围，其值为CIDR格式的网络地址，通常，Flannel网络插件的默认为10.244.0.0/16，Project Calico插件的默认值为192.168.0.0/16，而Cilium的默认值为10.0.0.0/8；

- --service-cidr：Service的网络地址范围，其值为CIDR格式的网络地址，kubeadm使用的默认为10.96.0.0/12；通常，仅在使用Flannel一类的网络插件需要手动指定该地址；

- --apiserver-advertise-address：apiserver通告给其他组件的IP地址，一般应该为Master节点的用于集群内部通信的IP地址，0.0.0.0表示节点上所有可用地址；

- --token-ttl：共享令牌（token）的过期时长，默认为24小时，0表示永不过期；为防止不安全存储等原因导致的令牌泄露危及集群安全，建议为其设定过期时长。未设定该选项时，在token过期后，若期望再向集群中加入其它节点，可以使用如下命令重新创建token，并生成节点加入命令。

  ```
  kubeadm token create --print-join-command
  ```

> 提示：无法访问registry.k8s.io时，同样可以在上面的命令中使用“--image-repository=registry.aliyuncs.com/google_containers”选项，以便从国内的镜像服务中获取各Image；

> 注意：若各节点未禁用Swap设备，还需要附加选项“--ignore-preflight-errors=Swap”，从而让kubeadm忽略该错误设定；

#### 初始化方式二

kubeadm也可通过配置文件加载配置，以定制更丰富的部署选项。获取内置的初始配置文件的命令

```
kubeadm config print init-defaults
```

下面的配置示例，是以上面命令的输出结果为框架进行修改的，它明确定义了kubeProxy的模式为ipvs，并支持通过修改imageRepository的值修改获取系统镜像时使用的镜像仓库。

```
apiVersion: kubeadm.k8s.io/v1beta3
bootstrapTokens:
- groups:
- system:bootstrappers:kubeadm:default-node-token
token: lxj.comc4mu9kzd5q7ur
ttl: 24h0m0s
usages:
- signing
- authentication
kind: InitConfiguration
localAPIEndpoint:
# 这里的地址即为初始化的控制平面第一个节点的IP地址；
advertiseAddress: 172.29.7.1
bindPort: 6443
nodeRegistration:
# 注意，使用docker-ce和cri-dockerd时，要启用如下配置的cri socket文件的路径；
#criSocket: unix:///run/cri-dockerd.sock
imagePullPolicy: IfNotPresent
# 第一个控制平面节点的主机名称；
name: k8s-master01.lxj.com
taints:
- effect: NoSchedule
  key: node-role.kubernetes.io/master
- effect: NoSchedule
  key: node-role.kubernetes.io/control-plane
---
apiServer:
timeoutForControlPlane: 4m0s
# 将下面配置中的certSANS列表中的值，修改为客户端接入API Server时可能会使用的各类目标地址；
certSANs:
- kubeapi.lxj.com
- 172.29.7.1
- 172.29.7.2
- 172.29.7.3
- 172.29.7.253
apiVersion: kubeadm.k8s.io/v1beta3
# 控制平面的接入端点，我们这里选择适配到kubeapi.lxj.com这一域名上；
controlPlaneEndpoint: "kubeapi.lxj.com:6443"
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controllerManager: {}
dns: {}
etcd:
local:
  dataDir: /var/lib/etcd
imageRepository: registry.aliyuncs.com/google_containers
kind: ClusterConfiguration
kubernetesVersion: v1.29.2
networking:
# 集群要使用的域名，默认为cluster.local
dnsDomain: cluster.local
# service网络的地址
serviceSubnet: 10.96.0.0/12
# pod网络的地址，flannel网络插件默认使用10.244.0.0/16
podSubnet: 10.244.0.0/16
scheduler: {}
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
# 用于配置kube-proxy上为Service指定的代理模式，默认为iptables；
mode: "ipvs"
```

将上面的内容保存于配置文件中，例如kubeadm-config.yaml，而后执行如下命令即能实现类似前一种初始化方式中的集群初始配置，但这里将Service的代理模式设定为了ipvs。

  ~# kubeadm init --config kubeadm-config.yaml --upload-certs

### 初始化完成后的操作步骤

对于Kubernetes系统的新用户来说，无论使用上述哪种方法，命令运行结束后，请记录最后的kubeadm join命令输出的最后提示的操作步骤。下面的内容是需要用户记录的一个命令输出示例，它提示了后续需要的操作步骤。

```
# 下面是成功完成第一个控制平面节点初始化的提示信息及后续需要完成的步骤
Your Kubernetes control-plane has initialized successfully!

# 为了完成初始化操作，管理员需要额外手动完成几个必要的步骤
To start using your cluster, you need to run the following as a regular user:

# 第1个步骤提示， Kubernetes集群管理员认证到Kubernetes集群时使用的kubeconfig配置文件
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 我们也可以不做上述设定，而使用环境变量KUBECONFIG为kubectl等指定默认使用的kubeconfig；
Alternatively, if you are the root user, you can run:

export KUBECONFIG=/etc/kubernetes/admin.conf

# 第2个步骤提示，为Kubernetes集群部署一个网络插件，具体选用的插件则取决于管理员；
You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
https://kubernetes.io/docs/concepts/cluster-administration/addons/

# 第3个步骤提示，向集群添加额外的控制平面节点，但本文会略过该步骤，并将在其它文章介绍其实现方式。
You can now join any number of the control-plane node running the following command on each as root:

# 在部署好kubeadm等程序包的其他控制平面节点上以root用户的身份运行类似如下命令，
# 命令中的hash信息对于不同的部署环境来说会各不相同；该步骤只能在其它控制平面节点上执行；
# 提示：与cri-dockerd结合使用docker-ce作为container runtime时，通常需要为下面的命令
#     额外附加“--cri-socket unix:///run/cri-dockerd.sock”选项；
kubeadm join kubeapi.lxj.com:6443 --token lxj.comc4mu9kzd5q7ur \
      --discovery-token-ca-cert-hash sha256:2f8028974b3830c5cb13163e06677f52711282b38ee872485ea81992c05d8a78 \
      --control-plane --certificate-key e01e6227c40c076dcebd1483d09191207da018610aab48fc240fa74a6ccefb80

# 因为在初始化命令“kubeadm init”中使用了“--upload-certs”选项，因而初始化过程会自动上传添加其它Master时用到的数字证书等信息；
# 出于安全考虑，这些内容会在2小时之后自动删除；
Please note that the certificate-key gives access to cluster sensitive data, keep it secret!
As a safeguard, uploaded-certs will be deleted in two hours; If necessary, you can use
"kubeadm init phase upload-certs --upload-certs" to reload certs afterward.

# 第4个步骤提示，向集群添加工作节点
Then you can join any number of worker nodes by running the following on each as root:

# 在部署好kubeadm等程序包的各工作节点上以root用户运行类似如下命令；
# 提示：与cri-dockerd结合使用docker-ce作为container runtime时，通常需要为下面的命令
#     额外附加“--cri-socket unix:///run/cri-dockerd.sock”选项；
kubeadm join kubeapi.lxj.com:6443 --token lxj.comc4mu9kzd5q7ur \
      --discovery-token-ca-cert-hash sha256:2f8028974b3830c5cb13163e06677f52711282b38ee872485ea81992c05d8a78
```

另外，kubeadm init命令完整参考指南请移步官方文档，地址为https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/。

### 设定kubectl

kubectl是kube-apiserver的命令行客户端程序，实现了除系统部署之外的几乎全部的管理操作，是kubernetes管理员使用最多的命令之一。kubectl需经由API server认证及授权后方能执行相应的管理操作，kubeadm部署的集群为其生成了一个具有管理员权限的认证配置文件/etc/kubernetes/admin.conf，它可由kubectl通过默认的“$HOME/.kube/config”的路径进行加载。当然，用户也可在kubectl命令上使用--kubeconfig选项指定一个别的位置。

下面复制认证为Kubernetes系统管理员的配置文件至目标用户（例如当前用户root）的家目录下：

~# mkdir ~/.kube

~# cp /etc/kubernetes/admin.conf  ~/.kube/config

### 部署网络插件

Kubernetes系统上Pod网络的实现依赖于第三方插件进行，这类插件有近数十种之多，较为著名的有flannel、calico、canal和kube-router等，简单易用的实现是为CoreOS提供的flannel项目。下面的命令用于在线部署flannel至Kubernetes系统之上，我们需要在初始化的第一个master节点k8s-master01上运行如下命令，以完成部署。

~# kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

而后使用如下命令确认其输出结果中Pod的状态为“Running”，类似如下命令及其输入的结果所示：

~# kubectl get pods -n kube-flannel

上述命令应该会得到类似如下输出，这表示kube-flannel已然正常运行。

```
NAME                   READY   STATUS   RESTARTS   AGE
kube-flannel-ds-65l9z   1/1     Running   0         15s
```

### 验证master节点已经就绪

~# kubectl get nodes

上述命令应该会得到类似如下输出，这表示k8s-master01节点已经就绪。

```
NAME                     STATUS   ROLES           AGE   VERSION
k8s-master01.lxj.com   Ready   control-plane   6m   v1.29.2
```

若准备有其它的master节点，以构建高可用的控制平面，可按照初始化控制平面第一个节点时输出的信息，在额外的master节点上运行添加命令，以完成控制平面其它节点的添加。相关的命令是形如下在的相关信息。

```bash
kubeadm join kubeapi.lxj.com:6443 --token lxj.comc4mu9kzd5q7ur \
       --discovery-token-ca-cert-hash sha256:2f8028974b3830c5cb13163e06677f52711282b38ee872485ea81992c05d8a78 \
       --control-plane --certificate-key e01e6227c40c076dcebd1483d09191207da018610aab48fc240fa74a6ccefb80
```

本示例中将不再演示如何添加这类的节点。

## 添加节点到集群中

下面的两个步骤，需要分别在k8s-node01、k8s-node02和k8s-node03上各自完成。

1、若未禁用Swap设备，编辑kubelet的配置文件/etc/default/kubelet，设置其忽略Swap启用的状态错误，内容如下： KUBELET_EXTRA_ARGS="--fail-swap-on=false"

2、将节点加入第二步中创建的master的集群中，要使用主节点初始化过程中记录的kubeadm join命令。再次提示，若使用docker-ce和cri-dockerd运行时环境，则需要在如下命令中额外添加“--cri-socket=unix:///var/run/cri-dockerd.sock”选项。

```
~# kubeadm join kubeapi.lxj.com:6443 --token lxj.comc4mu9kzd5q7ur \
      --discovery-token-ca-cert-hash sha256:2f8028974b3830c5cb13163e06677f52711282b38ee872485ea81992c05d8a78
```

> 提示：在未禁用Swap设备的情况下，还需要为上面的命令额外附加“--ignore-preflight-errors=Swap”选项。

### 验证节点添加结果

在每个节点添加完成后，即可通过kubectl验证添加结果。下面的命令及其输出是在所有的三个节点均添加完成后运行的，其输出结果表明三个Worker Node已经准备就绪。

~# kubectl get nodes

```
NAME                     STATUS   ROLES           AGE   VERSION
k8s-master01.lxj.com   Ready   control-plane   10m   v1.29.2
k8s-node01.lxj.com     Ready   <none>         9m   v1.29.2
k8s-node02.lxj.com     Ready   <none>         7m   v1.29.2
k8s-node03.lxj.com     Ready   <none>         5m   v1.29.2
```

### 测试应用编排及服务访问

到此为止，一个master，并附带有三个worker的kubernetes集群基础设施已经部署完成，用户随后即可测试其核心功能。例如，下面的命令可将demoapp以Pod的形式编排运行于集群之上，并通过在集群外部进行访问：

~# kubectl create deployment demoapp --image=ikubernetes/demoapp:v1.0 --replicas=3

~# kubectl create service nodeport demoapp --tcp=80:80

而后，使用如下命令了解Service对象demoapp使用的NodePort，以便于在集群外部进行访问：

~# kubectl get svc -l app=demoapp  

```
NAME     TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)       AGE
demoapp   NodePort   10.100.84.12   <none>       80:30622/TCP   2s
```

demoapp是一个web应用，因此，用户可以于集群外部通过“http://NodeIP:30622”这个URL访问demoapp上的应用，例如于集群外通过浏览器访问“http://172.29.7.11:30622”。

我们也可以在Kubernetes集群上启动一个临时的客户端，对demoapp服务发起访问测试。

~# kubectl run client-$RANDOM --image=ikubernetes/admin-box:v1.2 --rm --restart=Never -it --command -- /bin/bash

而后，在打开的交互式接口中，运行如下命令，对demoapp.default.svc服务发起访问请求，验证其负载均衡的效果。

root@client-3021 ~# while true; do curl demoapp.default.svc; sleep 1; done

该命令会持续返回类似如下的结果，这可以证明CoreDNS名称解析功能，以及Service的服务发现及负载均衡功能均已经正常工作。

```
iKubernetes demoapp v1.0 !! ClientIP: 10.244.1.3, ServerName: demoapp-7c58cd6bb-vf5ms, ServerIP: 10.244.3.3!
iKubernetes demoapp v1.0 !! ClientIP: 10.244.1.3, ServerName: demoapp-7c58cd6bb-z98hz, ServerIP: 10.244.2.3!
iKubernetes demoapp v1.0 !! ClientIP: 10.244.1.3, ServerName: demoapp-7c58cd6bb-9brsb, ServerIP: 10.244.1.2!
……
```

运行下面的命令，清理部署的测试应用。

~# kubectl delete deployments/demoapp services/demoapp

## 部署Add-ons（可选步骤）

### MetalLB

MetalLB是一款开源的云原生负载均衡器实现，可以在基于裸金属服务器或虚拟机的Kubernetes 环境中使用LoadBalancer类型的Service对外暴露服务。

MetalLB核心功能的实现依赖于两种机制：

- 地址分配：基于指定的地址池进行分配；
- 对外公告：让集群外部的网络了解新分配的IP地址，MetalLB使用ARP、NDP或BGP实现

#### 部署MetalLB

kube-proxy工作于ipvs模式时，必须要使用严格ARP（StrictARP）模式，因此，部署MetalLB之前，需要事先运行如下命令，配置kube-proxy。

~# kubectl get configmap kube-proxy -n kube-system -o yaml | sed -e "s/strictARP: false/strictARP: true/" | kubectl apply -f - -n kube-system

随后，运行如下命令，即可部署MetalLB至Kubernetes集群，本示例中部署的版本为“v0.14.3”。

~# kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml

MetalLB默认将其各组件部署于metallb-system名称空间下，运行如下命令，打印各Pod的运行状态 。

~# kubectl get pods -n metallb-system

```
NAME                         READY   STATUS   RESTARTS   AGE
controller-5f56cd6f78-zckt7   1/1     Running   0         29s
speaker-b69rz                 1/1     Running   0         29s
speaker-d8rqm                 1/1     Running   0         29s
speaker-jj9x5                 1/1     Running   0         29s
speaker-rf44t                 1/1     Running   0         29s
```

待如上各Pod转为Running状态后，即可进行后续的步骤。

#### 创建地址池

MetalLB提供了名为IPAddressPool的自定义资源类型，它允许用户以声明式方式定义用于分给LoadBalancer的IP地址范围。下面是一个IPAddressPool资源示例，它所选定的地址范围是当前集群节点网络中的一个空闲地址空间。

```
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
name: localip-pool
namespace: metallb-system
spec:
addresses:
- 172.29.7.51-172.29.7.80
autoAssign: true
avoidBuggyIPs: true
```

#### 创建二层公告机制

将地址池中的某地址配置在某节点上，并以externalIP的形式分配给某LoadBalancer使用之前，需要向整个本地网络通告该地址相关的ARP地址信息。具体使用时，请将如下示例中的interfaces修改为集群中各节点上实际使用的接口名称。

```
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
name: localip-pool-l2a
namespace: metallb-system
spec:
ipAddressPools:
- localip-pool
interfaces:
- enp1s0
```

#### 创建LB Service进行测试

创建Deployment和LoadBalancer Service，测试地址池是否已经能正常向Service分配LoadBalancer IP。

```bash
kubectl create deployment demoapp --image=ikubernetes/demoapp:v1.0 --replicas=2
kubectl create service loadbalancer demoapp --tcp=80:80
```

运行如下命令，查看service资源对象demoapp上是否自动获得了External IP。

```bash
kubectl get service demoapp
```

其结果应该类似如下内容，这表明EIP地址分配已经能够正常进行。

```
NAME     TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)       AGE
demoapp   LoadBalancer   10.102.82.80   172.29.7.51   80:30992/TCP   10s
```

随后，即可于集群外部的客户端上通过IP地址“172.29.7.51”对demoapp服务发起访问测试。

#### 清理

删除部署的测试目的Deployment和LoadBalancer Server。

```bash
kubectl delete service/demoapp deployment/demoapp
```

### Ingress Nginx

Ingress Nginx是由Kubernetes社区维护的Ingress Controller的实现。以v1.9.6版本为例，运行下面的命令，即可完成部署。需要特别说明的是，Ingress Nginx的相关Image位于registry.k8s.io服务上，该服务通常需要通过代理才能进行访问。

~# kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.6/deploy/static/provider/cloud/deploy.yaml

运行如下命令，确认部署的结果状态。后面的命令结果中，ingress-nginx-controller相关的Pod转为Runing状态，即为部署成功。

~# kubectl get pods -n ingress-nginx

```
NAME                                     READY   STATUS     RESTARTS   AGE
ingress-nginx-admission-create-rqj7z     0/1     Completed   0         66s
ingress-nginx-admission-patch-mrc6m     0/1     Completed   2         66s
ingress-nginx-controller-6f4b9c5-w9bt7   1/1     Running     0         66s
```

运行下面的命令，查看相关Service的状态信息。如果部署了MetalLB或OpenELB一类的LoadBalancer Service的实现，其External-IP应该可以获得EIP可用分配范围内的一个地址，类似如下命令及其结果所示。

~# kubectl get services -n ingress-nginx

```
NAME                                 TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                     AGE
ingress-nginx-controller             LoadBalancer   10.108.78.197   172.29.7.51   80:32375/TCP,443:32713/TCP   2m1s
ingress-nginx-controller-admission   ClusterIP     10.110.114.205   <none>       443/TCP                     2m1s
```

随后，我们即可透过Ingress向集群外部发布应用。

### Metrics Server

Metrics Server用于为Kubernetes集群提供核心指标API。它存在单实例部署和高可用部署两种模式，相应的资源配置文件名称分别为components.yaml和high-availability-1.21+.yaml。Metrics Server的Image位于registry.k8s.io服务上，请确保Kubernetes集群的各节点能够正常访问到该服务。

以v0.7.0版本为例，运行下面的命令，即可部署高可用模式的Metrics Server。

~# kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.7.0/high-availability-1.21+.yaml

> 提示：Metrics Server基于https协议从各节点收集指标，同各节点的10250端口建立通信连接之前，它会验证各节点的数字证书。这些数字证书中的CN通常是节点名称，因此，若Kubernetes集群上的Pod无法通过DNS服务解析到各节点的主机名，该验证将返回失败信息，并导致指标收集操作无法完成。此种情况下，可以通过修改资源配置文件中启动Metrics Server进行的命令行选项来完成。
>
> 具体方法是，首先将“--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname”选项修改为“--kubelet-preferred-address-types=InternalIP”，或额外添加“--kubelet-insecure-tls”选项。修改后的配置片断示例如下。
>
> ```yaml
>   spec:
>     containers:
>     - args:
>       - --cert-dir=/tmp
>       - --secure-port=4443
>       - --kubelet-preferred-address-types=InternalIP
>       - --kubelet-insecure-tls
>       - --kubelet-use-node-status-port
>       - --metric-resolution=15s
>       image: registry.lxj.com/metrics-server/metrics-server:v0.7.0
> ```

运行如下命令，确认部署的结果状态。后面的命令结果中，metrics-server相关的Pod转为Runing状态，即为部署成功。

~# kubectl get pods -n kube-system -l k8s-app=metrics-server

```
NAME                             READY   STATUS   RESTARTS   AGE
metrics-server-69d8c57977-jzb5f   1/1     Running   0         1m
metrics-server-69d8c57977-mj7c9   1/1     Running   0         1m
```

待各Pod转为Running状态后，即可运行如下命令，打印相应的API群组信息，其中会新增形如“metrics.k8s.io/v1beta1”的群组及版本标识。

~# kubectl api-versions

随后，即可运行下面的命令，了解Kubernetes集群中各节点的指标数据信息。而将命令中的nodes替换为pods，即可打印Pods相关的资源指标数据。

~# kubectl top nodes

```
NAME                     CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%  
k8s-master01.lxj.com   133m         1%     814Mi           10%      
k8s-node01.lxj.com     42m         0%     451Mi           6%        
k8s-node02.lxj.com     38m         0%     378Mi           5%        
k8s-node03.lxj.com     41m         0%     550Mi           7%        
```

### Kuboard

Kuboard是用于管理多Kubernetes集群的开源UI。以目前最新的v3.5版本为例，运行下面的命令，即可完成部署。

~# kubectl apply -f https://raw.githubusercontent.com/iKubernetes/learning-k8s/master/Kuboard/deploy.yaml

> 提示：Kuboard提供了适配到多种不同的平台的部署方式。出于简化部署过程的目的，本示例中使用了修改后的自定义配置文件，它会将Kubarod部署到名为kuboard的名称空间中。

运行如下命令，确认部署的结果状态。后面的命令结果中，kuboard相关的Pod转为Runing状态，即为部署成功。

~# kubectl get pods -n kuboard

```
kuboard-v3-b8568474c-4fb25         1/1     Running   0               2m
```

运行下面的命令，查看相关Service的状态信息。

~# kubectl get services -n kuboard

```
NAME             TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)                                       AGE
kuboard-v3       NodePort   10.108.193.34   <none>       80:30080/TCP,10081:30081/TCP,10081:30081/UDP   2d
```

若Kubernetes集群上部署有Ingress Controller的实现，例如前面示例中的Ingress Nginx，则运行如下命令，即可创建Ingress以暴露Kuboard至集群外部。

~# kubectl create ingress kuboard --rule="kuboard.lxj.com/*"=kuboard-v3:80 --class='nginx' --namespace=kuboard

接下来，运行下面的命令，查看相关Ingress的状态信息。

~# kubectl get ingresses -n kuboard

```
NAME     CLASS     HOSTS               ADDRESS       PORTS   AGE
kuboard   nginx   kuboard.lxj.com   172.29.7.51   80     71s
```

部署完成后，确认kuboard.lxj.com名称解析到了172.29.7.51（Ingress Nginx Service的External IP），即可在浏览器上使用该域名进行访问。其默认的用户和密码为“admin/Kuboard123”。