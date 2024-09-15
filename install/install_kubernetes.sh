#!/bin/bash
#
#********************************************************************
#Author:            lxj
#QQ:                29308620
#Date:              2020-07-05
#FileName:          install_kubernetes.sh
#Description:       通过kubeadm的安装方式实现Kubernetes的初始准备到安装的全过程
#Copyright (C):     2020 All rights reserved
#********************************************************************

#执行前准备:
#必须确保安装Kubernetes的主机内存至少2G
#必须先下载cri-dockerd_<version>-0.ubuntu-<version>_amd64.deb文件，放在当前目录下
#必须在变量中指定集群中各节点的IP信息
#必须在HOSTS变量中指定集群各节点的主机名称和IP的对应关系
#其它配置可选

. /etc/os-release

KUBE_VERSION="1.27.3"
#KUBE_VERSION="1.26.2"
#KUBE_VERSION="1.25.3"
#KUBE_VERSION="1.25.0"
#KUBE_VERSION="1.24.4"
#KUBE_VERSION="1.24.3"
#KUBE_VERSION="1.24.0"
#KUBE_VERSION="1.22.1"
#KUBE_VERSION="1.17.2"

CRI_DOCKER_VERSION=0.3.10
#CRI_DOCKER_VERSION=0.3.1
#CRI_DOCKER_VERSION=0.2.6
CRI_DOCKER_FILE="cri-dockerd_${CRI_DOCKER_VERSION}.3-0.ubuntu-${UBUNTU_CODENAME}_amd64.deb"
CRI_DOCKER_URL="https://github.com/Mirantis/cri-dockerd/releases/download/v${CRI_DOCKER_VERSION}/${CRI_DOCKER_FILE}"

PAUSE_VERSION=3.9
#PAUSE_VERSION=3.7

IMAGES_URL="registry.aliyuncs.com/google_containers"

KUBE_VERSION2=$(echo $KUBE_VERSION |awk -F. '{print $2}')

#指定修改集群各节点的地址,必须按环境修改

KUBEAPI_IP=10.0.0.171
MASTER1_IP=10.0.0.171
#MASTER2_IP=10.0.0.202
#MASTER3_IP=10.0.0.203
NODE1_IP=10.0.0.172
NODE2_IP=10.0.0.173
NODE3_IP=10.0.0.174
#HARBOR_IP=10.0.0.100

DOMAIN=wang.org

#MASTER1=master1.$DOMAIN
#MASTER2=master2.$DOMAIN
#MASTER3=master3.$DOMAIN
#NODE1=node1.$DOMAIN
#NODE2=node2.$DOMAIN
#NODE3=node3.$DOMAIN
#HA1=ha1.$DOMAIN
#HA2=ha1.$DOMAIN
#HARBOR=harbor.$DOMAIN

#在/etc/hosts文件内容指定主机名和IP对应关系,必须按环境修改

HOSTS="
$KUBEAPI_IP    kubeapi.$DOMAIN kubeapi
$MASTER1_IP    master1.$DOMAIN master1
#$MASTER2_IP    master2.$DOMAIN master2
#$MASTER3_IP    master3.$DOMAIN master3
$NODE1_IP    node1.$DOMAIN node1
$NODE2_IP    node2.$DOMAIN node2
$NODE3_IP    node3.$DOMAIN node3
#$HARBOR_IP    harbor.$DOMAIN harbor
"

#网络配置，默认即可
POD_NETWORK="10.244.0.0/16"
SERVICE_NETWORK="10.96.0.0/12"

LOCAL_IP=`hostname -I|awk '{print $1}'`

COLOR_SUCCESS="echo -e \\033[1;32m"
COLOR_FAILURE="echo -e \\033[1;31m"
END="\033[m"

color () {
    RES_COL=80
    MOVE_TO_COL="echo -en \\033[${RES_COL}G"
    SETCOLOR_SUCCESS="echo -en \\033[1;32m"
    SETCOLOR_FAILURE="echo -en \\033[1;31m"
    SETCOLOR_WARNING="echo -en \\033[1;33m"
    SETCOLOR_NORMAL="echo -en \E[0m"
    echo -n "$1" && $MOVE_TO_COL
    echo -n "["
    if [ $2 = "success" -o $2 = "0" ] ;then
        ${SETCOLOR_SUCCESS}
        echo -n $"  OK  "    
    elif [ $2 = "failure" -o $2 = "1"  ] ;then 
        ${SETCOLOR_FAILURE}
        echo -n $"FAILED"
    else
        ${SETCOLOR_WARNING}
        echo -n $"WARNING"
    fi
    ${SETCOLOR_NORMAL}
    echo -n "]"
    echo 
}

check () {
    if [ ! -f "${CRI_DOCKER_FILE}"  ];then
       color "${CRI_DOCKER_FILE} 文件不存在，退出!" 1
       exit
    fi
    if [ $ID = 'ubuntu' ] && [[ ${VERSION_ID} =~ 2[02].04  ]];then
        true
    else
        color "不支持此操作系统，退出!" 1
        exit
    fi
}

install_prepare () {
    echo "$HOSTS" >> /etc/hosts
    HOST_NAME=$(awk -v ip=$LOCAL_IP '{if($1==ip && $2 !~ "kubeapi")print $2}' /etc/hosts)
    hostnamectl set-hostname $HOST_NAME || { color "主机名配置失败，检查/etc/hosts文件!" 1 ; exit; } 
    swapoff -a
    sed -i '/swap/s/^/#/' /etc/fstab
    color "安装前准备完成!" 0
    sleep 1
}

