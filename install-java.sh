#linux java
#运行例子：mkdir -p /shell && cd /shell && rm -rf install-java.sh && wget --no-cache https://raw.githubusercontent.com/share-group/shell/master/install-java.sh && sh install-java.sh /usr/local
 
#定义本程序的当前目录
base_path=$(pwd)
ntpdate ntp.api.bz

#处理外部参数
java_install_path=$1
if [ ! $java_install_path ]; then
	echo 'error command!!! you must input java install path...'
	echo 'for example: sh install-java.sh /usr/local'
	exit
fi

#建立临时安装目录
echo 'preparing working path...'
install_path='/install'
rm -rf $install_path
mkdir -p $install_path

#下载java
jdk='jdk-10.0.2_linux-x64_bin'
echo 'installing '$jdk' ...'
if [ ! -f $base_path/$jdk.tar.gz ]; then
	echo $jdk'.tar.gz is not exists, system will going to download it...'
	wget -O $base_path/$jdk.tar.gz http://install.ruanzhijun.cn/$jdk.tar.gz || exit
	echo 'download '$jdk'.tar.gz finished...'
fi
tar zxvf $jdk.tar.gz -C $java_install_path

echo "" >> /etc/profile
echo "# set Java environment" >> /etc/profile
echo "JAVA_HOME="$java_install_path"/jdk-10.0.2" >> /etc/profile
echo "PATH=\$JAVA_HOME/bin:\$PATH" >> /etc/profile
echo "export JAVA_HOME" >> /etc/profile
echo "export PATH" >> /etc/profile
echo "export CLASSPATH" >> /etc/profile

source /etc/profile
echo 'java version:'
java -version