#linux rancher自动安装程序 
#运行例子：mkdir -p /shell && cd /shell && rm -rf install-rancher.sh && wget --no-cache https://raw.githubusercontent.com/share-group/shell/master/docker/install-rancher.sh && sh install-rancher.sh /usr/local

#处理外部参数
rancher_install_path=$1
if [ ! $rancher_install_path ]; then
	echo 'error command!!! you must input rancher install path...'
	echo 'for example: sh install-rancher.sh /usr/local'
	exit
fi

#定义本程序的当前目录
base_path=$(pwd)

#安装依赖
dnf install -y iptables iptables-services nftables kernel-modules-extra
alternatives --set iptables /usr/sbin/iptables-legacy
alternatives --set ip6tables /usr/sbin/ip6tables-legacy
modprobe ip_tables
modprobe iptable_nat
modprobe nf_nat
modprobe nf_conntrack
modprobe br_netfilter
cat <<EOF > /etc/sysctl.d/99-k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

#建立临时安装目录
echo 'preparing working path...'
install_path='/install'
rm -rf $install_path
mkdir -p $install_path

docker rm -f rancher
rm -rf $rancher_install_path/rancher
docker run -d --restart=unless-stopped \
  --name rancher \
  -p 8080:80 -p 8443:443 \
  -v $rancher_install_path/rancher:/var/lib/rancher \
  -v $rancher_install_path/rancher/log/auditlog:/var/log/auditlog \
  -e AUDIT_LEVEL=1 \
  --privileged \
  rancher/rancher