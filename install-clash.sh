#linux clash
#运行例子：mkdir -p /shell && cd /shell && rm -rf install-clash.sh && wget --no-cache https://raw.staticdn.net/share-group/shell/master/install-clash.sh && sh install-clash.sh 1.11.4 /usr/local/clash
 
#定义本程序的当前目录
base_path=$(pwd)

#处理外部参数
clash_version=$1
clash_install_path=$2
if [ ! $clash_version ] || [ ! $clash_install_path ]; then
	echo 'error command!!! you must input clash version and install path...'
	echo 'for example: sh install-clash.sh 1.11.4 /usr/local/clash'
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

rm -rf $clash_install_path
mkdir -p $clash_install_path/bin
cd $clash_install_path/bin && gzip -cd $base_path/$clash > clash && chmod 777 clash || exit
cd /usr/bin && rm -rf clash && ln -s $clash_install_path/bin/clash clash && chmod 777 clash || exit
clash -v

#下载GeoIp数据库
geoip_version='20230616'
cd $base_path && wget --no-check-certificate --no-cache https://install.ruanzhijun.cn/GeoLite2-Country_$geoip_version.tar.gz && tar zxvf $base_path/GeoLite2-Country_$geoip_version.tar.gz -C $install_path || exit
mkdir -p $clash_config_path && cd $clash_config_path && rm -rf config.yaml Country.mmdb && wget -O config.yaml https://install.ruanzhijun.cn/config.yaml && cp -rf $install_path/GeoLite2-Country_$geoip_version/GeoLite2-Country.mmdb ./Country.mmdb || exit

#加入系统服务
echo '[Unit]' > /etc/systemd/system/clash.service
echo 'Description=clash' >> /etc/systemd/system/clash.service
echo '[Service]' >> /etc/systemd/system/clash.service
echo 'OOMScoreAdjust=-1000' >> /etc/systemd/system/clash.service
echo 'ExecStart=/usr/local/clash/bin/clash -d /root/.config/clash' >> /etc/systemd/system/clash.service
echo 'Restart=on-failure' >> /etc/systemd/system/clash.service
echo 'RestartSec=5' >> /etc/systemd/system/clash.service
echo '[Install]' >> /etc/systemd/system/clash.service
echo 'WantedBy=multi-user.target' >> /etc/systemd/system/clash.service
systemctl daemon-reload && systemctl enable clash && systemctl restart clash && systemctl status clash

#安装图形界面
cd $clash_install_path && wget --no-check-certificate --no-cache https://install.ruanzhijun.cn/clash-dashboard-master.zip || exit
cd $clash_install_path && unzip clash-dashboard-master.zip && cd clash-dashboard-master && npm --registry https://registry.npm.taobao.org i --force && npm run build || exit
cd $clash_install_path && cp -rf clash-dashboard-master/dist ./dashboard && rm -rf clash-dashboard-master* || exit

#测试vpn是否成功
echo '正在测试 clash 是否安装成功...' && sleep 5 && curl -x http://127.0.0.1:7890 --connect-timeout 5 -m 5 https://www.google.com || (echo 'clash 安装失败...' && exit 1) && echo 'clash 安装成功...'

#开机自启动
echo 'systemctl start clash' >> /etc/rc.d/rc.local
$(source /etc/rc.d/rc.local)