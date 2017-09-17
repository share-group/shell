#linux nginx自动安装程序 
#运行例子：mkdir -p /shell && cd /shell && rm -rf install-nginx.sh && wget --no-cache https://raw.githubusercontent.com/share-group/shell/master/install-nginx.sh && sh install-nginx.sh 1.13.5 /usr/local
ntpdate ntp.api.bz
 
#定义本程序的当前目录
base_path=$(pwd)  

#处理外部参数
nginx_version=$1
nginx_install_path=$2
if [ ! $nginx_version ] || [ ! $nginx_install_path ]; then
	echo 'error command!!! you must input nginx version and install path...'
	echo 'for example: sh install-nginx.sh 1.13.5 /usr/local'
	exit
fi

yum -y install gcc libc6-dev gcc-c++ make rsync lrzsz bzip2 unzip vim

#建立临时安装目录
echo 'preparing working path...'
install_path='/install'
rm -rf $install_path
mkdir -p $install_path

#下载zlib
zlib='zlib-1.2.10'
if [ ! -d $install_path/$zlib ]; then
	echo 'installing '$zlib' ...'
	if [ ! -f $base_path/$zlib.tar.gz ]; then
		echo $zlib'.tar.gz is not exists, system will going to download it...'
		wget -O $base_path/$zlib.tar.gz http://install.ruanzhijun.cn/$zlib.tar.gz || exit
		echo 'download '$zlib' finished...'
	fi
	tar zxvf $base_path/$zlib.tar.gz -C $install_path || exit
fi

#下载pcre
pcre='pcre-8.41'
if [ ! -d $install_path/$pcre ]; then
	echo 'installing '$pcre' ...' 
	if [ ! -f $base_path/$pcre.tar.gz ]; then
		echo $pcre'.tar.gz is not exists, system will going to download it...'
		wget -O $base_path/$pcre.tar.gz http://install.ruanzhijun.cn/$pcre.tar.gz || exit
		echo 'download '$pcre' finished...'
	fi
	tar zxvf $base_path/$pcre.tar.gz -C $install_path || exit
fi 

