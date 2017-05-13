#linux gradle
#运行例子：sh install-phantomjs.sh 2.1.1 /usr/local
 
#定义本程序的当前目录
base_path=$(pwd)
ntpdate ntp.api.bz

#处理外部参数
phantomjs_install_version=$1
phantomjs_install_path=$2
if [ ! $phantomjs_install_version ] || [ ! $phantomjs_install_path ]; then
	echo 'error command!!! you must input phantomjs version and install path...'
	echo 'for example: sh install-phantomjs.sh 2.1.1 /usr/local'
	exit
fi

#建立临时安装目录
echo 'preparing working path...'
install_path='/install'
rm -rf $install_path
mkdir -p $install_path

#下载phantomjs
phantomjs='phantomjs-'$phantomjs_install_version
echo 'installing '$phantomjs' ...'
if [ ! -f $base_path/$phantomjs-linux-x86_64.tar ]; then
	echo $phantomjs'-linux-x86_64.tar is not exists, system will going to download it...'
	wget -O $base_path/$phantomjs-linux-x86_64.tar http://install.ruanzhijun.cn/$phantomjs-linux-x86_64.tar || exit
	echo 'download '$phantomjs' finished...' 
fi
tar xvf $base_path/$phantomjs-linux-x86_64.tar -C $install_path || exit
cd $install_path
rm -rf $phantomjs_install_path/phantomjs
mv $phantomjs-linux-x86_64 phantomjs
cp -rf phantomjs $phantomjs_install_path/
cd /usr/bin/
rm -rf phantomjs
ln -s $phantomjs_install_path/phantomjs/bin/phantomjs phantomjs

echo 'phantomjs version: '
phantomjs -v


