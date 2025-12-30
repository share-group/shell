#linux mongodb自动安装程序 
#运行例子：mkdir -p /shell && cd /shell && rm -rf install-mongodb.sh && wget --no-cache https://raw.githubusercontent.com/share-group/shell/master/docker/install-mongodb.sh && sh install-mongodb.sh 3.4.2 /usr/local

#处理外部参数
mongodb_version=$1
mongodb_install_path=$2
if [ ! $mongodb_version ] || [ ! $mongodb_install_path ]; then
	echo 'error command!!! you must input mongodb install path...'
	echo 'for example: sh install-mongodb.sh 3.4.2 /usr/local'
	exit
fi
 
#建立临时安装目录
echo 'preparing working path...'
install_path='/install'
rm -rf $install_path
mkdir -p $install_path

#创建配置文件
rm -rf /etc/mongod.conf
echo "# 日志文件位置
#logpath = D:\nginx\mongodb\mongod.log

# 以追加方式写入日志
logappend = true

# 默认27017
port = 27017

# 绑定的ip
bind_ip = 0.0.0.0

# 最大连接数
maxConns = 100

# 数据库文件位置
#dbpath = D:\nginx\mongodb\data

# 启用定期记录CPU利用率和 I/O 等待
cpu = true

# 强制验证客户端请求，确保客户端绝不插入无效文件到数据库中
objcheck = true

# 是否以安全认证方式运行，默认是不认证的非安全方式
noauth = true
#auth = true

# 详细记录输出
verbose = true

# 创建一个非常详细的故障排除和各种错误的诊断日志记录
diaglog = 3

# 数据库分析等级设置。记录一些操作性能到标准输出或则指定的logpath的日志文件中
profile = 2

# 开启后，在MongoDB默认会开启一个HTTP协议的端口提供REST的服务，这个端口是你Server端口加上1000，即28017，默认的HTTP端口是数据库状态页面
rest = true
" > /etc/mongod.conf

#准备数据目录
mkdir -p $mongodb_install_path/mongodb/data
chcon -Rt svirt_sandbox_file_t $mongodb_install_path/mongodb/data

#用docker安装
docker pull daocloud.io/library/mongo:$mongodb_version

#启动mongodb
docker run -it --name mongodb -p 27017:27017 -v $mongodb_install_path/mongodb/data:/data/db -v /etc/mongod.conf:/etc/mongod.conf.orig -d daocloud.io/library/mongo:$mongodb_version --config /etc/mongod.conf.orig --storageEngine wiredTiger


#开机自启动
echo '' >> /etc/rc.d/rc.local
echo 'docker start mongodb' >> /etc/rc.local