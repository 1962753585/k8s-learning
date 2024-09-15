

## 前置工作

**准备NFS服务器**

```yaml
#10.0.0.203安装nfs-kernel-server
[root@ubuntu2204 ~]#apt update && apt install nfs-kernel-server

#创建共享目录
mkdir -pv /data/nfs/jpress
导入jpress源码到服务器
#配置共享
vim /etc/exports
/data/nfs/jpress 10.0.0.0/24(rw,fsid=0,async,no_subtree_check,no_auth_nlm,insecure,no_root_squash)
#重载
exportfs -afv
```



```yaml
#kubernetes节点安装NFS客户端nfs-common
apt update && apt install nfs-common
```





**安装镜像构建环境**

```bash
apt install docker.io
#登录镜像仓库
docker login --username=NightQAQ registry.cn-beijing.aliyuncs.com
```





Dockerfile编译nginx，Docker 多阶段构建把nginx导出来，然后优化nginx配置，打成镜像，（具体配置用confgmap） (创建service 暴露到外面)

Dockerfile 编译安装 jkd tomcat，优化参数， 把NFS挂载到tomcar的目录上，然后再NFS服务器放Jpress.WAR包（创建service 内部暴露）





```bash
配置文件不能灵活运用，因为COPY命令是构建镜像时生效，如果Copy的文件文件使用变量，那么在构建镜像时这个文件已经生成，并且文件中的变量也已经生效，等我们在run 的时候 已经晚了，因此我们要在 运行容器时生成配置文件，并且生成的配置文件中可以使用变量，在启动的时候生成配置文件，在启动的时候 -e 传入参数，然后再启动。

我们得在镜像构建之后，启动容器的时候生成配置文件，并在配置文件中定义变量，启动容器的时候传入参数，

把环境的准备和启动容器进程分开，使用entrypoint做配置环境的初始化，使用CMD 执行容器中前台执行程序。


ENTRYPOINT ["/nginx.sh"]（初始化环境）
CMD ["/usr/local/nginx/sbin/nginx","-g","daemon off;"]（前台启动程序）
#但是我们不能直接这么写如果直接这么些就会变成cmd参数，这直接就乱套，再初始化脚本后面跟了一个莫名其妙的$1参数
/nginx.sh  /usr/local/nginx/sbin/nginx","-g","daemon off

#需要再初始化脚本加上如下配置
cat >/usr/local/nginx/conf/conf.d/www.conf<<E0F
server {
	listen 80;
	server name ${SERVER:-www.magedu.org ;
	root /data/website;}
EOF
mkdir /data/website -p
echo$fSERVER:-www.magedu.org > /data/website/index.html

exec “$@”

$* 把参数当成一个整体,不论多少个参数都是$1  
$@ 把参数 $1 $2 $3

如果ENTRYPOINT和CMD并存CMD变成ENTRYPOINT的参数，然后把 ENTRYPOINT 后面的CMD作为命令行参数，传递给 ENTRYPOINT 指定的脚本，然后我们再脚本中 exec "$@",，然后使用exec替换掉已经执行完的初始化脚本,运行我们的参数指定的进程，参数从CMD指定的进程。


多阶段构建：因为要编译go源码，安装了golang环境，导致镜像太大。但实际我们编译完之后就不需要golang环境了。
阶段一：编译GO文件，需要go环境
阶段二：因为GO是静态编译不依赖go环境，只需要编译后的go文件即可。我们只需要要把第一个镜像编译完成的文件copy到阶段二中小镜像 极大的缩减了空间。
我这个文件来自于第一阶段的容器中
#第一阶段
FROM golang:alpine3.19 as gogobuild
COPY  hello.go  /opt
RUN  cd /opt && go build hello.go
 
#第二阶段
FROM alpine:3.19
CoPY --from=gogobuild /opt/hello /opt/hello T
#COPY --from=0 /opt/hello /hello
CMD ["/opt/hello"]
#如果不写别名 0  1 .... 区分阶段
注意: C编译的文件，不能只COPY二进制，要把整个编译后的目录都COPY走，因为C是动态编译依赖库
```





酷酷打镜像

