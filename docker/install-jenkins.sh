#linux jenkins自动安装程序 
#运行例子：mkdir -p /shell && cd /shell && rm -rf install-jenkins.sh && wget --no-cache https://raw.githubusercontent.com/share-group/shell/master/docker/install-jenkins.sh && sh install-jenkins.sh 2.32.3 /usr/local

#处理外部参数
jenkins_version=$1
jenkins_install_path=$2
if [ ! $jenkins_version ] || [ ! $jenkins_install_path ]; then
	echo 'error command!!! you must input jenkins install path...'
	echo 'for example: sh install-jenkins.sh 2.32.3 /usr/local'
	exit
fi
 
#建立临时安装目录
echo 'preparing working path...'
install_path='/install'
rm -rf $install_path
mkdir -p $install_path

mkdir -p $jenkins_install_path/jenkins

#用docker安装
docker pull hub.c.163.com/library/jenkins:$jenkins_version

#启动jenkins
docker run --name jenkins -p 8080:8080 -v $jenkins_install_path/jenkins jenkins -d hub.c.163.com/library/jenkins:$jenkins_version

#开机自启动
echo '' >> /etc/rc.d/rc.local
echo 'docker start jenkins' >> /etc/rc.local