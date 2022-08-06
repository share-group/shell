#linux clash
#运行例子：mkdir -p /shell && cd /shell && rm -rf install-clash.sh && wget --no-cache https://raw.staticdn.net/share-group/shell/master/install-clash.sh && sh install-clash.sh 1.11.4 /usr/local
 
#定义本程序的当前目录
base_path=$(pwd)

#处理外部参数
clash_version=$1
clash_install_path=$2
if [ ! $clash_version ] || [ ! $clash_install_path ]; then
	echo 'error command!!! you must input clash version and install path...'
	echo 'for example: sh install-clash.sh 1.11.4 /usr/local'
	exit
fi

#建立临时安装目录
echo 'preparing working path...'
install_path='/install'
clash_config_path='/root/.config/clash'
rm -rf $install_path $clash_config_path
mkdir -p $install_path

#下载clash
clash='clash-linux-amd64-v'$clash_version'.gz'
if [ ! -d $install_path/$clash ]; then
	echo 'installing '$clash' ...'
	if [ ! -f $base_path/$clash ]; then
		echo $clash' is not exists, system will going to download it...'
		wget -O $base_path/$clash https://install.ruanzhijun.cn/$clash || exit
		echo 'download '$clash' finished...'
	fi
fi

rm -rf $clash_install_path/clash
mkdir -p $clash_install_path/clash/bin
cd $clash_install_path/clash/bin && gzip -cd $base_path/$clash > clash && chmod 777 clash || exit
cd /usr/bin && ln -s $clash_install_path/clash/bin/clash clash && chmod 777 clash || exit

#下载最新的国家ip数据库和配置文件
mkdir -p $clash_config_path && cd $clash_config_path && rm -rf config.yaml Country.mmdb && wget -O config.yaml https://install.ruanzhijun.cn/config.yml && wget -O Country.mmdb https://install.ruanzhijun.cn/GeoLite2-Country.mmdb || exit
clash -v && clash

#开机自启动
echo '' >> /etc/rc.d/rc.local
echo 'clash' >> /etc/rc.d/rc.local
$(source /etc/rc.d/rc.local)