#linux gitlab自动安装程序 
#运行例子：mkdir -p /shell && cd /shell && rm -rf install-gitlab.sh && wget --no-cache https://raw.githubusercontent.com/share-group/shell/master/docker/install-gitlab.sh && sh install-gitlab.sh /usr/local

#处理外部参数
gitlab_install_path=$1
if [ ! $gitlab_install_path ]; then
	echo 'error command!!! you must input gitlab install path...'
	echo 'for example: sh install-gitlab.sh /usr/local'
	exit
fi

#建立临时安装目录
echo 'preparing working path...'
install_path='/install'

#建立安装目录
rm -rf $install_path $gitlab_install_path/gitlab
mkdir -p $install_path
mkdir -p $gitlab_install_path/gitlab/data
mkdir -p $gitlab_install_path/gitlab/logs
mkdir -p $gitlab_install_path/gitlab/config
cat > $gitlab_install_path/gitlab/docker-compose.yml <<EOF
version: '3.8'

services:
  gitlab:
    image: gitlab/gitlab-ce:latest
    container_name: gitlab
    restart: always
    hostname: gitlab.ruanzhijun.cn
    shm_size: '256m'
    ports:
      - "80:80"
      - "443:443"
      - "2222:22"
    volumes:
      - $gitlab_install_path/gitlab/config:/etc/gitlab
      - $gitlab_install_path/gitlab/logs:/var/log/gitlab
      - $gitlab_install_path/gitlab/data:/var/opt/gitlab
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://gitlab.ruanzhijun.cn'
        gitlab_rails['gitlab_shell_ssh_port'] = 2222
        nginx['ssl_certificate'] = "/etc/gitlab/ssl/gitlab.example.com.crt"
		nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/gitlab.example.com.key"
        #letsencrypt['enable'] = true
        #letsencrypt['contact_emails'] = ['ruanzhijun@ruanzhijun.cn']
EOF
cd $gitlab_install_path/gitlab && docker compose up -d

#获取初始密码：docker exec -it gitlab cat /etc/gitlab/initial_root_password
#更新https证书：docker exec -it gitlab gitlab-ctl reconfigure