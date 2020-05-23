#linux mongodb自动安装程序 
#运行例子：mkdir -p /shell && cd /shell && rm -rf install-mongodb.sh && wget --no-cache https://raw.githubusercontent.com/share-group/shell/master/install-mongodb.sh && sh install-mongodb.sh 4.2.6 /usr/local
 
#定义本程序的当前目录
base_path=$(pwd)

#处理外部参数
mongodb_version=$1
mongodb_install_path=$2
if [ ! $mongodb_version ] || [ ! $mongodb_install_path ] ; then
	echo 'error command!!! you must input mongodb version and install path...'
	echo 'for example: sh install-mongodb.sh 4.2.6 /usr/local'
	exit
fi

#建立临时安装目录
echo 'preparing working path...'
install_path='/install'
rm -rf $install_path
mkdir -p $install_path

yum -y install libtool sed gcc gcc-c++ make net-snmp curl net-snmp-devel net-snmp-utils libc6-dev python-devel rsync perl bc libxslt-dev lrzsz bzip2 unzip 

rm -rf $mongodb_install_path/mongodb

wget -O $base_path/mongodb-$mongodb_version.tgz https://install.ruanzhijun.cn/mongodb-linux-x86_64-$mongodb_version.tgz || exit
tar zxvf $base_path/mongodb-$mongodb_version.tgz -C $mongodb_install_path || exit
mv $mongodb_install_path/mongodb-linux-x86_64-rhel70-$mongodb_version $mongodb_install_path/mongodb
rm -rf $mongodb_install_path/mongodb/data
mkdir -p $mongodb_install_path/mongodb/data

cd /usr/bin/ && rm -rf /usr/bin/mongo && ln -s $mongodb_install_path/mongodb/bin/mongo mongo
cd /usr/bin/ && rm -rf /usr/bin/mongod && ln -s $mongodb_install_path/mongodb/bin/mongod mongod
cd /usr/bin/ && rm -rf /usr/bin/mongodump && ln -s $mongodb_install_path/mongodb/bin/mongodump mongodump
chmod 777 /usr/bin/mongo
chmod 777 /usr/bin/mongod
chmod 777 /usr/bin/mongodump

#创建mongodb配置文件
echo "#系统日志
systemLog:
   #日志级别，0：默认值，包含 “info” 信息，1~5，即大于 0 的值均会包含 debug 信息
   verbosity: 0
   #打印异常详细信息
   traceAllExceptions: true
   #日志存储路径
   path: "$mongodb_install_path"/mongodb/mongodb.log
   #是否追加日志
   logAppend: true
   #日志 “回转”，防止一个日志文件特别大，则使用 logRotate 指令将文件 “回转”，可选值：rename、reopen
   logRotate: rename
   #日志输出目的地，可以指定为 “file” 或者“syslog”，表述输出到日志文件，如果不指定，则会输出到标准输出中（standard output）
   destination: file
   
#网络
net:
   #端口
   port: 27017
   #绑定ip，可用多个逗号分隔
   bindIp: 127.0.0.1
   #进程允许的最大连接数 默认值为 65536
   maxIncomingConnections: 65536
   #当客户端写入数据时，检测数据的有效性
   wireObjectCheck: true

#安全
security:
   #仅对 mongod 有效；enabled-客户端可以通过用户名和密码认证的方式访问系统的数据；disabled-客户端不需要密码即可访问数据库数据
   authorization: disabled

#进程管理
processManagement:
   #是否后台运行
   fork: true
   #PID文件路径
   pidFilePath: "$mongodb_install_path"/mongodb/mongodb.pid
   
#存储
storage:
   #mongod 进程存储数据目录，此配置仅对 mongod 进程有效
   dbPath: "$mongodb_install_path"/mongodb/data
   #当构建索引时 mongod 意外关闭，那么再次启动是否重新构建索引；索引构建失败，mongod 重启后将会删除尚未完成的索引
   indexBuildRetry: false
   journal:
      enabled: true
      commitIntervalMs: 500
   #是否开启目录存储模式(简单点说，就是根据数据库名创建文件夹)
   directoryPerDB: true
   #mongod 使用 fsync 操作将数据 flush 到磁盘的时间间隔，默认值为 60（单位：秒）强烈建议不要修改此值 mongod 将变更的数据写入 journal 后再写入内存，并间歇性的将内存数据 flush 到磁盘中，即延迟写入磁盘，有效提升磁盘效率
   syncPeriodSecs: 60
   #存储引擎类型，mongodb 3.0 之后支持 “mmapv1”、“wiredTiger” 两种引擎，默认值为“mmapv1”；官方宣称 wiredTiger 引擎更加优秀。
   engine: wiredTiger
   wiredTiger:
      engineConfig:
	     #默认情况下，此值的大小为物理内存的一半，单位：GB
         cacheSizeGB: 1
         #journal 日志的压缩算法，可选值为 “none”、“snappy”、“zlib”。
         journalCompressor: snappy
         #是否将索引和 collections 数据分别存储在 dbPath 单独的目录中。即 index 数据保存 “index” 子目录，collections 数据保存在 “collection” 子目录。默认值为 false，仅对 mongod 有效
         directoryForIndexes: false
      collectionConfig:
         #collection 数据压缩算法，可选值 “none”、“snappy”、“zlib”
         blockCompressor: snappy
      indexConfig:
         #是否对索引数据使用 “前缀压缩”。前缀压缩，对那些经过排序的值存储，有很大帮助，可以有效的减少索引数据的内存使用量。默认值为 true
         prefixCompression: true

#性能分析器
operationProfiling:
   #数据库 profiler 级别，操作的性能信息将会被写入日志文件中，可选值：off：关闭 profiling、slowOp：只包含慢操作日志、all：记录所有操作
   mode: slowOp
   #“慢查询” 的时间阀值，单位：毫秒
   slowOpThresholdMs: 100
   #慢查询日志采样率，0 - 1 之间的浮点数
   slowOpSampleRate: 0.5
" > $mongodb_install_path/mongodb/mongodb.conf || exit

mongod --config $mongodb_install_path/mongodb/mongodb.conf &
echo '' >> /etc/rc.local

#开机自启动
echo 'rm -rf '$mongodb_install_path'/mongodb/data/mongod.lock' >> /etc/rc.local
echo 'rm -rf '$mongodb_install_path'/mongodb/mongodb.pid' >> /etc/rc.local
echo 'mongod --config '$mongodb_install_path'/mongodb/mongodb.conf &' >> /etc/rc.local
source /etc/rc.local

#创建超级管理员
#db.createUser({user: "root",pwd: "xxxxxxxxxxxxx",roles: [{role:"dbAdminAnyDatabase",db:"admin"},{ role: "userAdminAnyDatabase",db:"admin"},{role:"readAnyDatabase",db:"admin"},{role:"readWriteAnyDatabase",db:"admin"}]})

#单个数据库读写
#db.createUser({user:"root",pwd: "xxxxxxxxxxxxxxxx",roles:[{role:"readWrite",db:"xxxxxxxx"}]})

#mongodb用户名密码登录
#mongo ip:port -u root -p root --authenticationDatabase admin

