# 使用Velero备份和恢复Kubernetes（1）

Velero是用于备份和恢复 Kubernetes 集群资源和PV的开源项目。

- 基于Velero CRD创建备份（Backup）和恢复作业（Restore）

- 可以备份或恢复集群中的几乎所有对象，也可以按类型、名称空间或标签过滤对象

- 支持基于文件系统备份（File System Backup，简称FSB）备份Pod卷中的数据，并借助于restic或kopia上传到对象存储系统上

- 支持基于快照备份PV，这种方式较之FSB能确保文件的一致性；它支持两种操作

- - 仅创建PV快照
  - 创建PV快照，并借助于restic或kopia上传到对象存储系统上

- 使用对象存储作为备份数据的存储目标，并基于对象存储上的备份对象完成数据恢复

- - 基于存储提供商插件同各种存储系统集成
  - 支持的Provider列表：https://velero.io/docs/main/supported-providers/

### 部署

Velero会将Backup对象存储于对象存储系统上，例如AWS S3、Google Cloud Storage、Azure Blob Storage、Alibaba Cloud OSS、Swift等，以及兼容S3接口的第三方对象存储系统，如MinIO等。

本示例将选用本地部署的MinIO，因此，需要事先部署有可用的MinIO（部署于minio名称空间，且服务名同样为minio），且创建了名为velero的bucket。

#### 准备用于认证到MinIO的配置文件

创建名为credentials-velero的文件，用于在部署过程中向velero install命令提供认证到MinIO的认证凭据。

[default]
\# 访问对象存储系统时使用的用户名
aws_access_key_id = minioadmin
\# 用户的密码
aws_secret_access_key = lxju.com
region = minio

#### 下载velero CLI

部署velero的常用方法有两种，一是使用velero CLI，另一个则是使用helm。本示例将选用前者进行。

首先，我们需要先下载velero CLI工具程序，以v1.13.0版本例，运行如下命令即可完成下载。

~# curl -LO https://github.com/vmware-tanzu/velero/releases/download/v1.13.0/velero-v1.13.0-linux-amd64.tar.gz

下载完成后，展开压缩文件，将velero复制到PATH环境变量指定的程序搜索目录之一，即可使用velero命令。

~# tar xf velero-v1.13.0-linux-amd64.tar.gz

~# mv  velero-v1.13.0-linux-amd64/velero  /usr/local/bin/

#### 部署Velero

velero CLI是一个多功能的应用程序，它有着众多的可用子命令。其中的install命令即用于部署Velero至Kubernetes集群上。

> 提示：velero CLI基于kubeconfig文件认证到Kubernetes集群，它搜索和加载kubeconfig的方式与kubectl类似。

velero install \   
    --secret-file=./credentials-velero \   
    --provider=aws \   
    --bucket=velero \   
    --backup-location-config region=minio,s3ForcePathStyle=true,s3Url=http://minio.lxju.com:9000 \   
     --plugins=velero/velero-plugin-for-aws:v1.9.0 \   
     --use-volume-snapshots=true \   
     --snapshot-location-config region=minio \   
     --use-node-agent \   
     --uploader-type=kopia

上面命令中使用了众多选项，其中各选项的功能如下。

- --provider：用于保存备份和卷数据的Provider的名称；Velero支持多种Provider，不同的Provider通常需要依赖专用的插件
- --plugins：要加载的插件列表，各插件是引用的Image的名称
- --backup-location-config：保存备份的存储系统的具体信息，格式为“key1=value1,key2=value2”
- --snapshot-location-config：保存PV快照的存储系统的具体信息，格式为“key1=value1,key2=value2”
- --use-volume-snapshots：是否自动创建用于保存快照的snapshot location，默认为true
- --secret-file：保存有认证到存储系统的认证凭据的文件
- --bucket：远端对象存储系统上用于保存备份信息的bucket
- --use-node-agent：是否创建用于部署node agent的DaemonSet，它们负责基于Restic或Kopia上传卷和快照中的数据至远端存储系统；
- --uploader-type：上传数据使用的uploader，可用值为Restic或Kopia

部署完成后，运行如下命令，可以了解到其创建的资源对象。

~# kubectl get all -n velero

如下面命令结果所示，它会部署一个daemonset编排运行Node Agent，以及一个deployment编排运行Velero。

部署完成后，velero install还会创建多个CRD，这可以通过如下命令了解相关的信息。

~# kubectl api-resources --api-group=velero.io