```bash
#制作基础镜像
docker pull ubuntu:jammy

#Dockerfile 
FROM ubuntu:jammy
MAINTAINER lixijun
COPY sources.list /etc/apt/sources.list
RUN apt update && apt install -y gcc openssh-server lrzsz tree openssl libssl-dev libpcre3 libpcre3-dev zlib1g-dev unzip zip make net-tools && useradd nginx -u 2088

#构建基础镜像
docker push registry.cn-beijing.aliyuncs.com/bjkubernetes/test-ubuntu-base:v1



#基于基础镜像制作JKD镜像
#JDK Base Image
FROM registry.cn-beijing.aliyuncs.com/bjkubernetes/test-ubuntu-base:v1 
MAINTAINER lixijun

ADD jdk-8u212-linux-x64.tar.gz /usr/local/src/
RUN ln -sv /usr/local/src/jdk1.8.0_212 /usr/local/jdk
ADD profile /etc/profile

ENV JAVA_HOME /usr/local/jdk
ENV JRE_HOME $JAVA_HOME/jre
ENV CLASSPATH $JAVA_HOME/lib/:$JRE_HOME/lib/
ENV PATH $PATH:$JAVA_HOME/bin                          

#构建JDK镜像
docker build -t registry.cn-beijing.aliyuncs.com/bjkubernetes/jdk-ubuntu:v1 .
docker push registry.cn-beijing.aliyuncs.com/bjkubernetes/jdk-ubuntu:v1


#基于JDK镜像制作tomcat基础镜像
#Tomcat 8.5.43基础镜像
FROM registry.cn-beijing.aliyuncs.com/bjkubernetes/jdk-ubuntu:v1
MAINTAINER lixijun

RUN mkdir /apps /data/tomcat/webapps /data/tomcat/logs -pv
ADD apache-tomcat-8.5.43.tar.gz  /apps
RUN useradd tomcat -u 2050 && ln -sv /apps/apache-tomcat-8.5.43 /apps/tomcat && chown -R tomcat.tomcat /apps /data -R
#制作并上传
docker build -t registry.cn-beijing.aliyuncs.com/bjkubernetes/tomcat-jdk-ubuntu:v1 .
docker push  registry.cn-beijing.aliyuncs.com/bjkubernetes/tomcat-jdk-ubuntu:v1

#测试tomcat是否可以运行
docker run -it --rm registry.cn-beijing.aliyuncs.com/bjkubernetes/tomcat-jdk-ubuntu:v1 bash


#最后一步添加业务代码和个性化配置

#tomcat web1
FROM registry.cn-beijing.aliyuncs.com/bjkubernetes/tomcat-jdk-ubuntu:v1 

ADD catalina.sh /apps/tomcat/bin/catalina.sh   #记得加执行权限
ADD server.xml /apps/tomcat/conf/server.xml
#ADD myapp/* /data/tomcat/webapps/myapp/
#ADD app1.tar.gz /data/tomcat/webapps/app1/
ADD run_tomcat.sh /apps/tomcat/bin/run_tomcat.sh #记得加执行权限
#ADD filebeat.yml /etc/filebeat/filebeat.yml 
RUN chown  -R nginx.nginx /data/ /apps/
#ADD filebeat-7.5.1-x86_64.rpm /tmp/
#RUN cd /tmp && yum localinstall -y filebeat-7.5.1-amd64.deb

EXPOSE 8080 8443

CMD ["/apps/tomcat/bin/run_tomcat.sh"]

docker build -t registry.cn-beijing.aliyuncs.com/bjkubernetes/conf-tomcat-jdk-ubuntu:v1 .

```





```
kind: Deployment
apiVersion: apps/v1
metadata:
  labels:
    app: tom
  name: jpress
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: tomcat-jpress
  template:
    metadata:
      labels:
        app: tomcat-jpress
    spec:
      containers:
      - name: jpress
        image: registry.cn-beijing.aliyuncs.com/bjkubernetes/conf-tomcat-jdk-ubuntu:v1
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8080
          protocol: TCP
          name: http
        volumeMounts:
        - name: jpress-nfs
          mountPath: /data/tomcat/webapps/
          readOnly: false
      volumes:
      - name: jpress-nfs
        persistentVolumeClaim:
          claimName: pvc001

---
apiVersion: v1
kind: Service
metadata:
  name: jpress-apache
  namespace: default
spec:
  type: NodePort
  ports:
  - name: http
    port: 80
    targetPort: 8080
    nodePort: 30080
    protocol: TCP
  selector:
    app: tomcat-jpress
```





