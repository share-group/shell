#linux docker
#运行例子：mkdir -p /shell && cd /shell && rm -rf install-docker.sh && wget --no-cache https://raw.githubusercontent.com/share-group/shell/master/install-docker.sh && sh install-docker.sh 17.03.0-ce /usr/local

#定义本程序的当前目录
base_path=$(pwd)

#处理外部参数
docker_version=$1
docker_install_path=$2 
if [ ! $docker_version ] || [ ! $docker_install_path ]; then
	echo 'error command!!! you must input docker version and install path...'
	echo 'for example: sh install-docker.sh 17.03.2-ce /usr/local'
	exit
fi

#建立临时安装目录
echo 'preparing working path...'
install_path='/install'
rm -rf $install_path
mkdir -p $install_path

#旧版本的docker
rm -rf /var/lib/docker
rm -rf $docker_install_path/docker
rm -rf /usr/bin/docker
rm -rf /usr/bin/dockerd
rm -rf /usr/bin/docker-containerd
rm -rf /usr/bin/docker-containerd-ctr
rm -rf /usr/bin/docker-containerd-shim
rm -rf /usr/bin/docker-proxy
rm -rf /usr/bin/docker-runc
rm -rf /usr/bin/docker-init

#下载docker
if [ ! -f $base_path/docker-$docker_version.tar.gz ]; then
	echo 'docker-'$docker_version'.tar.gz is not exists, system will going to download it...'
	wget -O $base_path/docker-$docker_version.tar.gz http://install.ruanzhijun.cn/docker-$docker_version.tar.gz || exit
	echo 'download docker-'$docker_version'.tar.gz finished...'
fi
tar zxvf $base_path/docker-$docker_version.tar.gz -C $docker_install_path || exit
cd $docker_install_path/docker && chmod 777 *
ln -s $docker_install_path/docker/docker /usr/bin/docker && chmod 777 /usr/bin/docker
ln -s $docker_install_path/docker/dockerd /usr/bin/dockerd && chmod 777 /usr/bin/dockerd
ln -s $docker_install_path/docker/docker-containerd /usr/bin/docker-containerd && chmod 777 /usr/bin/docker-containerd
ln -s $docker_install_path/docker/docker-containerd-ctr /usr/bin/docker-containerd-ctr && chmod 777 /usr/bin/docker-containerd-ctr
ln -s $docker_install_path/docker/docker-containerd-shim /usr/bin/docker-containerd-shim && chmod 777 /usr/bin/docker-containerd-shim
ln -s $docker_install_path/docker/docker-proxy /usr/bin/docker-proxy && chmod 777 /usr/bin/docker-proxy
ln -s $docker_install_path/docker/docker-runc /usr/bin/docker-runc && chmod 777 /usr/bin/docker-runc
ln -s $docker_install_path/docker/docker-init /usr/bin/docker-init && chmod 777 /usr/bin/docker-init

#使docker支持远程管理
echo 'DOCKER_OPTS="-H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock"' > /etc/default/docker

#关闭selinux
setenforce 0
sed -i '/^SELINUX=/c\SELINUX=disabled' /etc/selinux/config || exit
 
#启动docker
dockerd > /dev/null &

#使docker开机自启动
echo 'dockerd > /dev/null &' >> /etc/rc.local || exit


#打印docker版本
echo 'install docker-'$docker_version' finish ...'
docker -v
docker info

#安装alpine，作为所有镜像的基础系统，下载镜像时优先选择alpine的镜像
docker pull hub.c.163.com/library/alpine:latest

#安装docker管理工具：dockerui
dockerui='index.tenxcloud.com/tenxcloud/dockerui'
docker pull $dockerui
docker run -d --name dockerui -p 9000:9000 --privileged -v /var/run/docker.sock:/var/run/docker.sock $dockerui

#开机自启动
echo '' >> /etc/rc.d/rc.local
echo 'docker start dockerui' >> /etc/rc.d/rc.local
echo "let's visit the http://127.0.0.1:9000 to enjoy you docker ..."

#列一下现在有什么镜像
docker images

#国内docker镜像网站
#https://hub.tenxcloud.com/
#https://hub.daocloud.io/
#https://c.163.com/hub