NAME            SHORTNAMES  APIVERSION      NAMESPACED  KIND
backuprepositories           velero.io/v1     true     BackupRepository
backups                 velero.io/v1     true     Backup
backupstoragelocations   bsl      velero.io/v1     true     BackupStorageLocation
datadownloads              velero.io/v2alpha1  true     DataDownload
datauploads               velero.io/v2alpha1  true     DataUpload
deletebackuprequests          velero.io/v1     true     DeleteBackupRequest
downloadrequests            velero.io/v1     true     DownloadRequest
podvolumebackups            velero.io/v1     true     PodVolumeBackup
podvolumerestores            velero.io/v1     true     PodVolumeRestore
restores                velero.io/v1     true     Restore
schedules                velero.io/v1     true     Schedule
serverstatusrequests    ssr      velero.io/v1     true     ServerStatusRequest
volumesnapshotlocations  vsl      velero.io/v1     true     VolumeSnapshotLocation





#### 备份存储位置（Backup Storage Location）

Velero系统上用于保存备份信息的目标位置称为Backup Storage Location，可由专用的CRD/BackupStorageLocation进行定义和维护。Velero部署完成后，它会自动创建一个名为default的Backup Storage Location对象，它代表Velero默认用于存储Backup的位置。

~# kubectl get BackupStorageLocations -n velero

NAME    PHASE    LAST VALIDATED  AGE  DEFAULT
default  Available  21s        16m  true

也可以使用“velero backup-location”命令了解相关的资源对象，这类的指令式命令通常能够得到更为详细和易于理解的信息。

~# velero backup-location get

NAME    PROVIDER  BUCKET/PREFIX  PHASE    LAST VALIDATED          ACCESS MODE  DEFAULT
default  aws     velero      Available  2024-02-22 10:40:34 +0800 CST  ReadWrite   true

用户也可以创建更多的备份存储位置，以便于在不同的备份需求场景中使用，这使用如下格式的命令就能完成。

```
velero backup-location create NAME [flags]
```

命令的具体使用格式，请参考相关的帮助信息进行了解。

#### 创建Backup

通常，为没有使用到Volume的无状态应用创建Backup是最简单的备份需求。

管理Backup对象，可以创建相关的资源配置，并由kubectl进行，也可以由“velero backup”命令直接基于指令式命令完成。命令格式为：

```bash
velero backup create NAME [flags]
```

最为简单的格式就是仅给出Backup名称，如下所示，它将创建名为mykube的Backup对象，备份整个集群，并保存于安装Velero时创建的默认的保存位置，它通常是一个名为default的BackupStorageLocation对象。

```bash
velero backup create mykube
```

而后，可运行如下命令了解相关的Backup信息。未指定具全的Backup时，它将列表所有的Backup对象。

```bash 
velero backup get
```

命令的返回结果如下所示，其中的STATUS字段代表着备份作业的状态，InProgress表示正在进行中，备份执行完成后将转为Completed。

NAME   STATUS    ERRORS  WARNINGS  CREATED             EXPIRES  STORAGE LOCATION  SELECTOR
mykube  InProgress  0     0      2024-02-22 10:56:09 +0800 CST  29d    default       <none>

备份生成的内容存储于BackupStorageLocation/default指向的存储位置，本示例中，它指的是我们事先准备的MinIO存储系统上名为velero的bucket中。

![image-20240430205340637](./../images/image-20240430205340637.png)

若需要打印Backup对象的详细信息，可通过“velero backup describe”命令进行，如下面的命令所示。

```bash 
velero backup describe mykube
```

该命令还支持使用“--details”选项打印更加详细的信息。

删除Backup对象，可通过“velero backup delete”命令进行。例如，若要删除前面创建的Backup/mykube对象，可使用如下命令进行。

```bash
velero backup delete mykube
```

若要一次性删除所有备份对象，使用“velero backup delete --all”命令即可。

#### 定制备份的内容

“velero backup”命令允许用户选定要备份的名称空间，以及要备份的资源类型。

- --include-namespaces：要备份的名称空间列表，默认为“*”，代表备份所有的名称空间；
- --exclude-namespaces：在备份中要排除的名称空间列表，即不要备份的名称空间列表；
- --include-resources：要备份的资源类型列表，格式为“resouce.group”，例如“daemonsets.apps”，默认为“*”；
- --exclude-resources：要排除的资源类型列表，格式为“resouce.group”；
- --include-cluster-resources：同时备份集群级别的所有资源；
- --include-cluster-scoped-resources：要备份的集群级别的资源类型列表；
- --exclude-cluster-scoped-resources：要排除的集群级别的资源类型列表；
- --include-namespace-scoped-resources：要备份的名称空间级别的资源类型列表；不能够同--include-resources、--include-cluster-resources选项同时使用；
- --exclude-namespace-scoped-resources：要排除的名称空间级别的资源类型列表；
- --snapshot-volumes：是否为PV资源创建快照作为备份作业的一部分，默认为true；
- --default-volumes-to-fs-backup：是否使用FSB机制备份Pod卷中的内容；