install_docker () {
    apt update
    apt -y install docker.io || { color "安装Docker失败!" 1; exit 1; }
    cat > /etc/docker/daemon.json <<EOF
{
"registry-mirrors": [
"https://si7y70hh.mirror.aliyuncs.com",
"https://docker.mirrors.ustc.edu.cn",
"https://hub-mirror.c.163.com"
],
"insecure-registries":["harbor.wang.org"],
 "exec-opts": ["native.cgroupdriver=systemd"] 
}
EOF
    systemctl restart docker.service
    docker info && { color "安装Docker成功!" 0; sleep 1; } || { color "安装Docker失败!" 1 ; exit 2; }
}

#Kubernetes-v1.24之前版本无需安装cri-dockerd
install_cri_dockerd () {
    [ $KUBE_VERSION2 -lt 24 ] && return
    if [ ! -e ${CRI_DOCKER_FILE} ];then
        curl -LO $CRI_DOCKER_URL || { color "下载cri-dockerd失败!" 1 ; exit 2; }
    fi
    dpkg -i ${CRI_DOCKER_FILE}
    [ $? -eq 0 ] && color "安装cri-dockerd成功!" 0 || { color "安装cri-dockerd失败!" 1 ; exit 2; }
    sed -i '/^ExecStart/s#$# --pod-infra-container-image registry.aliyuncs.com/google_containers/pause:'$PAUSE_VERSION#   /lib/systemd/system/cri-docker.service
    systemctl daemon-reload 
    systemctl restart cri-docker.service
    [ $? -eq 0 ] && { color "配置cri-dockerd成功!" 0 ; sleep 1; } || { color "配置cri-dockerd失败!" 1 ; exit 2; }
}

install_kubeadm () {
    apt-get update && apt-get install -y apt-transport-https
    curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add - 
    cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF
    apt-get update
    apt-cache madison kubeadm |head
    ${COLOR_FAILURE}"5秒后即将安装: kubeadm-"${KUBE_VERSION}" 版本....."${END}
    ${COLOR_FAILURE}"如果想安装其它版本，请按ctrl+c键退出，修改版本再执行"${END}
    sleep 6

    #安装指定版本
    apt install -y  kubeadm=${KUBE_VERSION}-00 kubelet=${KUBE_VERSION}-00 kubectl=${KUBE_VERSION}-00
    [ $? -eq 0 ] && { color "安装kubeadm成功!" 0;sleep 1; } || { color "安装kubeadm失败!" 1 ; exit 2; }

    #实现kubectl命令自动补全功能    
    kubectl completion bash > /etc/profile.d/kubectl_completion.sh
}

#只有Kubernetes集群的第一个master节点需要执行下面初始化函数
kubernetes_init () {
    if [ $KUBE_VERSION2 -lt 24 ] ;then
        kubeadm init --control-plane-endpoint="kubeapi.$DOMAIN" \
                 --kubernetes-version=v${KUBE_VERSION}  \
                 --pod-network-cidr=${POD_NETWORK} \
                 --service-cidr=${SERVICE_NETWORK} \
                 --token-ttl=0  \
                 --upload-certs \
                 --image-repository=${IMAGES_URL} 
    else
    #Kubernetes-v1.24版本前无需加选项 --cri-socket=unix:///run/cri-dockerd.sock
        kubeadm init --control-plane-endpoint="kubeapi.$DOMAIN" \
                 --kubernetes-version=v${KUBE_VERSION}  \
                 --pod-network-cidr=${POD_NETWORK} \
                 --service-cidr=${SERVICE_NETWORK} \
                 --token-ttl=0  \
                 --upload-certs \
                 --image-repository=${IMAGES_URL} \
                 --cri-socket=unix:///run/cri-dockerd.sock
    fi
    [ $? -eq 0 ] && color "Kubernetes集群初始化成功!" 0 || { color "Kubernetes集群初始化失败!" 1 ; exit 3; }
    mkdir -p $HOME/.kube
    cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    chown $(id -u):$(id -g) $HOME/.kube/config
}

reset_kubernetes() {
    kubeadm reset -f --cri-socket unix:///run/cri-dockerd.sock
    rm -rf  /etc/cni/net.d/  $HOME/.kube/config
}

check 

PS3="请选择编号(1-4): "
ACTIONS="
初始化新的Kubernetes集群
加入已有的Kubernetes集群
退出Kubernetes集群
退出本程序
"
select action in $ACTIONS;do
    case $REPLY in 
    1)
        install_prepare
        install_docker
        install_cri_dockerd
        install_kubeadm
        kubernetes_init
        $COLOR_SUCCESS"Kubernetes集群初始化完毕,还需要在集群中其它主机节点执行加入集群命令：kubeadm join ... --cri-socket=unix:///run/cri-dockerd.sock"${END}
        break
        ;;
    2)
        install_prepare
        install_docker
        install_cri_dockerd
        install_kubeadm
        $COLOR_SUCCESS"加入已有的Kubernetes集群已准备完毕,还需要执行最后一步加入集群的命令 kubeadm join ... --cri-socket=unix:///run/cri-dockerd.sock"${END}
        break
        ;;
    3)
        reset_kubernetes
        break
        ;;
    4)
        exit
        ;;
    esac
done
exec bash