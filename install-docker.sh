#linux docker
#运行例子：mkdir -p /shell && cd /shell && rm -rf install-docker.sh && wget --no-cache https://raw.githubusercontent.com/share-group/shell/master/install-docker.sh && sh install-docker.sh

#定义本程序的当前目录
base_path=$(pwd)

#安装docker
yum remove -y docker docker-common docker-selinux docker-engine docker-ce
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum-config-manager --enable docker-ce-edge
yum-config-manager --enable docker-ce-testing
yum-config-manager --disable docker-ce-edge
yum makecache fast
yum install -y docker-ce
systemctl restart docker
docker -v
docker info

#加速器
curl -sSL https://get.daocloud.io/daotools/set_mirror.sh | sh -s http://30c125e3.m.daocloud.io

#重启docker
systemctl restart docker

#安装docker-compose
pip uninstall urllib3 -y 
pip uninstall chardet -y
pip install requests
pip install docker-compose

#安装基础镜像alpine
docker pull alpine

#开机自启动
chkconfig --level 35 iptables off
echo '' >> /etc/rc.local
echo 'chkconfig --level 35 iptables off' >> /etc/rc.local
echo 'systemctl start docker' >> /etc/rc.local

