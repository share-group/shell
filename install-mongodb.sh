#linux mongodb自动安装程序 
#运行例子：mkdir -p /shell && cd /shell && rm -rf install-mongodb.sh && wget --no-cache https://raw.githubusercontent.com/share-group/shell/master/install-mongodb.sh && sh install-mongodb.sh 4.0.0 /usr/local
 
#定义本程序的当前目录
base_path=$(pwd)
ntpdate ntp.api.bz

#处理外部参数
mongodb_version=$1
mongodb_install_path=$2
if [ ! $mongodb_version ] || [ ! $mongodb_install_path ] ; then
	echo 'error command!!! you must input mongodb version and install path...'
	echo 'for example: sh install-mongodb.sh 4.0.0 /usr/local'
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
mv $mongodb_install_path/mongodb-linux-x86_64-enterprise-rhel70-$mongodb_version $mongodb_install_path/mongodb
mkdir -p $mongodb_install_path/mongodb/data
$mongodb_install_path/mongodb/bin/mongod --port 27017 --dbpath $mongodb_install_path/mongodb/data --logpath --fork $mongodb_install_path/mongodb/log.log --logappend &
echo '' >> /etc/rc.d/rc.local

echo 'rm -rf '$mongodb_install_path'/mongodb/data/mongod.lock' >> /etc/rc.d/rc.local
echo $mongodb_install_path'/mongodb/bin/mongod --port 27017 --dbpath '$mongodb_install_path'/mongodb/data --logpath '$mongodb_install_path'/mongodb/log.log --logappend --fork --storageEngine wiredTiger &' >> /etc/rc.d/rc.local
source /etc/rc.d/rc.local

