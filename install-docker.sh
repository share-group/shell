#linux docker
#运行例子：mkdir -p /shell && cd /shell && rm -rf install-docker.sh && wget --no-cache https://raw.githubusercontent.com/share-group/shell/master/install-docker.sh && sh install-docker.sh

#定义本程序的当前目录
base_path=$(pwd)

install_path='/install'
rm -rf $install_path
mkdir -p $install_path

#安装docker
yum remove -y docker docker-common docker-selinux docker-engine docker-ce
yum install -y yum-utils device-mapper-persistent-data lvm2 wget
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum-config-manager --enable docker-ce-edge
yum-config-manager --enable docker-ce-testing
yum-config-manager --disable docker-ce-edge
yum makecache fast
yum install -y docker-ce
systemctl restart docker
docker -v
docker info

#解决docker日志过大的问题
mkdir -p /etc/docker
echo '{"registry-mirrors":["http://f1361db2.m.daocloud.io"],"log-driver":"json-file","log-opts":{"max-size":"1g","max-file":"10"}}' > /etc/docker/daemon.json

#重启docker
systemctl restart docker

#安装docker-compose
cd $install_path && wget --no-cache https://github.com/docker/compose/releases/download/1.24.1/docker-compose-Linux-x86_64
mv $install_path/docker-compose-Linux-x86_64 /usr/bin/docker-compose
chmod 777 /usr/bin/docker-compose
docker-compose -v

#开机自启动
echo 'systemctl start docker' >> /etc/rc.local

