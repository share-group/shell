#linux nodejs自动安装程序 
#运行例子：mkdir -p /shell && cd /shell && rm -rf install-nodejs.sh && wget --no-cache https://raw.githubusercontent.com/share-group/shell/master/install-nodejs.sh && sh install-nodejs.sh 8.5.0 /usr/local
ntpdate ntp.api.bz
 
#定义本程序的当前目录
base_path=$(pwd)

#处理外部参数
nodejs_version=$1
nodejs_install_path=$2
if [ ! $nodejs_version ] || [ ! $nodejs_install_path ]; then
	echo 'error command!!! you must input nodejs version and install path...'
	echo 'for example: sh install-nodejs.sh 8.5.0 /usr/local'
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
	wget -O $base_path/node-v$nodejs_version-linux-x64.tar.xz http://install.ruanzhijun.cn/node-v$nodejs_version-linux-x64.tar.xz || exit
	echo 'download node-v'$nodejs_version' finished...'
fi
xz -d node-v$nodejs_version-linux-x64.tar.xz
tar -xvf $base_path/node-v$nodejs_version-linux-x64.tar || exit
rm -rf /usr/bin/node
rm -rf /usr/bin/npm
mv node-v$nodejs_version-linux-x64 nodejs
mv nodejs $nodejs_install_path/
yes|cp -rf $nodejs_install_path/nodejs/bin/node /usr/bin/
ln -s $nodejs_install_path/nodejs/lib/node_modules/npm/bin/npm-cli.js /usr/bin/npm

#更新npm版本
npm config set registry https://registry.npm.taobao.org/
npm install npm yarn node-gyp pm2 -g
echo 'node version: '$(node -v)
echo 'npm version: '$(npm -v)
echo 'yarn version: '$(yarn -v)

#搭建私有npm
# http://blog.fens.me/nodejs-cnpm-npm/