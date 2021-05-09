#linux gitlab
#运行例子：mkdir -p /shell && cd /shell && rm -rf install-gitlab.sh && wget --no-cache https://raw.staticdn.net/share-group/shell/master/install-gitlab.sh && sh install-gitlab.sh
#定义本程序的当前目录
base_path=$(pwd)

#建立临时安装目录
echo 'preparing working path...'
install_path='/install'
rm -rf $install_path
mkdir -p $install_path
cd $install_path

yum -y install curl curl-devel zlib-devel openssl-devel perl cpio expat-devel perl-ExtUtils-MakeMaker gettext-devel gcc libc6-dev gcc-c++ pcre-devel libgd2-xpm libgd2-xpm-dev geoip-database libgeoip-dev make libxslt-dev rsync lrzsz bzip2 unzip vim iptables-services httpd-tools ruby ruby-devel rubygems rpm-build bc perl-devel nscd ImageMagick ImageMagick-devel perl-ExtUtils-Embed python-devel gd-devel libxml2 libxml2-dev libpcre3 libpcre3-dev socat perl-CPAN libtool sed net-snmp net-snmp-devel net-snmp-utils ncurses-devel dos2unix texinfo policycoreutils openssh-server openssh-clients postfix bison

systemctl enable sshd
systemctl start sshd
systemctl enable postfix
systemctl start postfix
chkconfig postfix on

firewall-cmd --permanent --add-service=http
systemctl reload firewalld

cd $install_path
gitlab='gitlab-ce-11.3.4-ce.0.el7.x86_64.rpm'
if [ ! -f $install_path/$gitlab ]; then
	wget --no-cache https://install.ruanzhijun.cn/$gitlab || exit
fi
rpm -ivh $gitlab

gitlab-ctl reconfigure
gitlab-ctl restart

echo '' >> /etc/rc.local
echo 'gitlab-ctl start' >> /etc/rc.local