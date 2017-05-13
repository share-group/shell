#linux twemproxy自动安装程序
#运行例子：sh install-twemproxy.sh /usr/local
 
#定义本程序的当前目录
base_path=$(pwd)
ntpdate ntp.api.bz

#处理外部参数
twemproxy_install_path=$1
if [ ! $twemproxy_install_path ]; then
	echo 'error command!!! you must input twemproxy install path...'
	echo 'for example: sh install-twemproxy.sh /usr/local'
	exit
fi

#建立临时安装目录
echo 'preparing working path...'
install_path='/install'
rm -rf $install_path
mkdir -p $install_path

yum -y install libtool sed gcc gcc-c++ make net-snmp net-snmp-devel net-snmp-utils libc6-dev python-devel rsync perl bc libxslt-dev lrzsz

#用git拉取
cd $base_path
if [ ! -d $base_path/twemproxy ]; then
	git clone https://github.com/twitter/twemproxy.git
fi
yes | cp -rf twemproxy $install_path/twemproxy

#安装twemproxy
cd $install_path/twemproxy
rm -rf $twemproxy_install_path/twemproxy
autoreconf -fvi && CFLAGS="-O3 -fno-strict-aliasing" ./configure --prefix=$twemproxy_install_path/twemproxy && make && make install || exit
yes|cp -rf $twemproxy_install_path/twemproxy/sbin/* /usr/bin/
nutcracker -V

#生成配置文件
echo 'create nutcracker.yml ...'
mkdir -p $twemproxy_install_path/twemproxy/conf
echo 'example:
   listen: 0.0.0.0:33333
   hash: fnv1_64
   hash_tag: "{}"
   distribution: ketama
   auto_eject_hosts: true
   preconnect: true
   server_connections: 50
   timeout: 2000
   backlog: 512
   redis: true
   server_retry_timeout: 2000
   server_failure_limit: 1
   servers:
      - 127.0.0.1:6379:1
' > $twemproxy_install_path/twemproxy/conf/nutcracker.yml || exit

#开机自启动
echo '' >> /etc/rc.local
echo 'nutcracker -d -v 11 -c '$twemproxy_install_path'/twemproxy/conf/nutcracker.yml -p '$twemproxy_install_path'/twemproxy/nutcracker.pid -o '$twemproxy_install_path'/twemproxy/nutcracker.log' >> /etc/rc.local
$(source /etc/rc.local)