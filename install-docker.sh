#linux docker
#运行例子：mkdir -p /shell && cd /shell && rm -rf install-docker.sh && wget --no-check-certificate --no-cache https://raw.staticdn.net/share-group/shell/master/install-docker.sh && sh install-docker.sh
#定义本程序的当前目录
base_path=$(pwd)

install_path='/install'
rm -rf $install_path
mkdir -p $install_path

#更新yum源
yum install -y yum-utils || exit
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo || exit
dnf makecache || exit

#安装docker
yum install -y --allowerasing docker-ce docker-ce-cli containerd.io || exit
systemctl restart docker || exit
docker -v || exit
docker info || exit

#给docker配置个VPN
#mkdir -p /etc/systemd/system/docker.service.d
#echo '[Service]' > /etc/systemd/system/docker.service.d/proxy.conf
#echo 'Environment="HTTP_PROXY=http://127.0.0.1:7890/"' >> /etc/systemd/system/docker.service.d/proxy.conf
#echo 'Environment="HTTPS_PROXY=http://127.0.0.1:7890/"' >> /etc/systemd/system/docker.service.d/proxy.conf
#echo 'Environment="NO_PROXY=localhost,127.0.0.1,.docker.com"' >> /etc/systemd/system/docker.service.d/proxy.conf

#解决docker日志过大的问题
mkdir -p /etc/docker
echo '{"storage-driver":"overlay2","log-driver":"json-file","log-opts":{"max-size":"1k","max-file":"1"}}' > /etc/docker/daemon.json || exit
systemctl daemon-reload && systemctl restart docker && docker info || exit

#安装docker-compose
cd /usr/bin && wget --no-check-certificate --no-cache https://install.ruanzhijun.cn/docker-compose && chmod 777 docker-compose || exit
docker-compose -v

#开机自启动
echo 'systemctl start docker' >> /etc/rc.local && chmod 777 /etc/rc.local || exit 