#linux redis自动安装程序 
#运行例子：mkdir -p /shell && cd /shell && rm -rf install-redis.sh && wget --no-cache https://raw.staticdn.net/share-group/shell/master/docker/install-redis.sh && sh install-redis.sh 3.2.6 /usr/local

function cluster(){ 
	redis_version=$1;
	port=$2;
	mkdir -p /usr/local/redis/data/$port
	docker run -it --name redis-$port -p $port:6379 -v /usr/local/redis/data/$port:/data -d hub.c.163.com/library/redis:$redis_version-alpine
}


#处理外部参数
redis_version=$1
redis_install_path=$2
if [ ! $redis_version ] || [ ! $redis_install_path ] ; then
	echo 'error command!!! you must input redis version and install path...'
	echo 'for example: sh install-redis.sh 3.2.6 /usr/local'
	exit
fi


#建立临时安装目录
echo 'preparing working path...'
install_path='/install'
rm -rf $install_path
mkdir -p $install_path

rm -rf $redis_install_path/redis
mkdir -p $redis_install_path/redis/data
mkdir -p $redis_install_path/redis/bin

#下载redis-trib.rb
cd $redis_install_path/redis/bin
wget --no-cache https://raw.staticdn.net/antirez/redis/$redis_version/src/redis-trib.rb
rm -rf /usr/bin/redis-trib.rb
ln -s $redis_install_path/redis/bin/redis-trib.rb /usr/bin/redis-trib.rb
chmod 777 /usr/bin/redis-trib.rb
chmod 777 $redis_install_path/redis/bin/redis-trib.rb

#用docker安装
docker pull hub.c.163.com/library/redis:$redis_version-alpine

#默认创建一个6个节点(3主3从)的集群
cluster $redis_version 7000
cluster $redis_version 7001
cluster $redis_version 7002
cluster $redis_version 7003
cluster $redis_version 7004
cluster $redis_version 7005
redis-trib.rb create --replicas 1 127.0.0.1:7000 127.0.0.1:7001 127.0.0.1:7002 127.0.0.1:7003 127.0.0.1:7004 127.0.0.1:7005
