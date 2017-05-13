#linux gradle
#运行例子：sh install-casperjs.sh 1.1.3 /usr/local
 
#定义本程序的当前目录
base_path=$(pwd)
ntpdate ntp.api.bz

#处理外部参数
casperjs_install_version=$1
casperjs_install_path=$2
if [ ! $casperjs_install_version ] || [ ! $casperjs_install_path ]; then
	echo 'error command!!! you must input casperjs version and install path...'
	echo 'for example: sh install-casperjs.sh 1.1.3 /usr/local'
	exit
fi

#建立临时安装目录
echo 'preparing working path...'
install_path='/install'
rm -rf $install_path
mkdir -p $install_path

#下载casperjs
casperjs='casperjs-'$casperjs_install_version
echo 'installing '$casperjs' ...'
if [ ! -f $base_path/$casperjs.zip ]; then
	echo $casperjs'.zip is not exists, system will going to download it...'
	wget -O $install_path/$casperjs.zip http://install.ruanzhijun.cn/$casperjs.zip || exit
	echo 'download '$casperjs' finished...'
fi
cd $install_path
unzip $casperjs.zip
rm -rf $casperjs_install_path/casperjs
mkdir -p $casperjs_install_path/casperjs
yes|cp -rf $casperjs/* $casperjs_install_path/casperjs/
cd /usr/bin/
ln -s $casperjs_install_path/casperjs/bin/casperjs casperjs

echo 'casperjs version: '
casperjs --version


