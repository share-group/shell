#linux rancher自动安装程序 
#运行例子：mkdir -p /shell && cd /shell && rm -rf install-rancher.sh && wget --no-cache https://raw.githubusercontent.com/share-group/shell/master/docker/install-rancher.sh && sh install-rancher.sh /usr/local

#处理外部参数
rancher_install_path=$1
if [ ! $rancher_install_path ]; then
	echo 'error command!!! you must input rancher install path...'
	echo 'for example: sh install-rancher.sh /usr/local'
	exit
fi
 
#建立临时安装目录
echo 'preparing working path...'
mkdir -p $rancher_install_path/rancher/log

#拉取镜像
docker pull rancher/rancher

#启动rancher
docker run --name rancher -d --restart=unless-stopped -p 80:80 -p 443:443 -v $rancher_install_path/rancher:/var/lib/rancher -v $rancher_install_path/rancher/log/auditlog:/var/log/auditlog -e AUDIT_LEVEL=3 rancher/rancher