#linux nsq
#运行例子：mkdir -p /shell && cd /shell && rm -rf install-nsq.sh && wget --no-cache https://raw.githubusercontent.com/ruanzhijun/share/master/shell/install-nsq.sh && sh install-nsq.sh
 
#定义本程序的当前目录
base_path=$(pwd)
ntpdate ntp.api.bz

#建立临时安装目录
echo 'preparing working path...'
install_path='/install'
rm -rf $install_path
mkdir -p $install_path
nsq_install_path='/usr/local' 

# 安装nsq
nsq_version='nsq-1.0.0-compat.linux-amd64.go1.8'
rm -rf /usr/bin/nsq*
if [ ! -f $base_path/nsq.tar.gz ]; then
	wget -O $base_path/nsq.tar.gz http://install.ruanzhijun.cn/$nsq_version.tar.gz
fi

tar zxvf $base_path/nsq.tar.gz -C $install_path || exit

rm -rf $nsq_install_path/nsq
mkdir -p $nsq_install_path/nsq/data

mv $install_path/$nsq_version/ $install_path/nsq
mv $install_path/nsq/* $nsq_install_path/nsq/
chmod -R 777 $nsq_install_path/nsq/bin/*
yes | cp -rf $nsq_install_path/nsq/bin/* /usr/bin/

#生成启动nsq脚本
rm -rf $nsq_install_path/nsq/start.sh
echo 'cd '$nsq_install_path'/nsq/' >> $nsq_install_path/nsq/start.sh
echo "#!/bin/bash" >> $nsq_install_path/nsq/start.sh
echo "list=\$(ps -ef|grep nsq|grep start|grep -v grep|awk '{print \$2}')" >> $nsq_install_path/nsq/start.sh
echo "for proc in \$list" >> $nsq_install_path/nsq/start.sh
echo "do" >> $nsq_install_path/nsq/start.sh
echo "	kill -15 \$proc" >> $nsq_install_path/nsq/start.sh
echo "done" >> $nsq_install_path/nsq/start.sh
echo 'nsqlookupd -http-address=0.0.0.0:4161 -tcp-address=0.0.0.0:4160 &' >> $nsq_install_path/nsq/start.sh
echo 'sleep 2' >> $nsq_install_path/nsq/start.sh
echo 'nsqd -http-address=0.0.0.0:4151 -tcp-address=0.0.0.0:4150 --lookupd-tcp-address=127.0.0.1:4160 -broadcast-address=127.0.0.1 &' >> $nsq_install_path/nsq/start.sh
echo 'sleep 2' >> $nsq_install_path/nsq/start.sh
echo 'nsqadmin --lookupd-http-address=0.0.0.0:4161 -http-address=0.0.0.0:4171 &' >> $nsq_install_path/nsq/start.sh
echo 'sleep 2' >> $nsq_install_path/nsq/start.sh
echo 'nsq_to_file --output-dir='$nsq_install_path'/nsq/data --lookupd-http-address=127.0.0.1:4161 &' >> $nsq_install_path/nsq/start.sh
chmod 777 $nsq_install_path/nsq/start.sh
$nsq_install_path/nsq/start.sh