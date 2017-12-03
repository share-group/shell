#linux gitlab自动安装程序 
#运行例子：mkdir -p /shell && cd /shell && rm -rf install-gitlab.sh && wget --no-cache https://raw.githubusercontent.com/share-group/shell/master/docker/install-gitlab.sh && sh install-gitlab.sh /usr/local

#处理外部参数
gitlab_install_path=$1
if [ ! $gitlab_install_path ]; then
	echo 'error command!!! you must input gitlab install path...'
	echo 'for example: sh install-gitlab.sh /usr/local'
	exit
fi

#建立临时安装目录
echo 'preparing working path...'
install_path='/install'
rm -rf $install_path $gitlab_install_path/gitlab
mkdir -p $install_path
mkdir -p $gitlab_install_path/gitlab/data
mkdir -p $gitlab_install_path/gitlab/logs
mkdir -p $gitlab_install_path/gitlab/config

#拉取镜像
docker pull gitlab/gitlab-ce

#启动gitlab
docker run -d --name gitlab -p 10080:80 --restart always -v $gitlab_install_path/gitlab/config:/etc/gitlab -v $gitlab_install_path/gitlab/logs:/var/log/gitlab -v $gitlab_install_path/gitlab/data:/var/opt/gitlab gitlab/gitlab-ce

# 可能需要设置防火墙
# *nat
# :PREROUTING ACCEPT [27:11935]
# :INPUT ACCEPT [0:0]
# :OUTPUT ACCEPT [598:57368]
# :POSTROUTING ACCEPT [591:57092]
# :DOCKER - [0:0]
# -A PREROUTING -m addrtype --dst-type LOCAL -j DOCKER
# -A OUTPUT ! -d 127.0.0.0/8 -m addrtype --dst-type LOCAL -j DOCKER
# -A POSTROUTING -s 172.17.0.0/16 ! -o docker0 -j MASQUERADE
# COMMIT
# *filter
# :INPUT ACCEPT [0:0]
# :FORWARD ACCEPT [0:0]
# :OUTPUT ACCEPT [0:0]
# :DOCKER - [0:0]
# -A FORWARD -o docker0 -j DOCKER
# -A FORWARD -o docker0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
# -A FORWARD -i docker0 ! -o docker0 -j ACCEPT
# -A FORWARD -i docker0 -o docker0 -j ACCEPT
# -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
# -A INPUT -p icmp -j ACCEPT
# -A INPUT -i lo -j ACCEPT
# -A INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
# -A INPUT -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT
# -A INPUT -p tcp -m state --state NEW -m tcp --dport 500 -j ACCEPT
# -A INPUT -p tcp -m state --state NEW -m tcp --dport 4500 -j ACCEPT
# -A INPUT -j REJECT --reject-with icmp-host-prohibited
# -A FORWARD -j REJECT --reject-with icmp-host-prohibited
# COMMIT