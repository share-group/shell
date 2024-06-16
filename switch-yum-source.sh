#linux 切换yum源
#运行例子：mkdir -p /shell && cd /shell && rm -rf switch-yum-source.sh && wget --no-check-certificate --no-cache https://raw.githubusercontents.com/share-group/shell/master/switch-yum-source.sh && sh switch-yum-source.sh

cd /etc/yum.repos.d && echo "[baseos]
name=CentOS Stream $releasever - BaseOS
baseurl=https://mirrors.ustc.edu.cn/centos-stream/9-stream/BaseOS/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
[appstream]
name=CentOS Stream $releasever - AppStream
baseurl=https://mirrors.ustc.edu.cn/centos-stream/9-stream/AppStream/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial" > centos.repo

yum clean all && yum makecache && rm -rf /shell