#安装libiconv
if [ ! -d $nginx_install_path/libiconv ]; then
	libiconv='libiconv-1.14'
	if [ ! -f $base_path/$libiconv.tar.gz ]; then
		wget -O $base_path/$libiconv.tar.gz http://install.ruanzhijun.cn/$libiconv.tar.gz || exit
	fi
	tar zxvf $base_path/$libiconv.tar.gz -C $install_path || exit
	cd $install_path/$libiconv/srclib
	sed -i -e '/gets is a security/d' ./stdio.in.h
	cd $install_path/$libiconv
	./configure --prefix=$nginx_install_path/libiconv -enable-shared --host=arm-linux && make && make install || exit
	yes|cp $nginx_install_path/libiconv/bin/* /usr/bin/
fi

# 安装OpenSSL
openssl='openssl-1.1.0e'
if [ ! -d $nginx_install_path/openssl ]; then
	echo 'installing '$openssl' ...'
	if [ ! -f $base_path/$openssl.tar.gz ]; then
		echo $openssl'.tar.gz is not exists, system will going to download it...'
		wget -O $base_path/$openssl.tar.gz http://install.ruanzhijun.cn/$openssl.tar.gz || exit
		echo 'download '$openssl' finished...'
	fi
	tar zxvf $base_path/$openssl.tar.gz -C $install_path || exit
	cd $install_path/$openssl
	./config shared zlib --prefix=$nginx_install_path/openssl && $install_path/$openssl/config -t && make && make install || exit
	rm -rf /usr/bin/openssl && ln -s $nginx_install_path/openssl/bin/openssl /usr/bin/openssl
	rm -rf /usr/include/openssl && ln -s $nginx_install_path/openssl/include/openssl /usr/include/openssl
	rm -rf /usr/lib64/libssl.so.1.1 && ln -s $nginx_install_path/openssl/lib/libssl.so.1.1 /usr/lib64/libssl.so.1.1
	rm -rf /usr/lib64/libcrypto.so.1.1 && ln -s $nginx_install_path/openssl/lib/libcrypto.so.1.1 /usr/lib64/libcrypto.so.1.1
	echo $nginx_install_path"/openssl/lib" >> /etc/ld.so.conf
	ldconfig -v
	yes|cp $nginx_install_path/openssl/bin/* /usr/bin/
	echo $openssl' install finished...'
	
	#再解压一次给nginx编译用
	rm -rf $install_path/$openssl
	tar zxvf $base_path/$openssl.tar.gz -C $install_path || exit
fi

#安装libatomic
libatomic='libatomic_ops-1.1'
if [ ! -d $install_path/$libatomic ]; then
	echo 'installing '$libatomic' ...'
	if [ ! -f $base_path/$libatomic.tar.gz ]; then
		echo $libatomic'.tar.gz is not exists, system will going to download it...'
		wget -O $base_path/$libatomic.tar.gz http://install.ruanzhijun.cn/$libatomic.tar.gz || exit
		echo 'download '$libatomic' finished...'
	fi
	tar zxvf $base_path/$libatomic.tar.gz -C $install_path || exit
fi

#安装nginx
nginx='nginx-'$nginx_version
echo 'installing '$nginx' ...'
if [ ! -d $nginx_install_path/nginx ]; then
	if [ ! -f $base_path/$nginx.tar.gz ]; then
		echo $nginx'.tar.gz is not exists, system will going to download it...'
		wget -O $base_path/$nginx.tar.gz http://install.ruanzhijun.cn/$nginx.tar.gz || exit
		echo 'download '$nginx' finished...'
	fi
	tar zxvf $base_path/$nginx.tar.gz -C $install_path || exit
fi
cd $install_path/$nginx
./configure --prefix=$nginx_install_path/nginx --with-http_stub_status_module --with-ld-opt="-Wl,-E" --with-http_v2_module --with-select_module --with-poll_module --with-file-aio --with-ipv6 --with-http_gzip_static_module --with-http_image_filter_module --with-http_sub_module --with-http_ssl_module --with-pcre=$install_path/$pcre --with-zlib=$install_path/$zlib --with-openssl=$install_path/$openssl --with-md5=/usr/lib --with-sha1=/usr/lib --with-md5-asm --with-sha1-asm --with-mail --with-mail_ssl_module --with-http_realip_module --with-http_perl_module --with-http_addition_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_random_index_module --with-http_secure_link_module --with-http_degradation_module --with-http_stub_status_module --with-stream --with-stream_ssl_module --with-libatomic=$install_path/$libatomic && make && make install || exit

#写入nginx配置文件
echo 'create nginx.conf...'
ulimit='65535' #单个进程最大打开文件数
worker_processes=$(cat /proc/cpuinfo | grep name | cut -f3 -d: | uniq -c | cut -b 7) #查询cpu逻辑个数
echo "user root root;
worker_cpu_affinity auto;
worker_processes "$worker_processes";
worker_rlimit_nofile "$ulimit";

events {
	use epoll;
	accept_mutex off;
	worker_connections "$ulimit";
}

http {
	include mime.types;
	charset utf-8;
	default_type application/octet-stream;
	access_log off;
	error_log "$nginx_install_path"/nginx/logs/error.log crit;
	sendfile on;
	tcp_nopush on;
	tcp_nodelay on;
	keepalive_timeout 60;
	client_header_buffer_size 32k;
	client_max_body_size 200m;
	
	add_header Cache-Control no-store,no-cache,must-revalidate,max-age=0;
	
	proxy_set_header  X-Real-IP \$remote_addr;
	proxy_set_header  X-Forwarded-For \$proxy_add_x_forwarded_for;
	
	fastcgi_connect_timeout 600;
	fastcgi_send_timeout 600;
	fastcgi_read_timeout 600;
	fastcgi_buffer_size 64k;
	fastcgi_buffers 4 64k;
	fastcgi_busy_buffers_size 128k;
	fastcgi_temp_file_write_size 128k;

	gzip on;
	gzip_min_length 10k;
	gzip_buffers 4 16k;
	gzip_http_version 1.0;
	gzip_comp_level 4;
	gzip_types text/plain application/x-javascript text/css application/xml;
	gzip_vary on;	

	server_tokens off;    
	   
	include "$nginx_install_path"/nginx/conf/web/*.conf;
}
" > $nginx_install_path/nginx/conf/nginx.conf || exit
rm -rf $nginx_install_path/nginx/conf/web/
mkdir $nginx_install_path/nginx/conf/web/
echo 'create nginx.conf finished...'

#创建网站文件存放目录
echo 'create www_root...'
web_root='www'
mv $nginx_install_path/nginx/html $nginx_install_path/nginx/$web_root
echo "<?php phpinfo(); ?>" > $nginx_install_path/nginx/$web_root/phpinfo.php || exit

#创建一个80端口的配置文件(作为demo)
echo 'create a demo conf , 80.conf...'
echo '
#80
server {
	listen 80;
	server_name _;
	root '$web_root';
	#autoindex on; #无index时是否显示文件列表
	index index.html index.php;

	location ~ \.php$ {
		fastcgi_pass 127.0.0.1:9000;
		fastcgi_index index.php;
		fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
		include fastcgi.conf;
	}
		
	#缓存网站素材
	#location ~ .*\.(gif|jpg|jpeg|png|bmp|swf|js|css)$ {
	#	expires 30d;
	#}
		
	#如果使用了伪静态，则可以保护这些文件的正常访问
	#location ~ /(images|css|js|swf|upload)/.*$ {
	#
	#}
		
	#禁止某些文件被访问
	#location ~ .*\.(txt|ico)$ {
	#	break;
	#}
	
	#需要用户名密码访问
	#location / {
	#		auth_basic "Authorized users only";
	#		auth_basic_user_file /usr/local/tengine/conf/web/htpasswd;  #密码文件格式：gatherup.cc:/XJt5jAl/dKTI
	#}
		
	#nginx 伪静态写法(一定要写在最后)
	#location ~ .*$ { 
	#	 rewrite ^/(.*)$ /index.php break;    #目录所有链接都指向index.php
	#	 fastcgi_pass  127.0.0.1:9000;
	#	 fastcgi_index index.php;
	#	 fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
	#	 include fastcgi.conf;
	#}
}
' > $nginx_install_path/nginx/conf/web/80.conf

#创建一个https的配置文件
echo 'create 443.conf...'

#首先自己生成证书，可以实现https，但是不受浏览器信任
echo "
#https
#server {
	#listen  443;
	#server_name _;
	#root  "$web_root";
	#index index.html index.php;
	
	#ssl on;
	#ssl_certificate /letsencrypt/letsencrypt/trustdream.chained.crt;
	#ssl_certificate_key /letsencrypt/letsencrypt/trustdream.com.key;
	#ssl_ciphers \"ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA\";
	#ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
	#ssl_dhparam /letsencrypt/letsencrypt/dhparam.lifution.pem;
	#ssl_prefer_server_ciphers on;
	#ssl_session_cache shared:SSL:10m;
	
	#ssl_stapling on;
	#ssl_stapling_verify on;
	#resolver 8.8.4.4 8.8.8.8 valid=300s;
    #resolver_timeout 10s;

	#add_header x-Content-Type-Options nosniff;
	#add_header X-Frame-Options deny;
	#add_header Strict-Transport-Security 'max-age=315360000; includeSubDomains; preload;';
#}" > $nginx_install_path/nginx/conf/web/443.conf

#修改环境变量
echo 'modify /etc/profile...'
echo "ulimit -SHn "$ulimit >> /etc/profile
$(source /etc/profile)

#启动nginx
yes|cp -rf $nginx_install_path/nginx/sbin/nginx /usr/bin/
nginx

#开机自启动
echo '' >> /etc/rc.d/rc.local
echo 'systemctl stop firewalld' >> /etc/rc.d/rc.local
echo 'nginx' >> /etc/rc.d/rc.local
$(source /etc/rc.d/rc.local)

##################### 自己给自己颁发证书的方法 ######################################
# 生成一个RSA密钥 
# $ openssl genrsa -des3 -out 33iq.key 1024
 
# 拷贝一个不需要输入密码的密钥文件
# $ openssl rsa -in 33iq.key -out 33iq_nopass.key
 
# 生成一个证书请求
# $ openssl req -new -key 33iq.key -out 33iq.csr
 
# 自己签发证书
# $ openssl x509 -req -days 365 -in 33iq.csr -signkey 33iq.key -out 33iq.crt
#第3个命令是生成证书请求，会提示输入省份、城市、域名信息等，重要的是，email一定要是你的域名后缀的。这样就有一个 csr 文件了，提交给 ssl 提供商的时候就是这个 csr 文件。当然我这里并没有向证书提供商申请，而是在第4步自己签发了证书。