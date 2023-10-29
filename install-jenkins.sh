#linux jenkins
#运行例子：mkdir -p /shell && cd /shell && rm -rf install-jenkins.sh && wget --no-cache https://raw.staticdn.net/share-group/master/shell/install-jenkins.sh && sh install-jenkins.sh /usr/local
 
#定义本程序的当前目录
base_path=$(pwd)

#处理外部参数
jenkins_install_path=$1
if [ ! $jenkins_install_path ]; then
	echo 'error command!!! you must input install path...'
	echo 'for example: sh install-jenkins.sh /usr/local'
	exit
fi

#建立临时安装目录
echo 'preparing working path...'
install_path='/install'
rm -rf $install_path
mkdir -p $install_path

#下载jenkins
jenkins='jenkins.war'
if [ ! -d $install_path/$jenkins ]; then
	echo 'installing '$jenkins' ...'
	if [ ! -f $base_path/$jenkins ]; then
		echo $jenkins' is not exists, system will going to download it...'
		wget -O $base_path/$jenkins https://install.ruanzhijun.cn/$jenkins || exit
		echo 'download '$jenkins' finished...'
	fi
fi

#查询cpu逻辑个数
cpus=$(nproc --all)

thread=`expr 4 \* $cpus`

memory='-Xms192m -Xmx192m'

jvm='-XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+PrintGCApplicationStoppedTime -XX:+PrintGCApplicationConcurrentTime -XX:+PrintHeapAtGC -XX:ParallelGCThreads='$thread' -XX:CompileThreshold='$thread' -XX:+UseParallelGC -XX:+AggressiveOpts -XX:+UseBiasedLocking -XX:+UseFastAccessorMethods -XX:+DoEscapeAnalysis'


rm -rf $jenkins_install_path/jenkins /root/.jenkins
mkdir -p $jenkins_install_path/jenkins
cp -rf $base_path/$jenkins $jenkins_install_path/jenkins
cd $jenkins_install_path/jenkins
echo "
#!/bin/bash
processlist=\$(ps -ef|grep jenkins|grep -v grep|awk '{print \$2}')
for proc in \$processlist
do
	kill -15 \$proc
	echo 'kill -15 '\$proc
done

nohup java -jar -Xverify:none -server $memory $jvm $jenkins_install_path/jenkins/jenkins.war > /dev/null 2>&1 &
" > start.sh
chmod 777 start.sh
sh start.sh