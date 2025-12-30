#linux java
#运行例子：mkdir -p /shell && cd /shell && rm -rf install-go.sh && wget --no-cache https://raw.githubusercontent.com/share-group/shell/master/install-go.sh && sh install-go.sh 1.21.0 /usr/local
 
#定义本程序的当前目录
base_path=$(pwd)

#处理外部参数
go_version=$1
go_install_path=$2
if [ ! $go_version ] || [ ! $go_install_path ]; then
	echo 'error command!!! you must input nginx version and install path...'
	echo 'for example: sh install-go.sh 1.21.0 /usr/local'
	exit
fi

#建立临时安装目录
echo 'preparing working path...'
install_path='/install'
rm -rf $install_path
mkdir -p $install_path

#下载java
echo 'installing '$go_version' ...'

if [ ! -f $base_path/'go'$go_version'.linux-amd64.tar.gz' ]; then
	echo $base_path/'go'$go_version'.linux-amd64.tar.gz is not exists, system will going to download it...'
	wget -O $base_path'/go'$go_version'.linux-amd64.tar.gz' 'https://install.ruanzhijun.cn/go'$go_version'.linux-amd64.tar.gz' || exit
	echo 'download go'$go_version'.linux-amd64.tar.gz finished...'
fi
tar zxvf 'go'$go_version'.linux-amd64.tar.gz' -C $go_install_path

echo "" >> /etc/profile
echo "# set golang environment" >> /etc/profile
echo "GOROOT="$go_install_path"/go" >> /etc/profile
mkdir -p /root/.config/go && echo "GOPATH=/root/.config/go" >> /etc/profile
echo "export GOROOT" >> /etc/profile
echo "export GOPATH" >> /etc/profile
echo "export PATH" >> /etc/profile
echo "PATH=\$GOROOT/bin:\$PATH" >> /etc/profile

go env -w GOARCH=amd64
go env -w GOBIN=$GOROOT\bin
go env -w GO111MODULE=on
go env -w GOPROXY=https://goproxy.cn,direct

source /etc/profile
echo 'go version:'
go version