注意，上面几个选项中，部分选项不能同时使用，例如--include-resources、--exclude-resources和--include-cluster-resources，就不能同include-cluster-scoped-resources、exclude-cluster-scoped-resources、include-namespace-scoped-resources以及exclude-namespace-scoped-resources几个同时使用。

例如，执行备份测试时，仅备份demo名称空间，可以通过如下命令完成。

```bash
velero backup create backup-demo --include-namespaces demo
```

仅备份demo名称空间，且要使用FSB备份机制来备份Pod Volume中的数据时，可通过如下命令进行。

```bash
velero backup create backup-demo-with-volume --include-namespaces demo --default-volumes-to-fs-backup
```

该命令会触发Velero在远程对象存储的bucket中自动创建一个与uploader同名（默认为kopia）的目录来存储卷中的数据，每个名称空间中的卷数据会存储在一个以名称空间名字命名的目录中。

> 提示：通过这种方式备份Pod卷中的数据，很可能会导致数据不一致的情形。这是因为备份过程是通过复制卷中的数据进行的，这对于一个存在频繁数据写入的Pod卷来说，复制而来的数据不一致也就不难理解了。更为妥当的备份方式，是对PV做快照后，基于快照卷来备份数据。



若要备份除demo以外的所有名称空间，以及集群级别的所有资源，可通过如下命令进行。命令中的“--snapshot-volumes=false”表示不要试图为PV创建快照备份，这在备份的Pod上使用的卷后端不支持快照时较为有用。

```bash 
velero backup create mykube-exclude-demo --include-cluster-resources --snapshot-volumes=false --exclude-namespaces demo
```

另外，"velero backup logs"命令可用于打印Backup对象的详细日志信息，这对于排查错误、验证备份任务细节等特别有帮助。

#### 创建和使用Restore

我们通过模拟误删除了demo名称空间，并从备份中执行恢复来了解Velero的灾难恢复机制。下面的命令，能够从前面特地针对demo名称空间创建的备份对象backup-demo中来恢复demo名称空间及内部的所有资源。

```bash 
velero restore create --from-backup backup-demo
```

该命令会创建一个Restore资源对象来执行恢复过程，相关的对象的信息，可由如下命令列出。

```bash 
velero restore get
```

上面创建的恢复对象相关的信息显示如下，相关的对象名称为backup-demo-20240222133038。

NAME             BACKUP     STATUS    STARTED             COMPLETED            ERRORS  WARNINGS  CREATED             SELECTOR
backup-demo-20240222133038  backup-demo  Completed  2024-02-22 13:30:38 +0800 CST  2024-02-22 13:30:39 +0800 CST  0     1      2024-02-22 13:30:38 +0800 CST  <none>

若需要打印该Restore对象的详细信息，可使用“velero restore describe”命令进行，而打印日志信息则要使用“velero restore logs”命令完成。

需要注意的是，前一节创建Backup/backup-demo对象时，并未启用FSB机制来上传Pod卷中的数据，因此，对于使用了卷的Pod来说，Restore作业将无法完成其数据恢复，而仅能恢复其卷的定义。而前一节在“velero backup create”命令创建Backup/bacup-demo-with-volume时使用了“--default-volumes-to-fs-backup”选项，它会打包上传各Pod卷中的数据，并可用于数据恢复。

于是，为了测试Pod卷的数据恢复效果，在删除demo名称空间后，我们再次创建一个Restore对象，从带有数据的Backup中进行灾难恢复。

```bash 
velero restore create --from-backup backup-demo-with-volume
```

上面的命令能够恢复Pod卷中的数据至备份那一刻的状态 ，但这种方式备份和恢复的数据，很可能存在不一致状态。

#### 恢复指定的数据

“velero restore create”命令还可多个选项，用于帮助用户仅恢复备份集中的部分内容，例如特定的名称空间、特定类型的资源等。

- --include-namespaces：从备份中恢复的名称空间列表，默认为“*”，即备份中存在的所有名称空间；
- --exclude-namespaces：从备份中进行恢复作业时，要排除的名称空间列表；
- --include-resources：从备份中要恢复的资源类型，格式为“resouce.group”，例如“daemonsets.apps”，默认为“*”，即恢复备份集中的所有类型的资源对象；
- --exclude-resources：执行恢复操作时要排除的资源类型；
- -l, --selector：基于标签选择器来指定要恢复的资源对象；
- --namespace-mappings：给恢复的名称空间重命令，格式为“src1:dst1,src2:dst2,...”；
- --restore-volumes：是否要从相关的快照中恢复卷，默认为true；
