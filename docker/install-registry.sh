#linux registry自动安装程序 
#运行例子：mkdir -p /shell && cd /shell && rm -rf install-registry.sh && wget --no-cache https://raw.githubusercontent.com/share-group/shell/master/docker/install-registry.sh && sh install-registry.sh /usr/local

#处理外部参数
registry_install_path=$1
if [ ! $registry_install_path ]; then
	echo 'error command!!! you must input registry install path...'
	echo 'for example: sh install-registry.sh /usr/local'
	exit
fi

#建立临时安装目录
echo 'preparing working path...'
install_path='/install'
rm -rf $install_path $registry_install_path/registry
mkdir -p $install_path
mkdir -p $registry_install_path/registry

#拉取镜像
docker pull registry

#启动docker pull registry
docker run -d --name registry -v $registry_install_path/registry:/var/lib/registry -p 5000:5000 --restart=always --privileged=true registry

#安装harbor作为镜像管理  https://www.cnblogs.com/huangjc/p/6266564.html
yum -y install epel-release
yum -y install python-pip
pip install --upgrade backports.ssl_match_hostname
pip install --upgrade pip
pip install docker-compose
docker-compose --version

#解决https的问题
#在”/etc/docker/“目录下，创建”daemon.json“文件。在文件中写入：
#{ "insecure-registries":["192.168.1.100:5000"] }

#需要用户名密码：http://blog.csdn.net/dream_an/article/details/58005324