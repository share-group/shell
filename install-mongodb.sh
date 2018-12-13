#linux mongodb自动安装程序 
#运行例子：mkdir -p /shell && cd /shell && rm -rf install-mongodb.sh && wget --no-cache https://raw.githubusercontent.com/share-group/shell/master/install-mongodb.sh && sh install-mongodb.sh 4.0.4 /usr/local
 
#定义本程序的当前目录
base_path=$(pwd)
ntpdate ntp.api.bz

#处理外部参数
mongodb_version=$1
mongodb_install_path=$2
if [ ! $mongodb_version ] || [ ! $mongodb_install_path ] ; then
	echo 'error command!!! you must input mongodb version and install path...'
	echo 'for example: sh install-mongodb.sh 4.0.4 /usr/local'
	exit
fi

#建立临时安装目录
echo 'preparing working path...'
install_path='/install'
rm -rf $install_path
mkdir -p $install_path

yum -y install libtool sed gcc gcc-c++ make net-snmp curl net-snmp-devel net-snmp-utils libc6-dev python-devel rsync perl bc libxslt-dev lrzsz bzip2 unzip 

rm -rf $mongodb_install_path/mongodb

wget -O $base_path/mongodb-$mongodb_version.tgz http://install.ruanzhijun.cn/mongodb-linux-x86_64-$mongodb_version.tgz || exit
tar zxvf $base_path/mongodb-$mongodb_version.tgz -C $mongodb_install_path || exit
mv $mongodb_install_path/mongodb-linux-x86_64-$mongodb_version $mongodb_install_path/mongodb
rm -rf $mongodb_install_path/mongodb/data
mkdir -p $mongodb_install_path/mongodb/data

cd /usr/bin/ && rm -rf /usr/bin/mongo && ln -s $mongodb_install_path/mongodb/bin/mongo mongo
cd /usr/bin/ && rm -rf /usr/bin/mongod && ln -s $mongodb_install_path/mongodb/bin/mongod mongod
cd /usr/bin/ && rm -rf /usr/bin/mongodump && ln -s $mongodb_install_path/mongodb/bin/mongodump mongodump
chmod 777 /usr/bin/mongo
chmod 777 /usr/bin/mongod
chmod 777 /usr/bin/mongodump

#创建mongodb配置文件
echo "#数据存储路径
dbpath="$mongodb_install_path"/mongodb/data

#日志存储路径
logpath="$mongodb_install_path"/mongodb/mongodb.log

#非常详细的故障排除和各种错误的诊断日志记录
#默认0。设置为1，为在dbpath目录里生成一个diaglog.开头的日志文件，他的值如下：
#Value    			 Setting
#  0    		off. No logging.       				#关闭。没有记录。
#  1    		Log write operations.  				#写操作
#  2    		Log read operations.   				#读操作
#  3    		Log both read and write operations. #读写操作
#  7    		Log write and some read operations. #写和一些读操作
#diaglog=7

#pid文件路径
pidfilepath="$mongodb_install_path"/mongodb/mongodb.pid

#是否追加日志
logappend=true

#是否后台运行
fork=true

#是否开启cpu使用报告
cpu=true

#是否开启目录存储模式(简单点说，就是根据数据库名创建文件夹)
directoryperdb=true

#绑定的ip地址(可以用一个逗号分隔的列表绑定多个IP地址)
bind_ip=0.0.0.0

#启动端口
port=27017

#最大连接数(最大20000)
maxConns=100

#存储引擎
storageEngine=wiredTiger

#是否强制验证客户端请求
objcheck=true

#开启journal(参考：http://www.mongoing.com/archives/3988)
journal=true

#刷写提交机制
journalCommitInterval=100

#预分配方式
noprealloc=false

#慢查询时间(单位：ms)
slowms=100

#是否开启认证模式
noauth=true
#auth=true

#mongodb主从
#master=true
#slave=true
#source=slave.mongodb.com
" > $mongodb_install_path/mongodb/mongodb.conf || exit

mongod --config $mongodb_install_path/mongodb/mongodb.conf &
echo '' >> /etc/rc.d/rc.local

echo 'rm -rf '$mongodb_install_path'/mongodb/data/mongod.lock' >> /etc/rc.d/rc.local
echo 'rm -rf '$mongodb_install_path'/mongodb/mongodb.pid' >> /etc/rc.d/rc.local
echo 'mongod --config '$mongodb_install_path'/mongodb/mongodb.conf &' >> /etc/rc.d/rc.local
source /etc/rc.d/rc.local

#创建超级管理员
#db.createUser({user: "root",pwd: "xxxxxxxxxxxxx",roles: [{role:"dbAdminAnyDatabase",db:"admin"},{ role: "userAdminAnyDatabase",db:"admin"},{role:"readAnyDatabase",db:"admin"},{role:"readWriteAnyDatabase",db:"admin"}]})

#单个数据库读写
#db.createUser({user:"root",pwd: "xxxxxxxxxxxxxxxx",roles:[{role:"readWrite",db:"Kpoker"}]})

#mongodb用户名密码登录
#mongo -u root -p root --authenticationDatabase admin