```
#创建pvc
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  namespace: default
  name: pvc001
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 8Gi
  volumeMode: Filesystem
  selector:
    matchLabels:
      name: pvnfs
```









```
#创建pv
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv001
  labels:
    name: pvnfs
spec:
  capacity:
    storage: 10Gi
  volumeMode: Filesystem 
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain  # 定义回收策略为 Retain Delete
  nfs:
    path: /data/nfs/jpress
    server: 10.0.0.203
```







## 使用 Ingress nginx ssl 暴露 wordpress

部署 Ingress-nginx  controller

```
kubectl create namespace blog
```



1使用statefulSet部署mysql 主从

```bash
#进入容器mysql 创建wordpress需要的用户表授权
kubectl exec -it -n blog mysql-0 -- /bin/bash

mysql
CREATE DATABASE wordpressdb;
CREATE USER 'wordpress'@'%' IDENTIFIED BY '123456';
GRANT ALL PRIVILEGES ON wordpressdb.* TO 'wordpress'@'%';
FLUSH PRIVILEGES;
quit;
```



部署wordpress

```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: wordpress
  name: service-wordpress
  namespace: blog
spec:
  ports:
  - name: fpm
    port: 9000
    protocol: TCP
    targetPort: 9000
  selector:
    app: wordpress
```





```bash
#创建连接mysql的secret
kubectl create secret generic wordpres-smysql-secret --from-literal=user.name='wordpress' --from-literal=user.password="123456" --from-literal=db.name='wordpressdb' -n blog --dry-run=client -o yaml


apiVersion: v1
data:
  db.name: d29yZHByZXNzZGI=
  user.name: d29yZHByZXNz
  user.password: MTIzNDU2
kind: Secret
metadata:
  name: wordpres-smysql-secret
  namespace: blog
```



```yaml
#创建pvc
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  namespace: blog
  name: pvc-wordpress
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
  storageClassName: nfs-csi
                             
```





```yaml
#部署wordpress

apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: wordpress
  name: wordpress
  namespace: blog
spec:
  replicas: 1
  selector:
    matchLabels:
      app: wordpress
  template:
    metadata:
      labels:
        app: wordpress
    spec:
      containers:
      - image: wordpress:5.8-fpm
        name: wordpress
        env:
        - name: WORDPRESS_DB_HOST
          value: mysql-read
        - name: WORDPRESS_DB_USER
          valueFrom:
            secretKeyRef:
              name: wordpres-smysql-secret
              key: user.name
        - name: WORDPRESS_DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: wordpres-smysql-secret
              key: user.password
        - name: WORDPRESS_DB_NAME
          valueFrom:
            secretKeyRef:
              name: wordpres-smysql-secret
              key: db.name
        volumeMounts:
        - name: pvc
          mountPath: /var/www/html/
      volumes:
      - name: pvc
        persistentVolumeClaim:
          claimName: pvc-wordpress

```





使用ingress ssl 暴露服务

```bash
(umask 077; openssl genrsa -out zedking.key 2048)
openssl req -new -x509 -key ./zedking.key -out ./zedking.crt -days=3655 -subj="/O=zedking1/OU=DevOps/CN=www.zedking.org"

kubectl create secret tls tls-wordpress --cert=.zedking.crt --key=./zedking.key -n blog

#创建常规的虚拟主机代理规则，同时将该主机定义为TLS类型
kubectl create ingress ingress-wordpress --rule='www.zedking.org/*=wordpress:80,tls=tls-wordpress' --class=nginx -n blog

#注意：启用tls后，该域名下的所有URI默认为强制将http请求跳转至https，若不希望使用该功能，可以使用如下注解选项
--annotation nginx.ingress.kubernetes.io/ssl-redirect=false
```

