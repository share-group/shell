#linux docker
#运行例子：mkdir -p /shell && cd /shell && rm -rf install-docker.sh && wget --no-check-certificate --no-cache https://raw.staticdn.net/share-group/shell/master/install-docker.sh && sh install-docker.sh
#定义本程序的当前目录
base_path=$(pwd)

install_path='/install'
rm -rf $install_path
mkdir -p $install_path

#更新yum源
yum install -y yum-utils || exit
yum-config-manager --add-repo https://install.ruanzhijun.cn/docker-ce.repo || exit
dnf makecache || exit

#安装docker
yum install -y --allowerasing docker-ce docker-ce-cli containerd.io || exit
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