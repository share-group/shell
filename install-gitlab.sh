#linux gitlab
#运行例子：mkdir -p /shell && cd /shell && rm -rf install-gitlab.sh && wget --no-cache https://raw.githubusercontent.com/share-group/shell/master/install-gitlab.sh && sh install-gitlab.sh
#定义本程序的当前目录
base_path=$(pwd)
ntpdate ntp.api.bz

#建立临时安装目录
echo 'preparing working path...'
install_path='/install'
rm -rf $install_path
mkdir -p $install_path
cd $install_path

yum -y install gcc libc6-dev gcc-c++ pcre-devel perl-devel nscd ImageMagick ImageMagick-devel perl-ExtUtils-Embed geoip-database python-devel gd-devel libgeoip-dev make libxslt-dev rsync lrzsz libxml2 libxml2-dev libxslt-dev libgd2-xpm libgd2-xpm-dev libpcre3 libpcre3-dev httpd-tools ruby ruby-devel rubygems rpm-build bc curl policycoreutils openssh-server openssh-clients postfix

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
	wget --no-cache http://install.ruanzhijun.cn/$gitlab || exit
fi
rpm -ivh $gitlab

gitlab-ctl reconfigure
gitlab-ctl restart

echo '' >> /etc/rc.local
echo 'gitlab-ctl start' >> /etc/rc.local