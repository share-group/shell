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

#配置加速器、解决docker日志过大的问题
mkdir -p /etc/docker
echo '{"storage-driver":"overlay2","registry-mirrors": ["https://8ci56u67.mirror.aliyuncs.com"],"log-driver":"json-file","log-opts":{"max-size":"1m","max-file":"1"}}' > /etc/docker/daemon.json || exit
systemctl daemon-reload && systemctl restart docker && docker info || exit

#安装docker-compose
cd /usr/bin && wget --no-check-certificate --no-cache https://install.ruanzhijun.cn/docker-compose && chmod 777 docker-compose || exit
docker-compose -v

#开机自启动
echo 'systemctl start docker' >> /etc/rc.local && chmod 777 /etc/rc.local || exit