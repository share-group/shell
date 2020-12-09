#linux docker
#运行例子：mkdir -p /shell && cd /shell && rm -rf install-docker.sh && wget --no-check-certificate --no-cache https://raw.githubusercontent.com/share-group/shell/master/install-docker.sh && sh install-docker.sh
#rpm包下载地址：https://download.docker.com/linux/centos/7/x86_64/stable/Packages/
#定义本程序的当前目录
base_path=$(pwd)

install_path='/install'
rm -rf $install_path
mkdir -p $install_path

#安装docker
yum install -y podman-manpages || exit
yum install -y https://install.ruanzhijun.cn/containerd.io-1.2.13-3.2.el7.x86_64.rpm || exit
yum install -y https://install.ruanzhijun.cn/docker-ce-cli-20.10.0-3.el7.x86_64.rpm || exit
yum install -y https://install.ruanzhijun.cn/docker-ce-20.10.0-3.el7.x86_64.rpm || exit
systemctl restart docker || exit
docker -v || exit
docker info || exit

#解决docker日志过大的问题
mkdir -p /etc/docker
echo '{"storage-driver":"overlay2","storage-opts":["overlay2.override_kernel_check=true"],"registry-mirrors":["https://1nj0zren.mirror.aliyuncs.com"],"log-driver":"json-file","log-opts":{"max-size":"1g","max-file":"10"}}' > /etc/docker/daemon.json

#重启docker

systemctl daemon-reload && systemctl restart docker || exit

#安装docker-compose
cd /usr/bin && wget --no-check-certificate --no-cache https://install.ruanzhijun.cn/docker-compose && chmod 777 docker-compose || exit
docker-compose -v

#开机自启动
echo 'systemctl start docker' >> /etc/rc.local && chmod 777 /etc/rc.local

