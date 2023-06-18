#linux nodejs自动安装程序 
#运行例子：mkdir -p /shell && cd /shell && rm -rf install-nodejs.sh && wget --no-cache https://raw.staticdn.net/share-group/shell/master/install-nodejs.sh && sh install-nodejs.sh 20.3.0 /usr/local
 
#定义本程序的当前目录
base_path=$(pwd)

#处理外部参数
nodejs_version=$1
nodejs_install_path=$2
if [ ! $nodejs_version ] || [ ! $nodejs_install_path ]; then
	echo 'error command!!! you must input nodejs version and install path...'
	echo 'for example: sh install-nodejs.sh 20.3.0 /usr/local'
	exit
fi

#建立临时安装目录
echo 'preparing working path...'
install_path='/install'
rm -rf $install_path
mkdir -p $install_path

#安装nodejs
rm -rf $nodejs_install_path/nodejs
echo 'installing node-v'$nodejs_version' ...'
if [ ! -f $base_path/node-v$nodejs_version-linux-x64.tar.xz ]; then
	echo 'node-v'$nodejs_version'-linux-x64.tar.xz is not exists, system will going to download it...'
	wget -O $base_path/node-v$nodejs_version-linux-x64.tar.xz https://install.ruanzhijun.cn/node-v$nodejs_version-linux-x64.tar.xz || exit
	echo 'download node-v'$nodejs_version' finished...'
fi
xz -d node-v$nodejs_version-linux-x64.tar.xz
tar -xvf $base_path/node-v$nodejs_version-linux-x64.tar || exit
mv node-v$nodejs_version-linux-x64 nodejs
mv nodejs $nodejs_install_path/

#添加环境变量
echo 'PATH=$PATH:'$nodejs_install_path'/nodejs/bin' >> /etc/profile || exit
source /etc/profile || exit

#更新npm版本
npm --registry https://registry.npm.taobao.org i -g --omit=dev npm
echo 'node version: '$(node -v)
echo 'npm version: '$(npm -v)

#搭建私有npm
# http://blog.fens.me/nodejs-cnpm-npm/