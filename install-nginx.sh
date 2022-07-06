#linux nginx自动安装程序 
#运行例子：mkdir -p /shell && cd /shell && rm -rf install-nginx.sh && wget --no-check-certificate --no-cache https://raw.githubusercontents.com/share-group/shell/master/install-nginx.sh && sh install-nginx.sh 1.22.0 /usr/local
 
#定义本程序的当前目录
base_path=$(pwd)  

#处理外部参数
nginx_version=$1
nginx_install_path=$2
if [ ! $nginx_version ] || [ ! $nginx_install_path ]; then
	echo 'error command!!! you must input nginx version and install path...'
	echo 'for example: sh install-nginx.sh 1.22.0 /usr/local'
	exit
fi

worker_processes=$(cat /proc/cpuinfo | grep name | cut -f3 -d: | uniq -c | cut -b 7) #查询cpu逻辑个数
yum -y install wget gcc gcc-c++ make perl-core

#建立临时安装目录
echo 'preparing working path...'
install_path='/install'
rm -rf $install_path
mkdir -p $install_path

#下载zlib
zlib='zlib-1.2.12'
if [ ! -d $install_path/$zlib ]; then
	echo 'installing '$zlib' ...'
	if [ ! -f $base_path/$zlib.tar.gz ]; then
		echo $zlib'.tar.gz is not exists, system will going to download it...'
		wget -O $base_path/$zlib.tar.gz https://install.ruanzhijun.cn/$zlib.tar.gz || exit
		echo 'download '$zlib' finished...'
	fi
	tar zxvf $base_path/$zlib.tar.gz -C $install_path || exit
	cd $install_path/$zlib
	./configure --prefix=$nginx_install_path/zlib --shared && make -j $worker_processes && make test && make install || exit
	cp $install_path/$zlib/zutil.h /usr/local/include
	cp $install_path/$zlib/zutil.c /usr/local/include
	cp $nginx_install_path/zlib/include/zlib.h /usr/local/include
	cp $nginx_install_path/zlib/include/zconf.h /usr/local/include
	cd /usr/local/lib && ln -s $nginx_install_path/zlib/lib/libz.a libz.a
	cd /usr/local/lib && ln -s $nginx_install_path/zlib/lib/libz.so libz.so
	cd /usr/local/lib && ln -s $nginx_install_path/zlib/lib/libz.so.1 libz.so.1
	cd /usr/local/lib && ln -s $nginx_install_path/zlib/lib/libz.so.1.2.12 libz.so.1.2.12
	echo $nginx_install_path"/zlib/lib" >> /etc/ld.so.conf
	ldconfig
fi

#下载pcre
pcre='pcre2-10.37'
if [ ! -d $install_path/$pcre ]; then
	echo 'installing '$pcre' ...' 
	if [ ! -f $base_path/$pcre.tar.gz ]; then
		echo $pcre'.tar.gz is not exists, system will going to download it...'
		wget -O $base_path/$pcre.tar.gz https://install.ruanzhijun.cn/$pcre.tar.gz || exit
		echo 'download '$pcre' finished...'
	fi
	tar zxvf $base_path/$pcre.tar.gz -C $install_path || exit
fi 

#安装libiconv
if [ ! -d $nginx_install_path/libiconv ]; then
	libiconv='libiconv-1.17'
	if [ ! -f $base_path/$libiconv.tar.gz ]; then
		wget -O $base_path/$libiconv.tar.gz https://install.ruanzhijun.cn/$libiconv.tar.gz || exit
	fi
	tar zxvf $base_path/$libiconv.tar.gz -C $install_path || exit
	cd $install_path/$libiconv/srclib
	sed -i -e '/gets is a security/d' ./stdio.in.h
	cd $install_path/$libiconv
	./configure --prefix=$nginx_install_path/libiconv -enable-shared --host=arm-linux && make -j $worker_processes && make install || exit
	yes|cp $nginx_install_path/libiconv/bin/* /usr/bin/
fi

#安装jemalloc
jemalloc='jemalloc-5.3.0'
if [ ! -d $nginx_install_path/jemalloc ]; then
	if [ ! -d $install_path/$jemalloc ]; then
		echo 'installing '$jemalloc' ...'
		if [ ! -f $base_path/$jemalloc.tar.bz2 ]; then
			echo $jemalloc'.tar.bz2 is not exists, system will going to download it...'
			wget -O $base_path/$jemalloc.tar.bz2 https://install.ruanzhijun.cn/$jemalloc.tar.bz2 || exit
			echo 'download '$jemalloc' finished...'
		fi
		tar jxvf $base_path/$jemalloc.tar.bz2 -C $install_path || exit
		cd $install_path/$jemalloc
		./configure --prefix=$nginx_install_path/jemalloc && make -j $worker_processes && make install || exit
		echo $nginx_install_path"/jemalloc/lib" >> /etc/ld.so.conf || exit
		ldconfig
	fi 
fi 

# 安装OpenSSL
openssl='openssl-3.0.4'
if [ ! -f $base_path/$openssl.tar.gz ]; then
	echo $openssl'.tar.gz is not exists, system will going to download it...'
	wget -O $base_path/$openssl.tar.gz https://install.ruanzhijun.cn/$openssl.tar.gz || exit
	echo 'download '$openssl' finished...'
fi
if [ ! -d $nginx_install_path/openssl ]; then
	echo 'installing '$openssl' ...'
	if [ ! -f $base_path/$openssl.tar.gz ]; then
		echo $openssl'.tar.gz is not exists, system will going to download it...'
		wget -O $base_path/$openssl.tar.gz https://install.ruanzhijun.cn/$openssl.tar.gz || exit
		echo 'download '$openssl' finished...'
	fi
	tar zxvf $base_path/$openssl.tar.gz -C $install_path || exit
	cd $install_path/$openssl
	rm -rf $nginx_install_path/openssl && ./config shared zlib --prefix=$nginx_install_path/openssl && $install_path/$openssl/config -t && make update && make -j $worker_processes && make install || exit
	rm -rf /usr/bin/openssl && ln -s $nginx_install_path/openssl/bin/openssl /usr/bin/openssl
	rm -rf /usr/include/openssl && ln -s $nginx_install_path/openssl/include/openssl /usr/include/openssl
	rm -rf /usr/lib/libssl.so && ln -s $nginx_install_path/openssl/lib64/libssl.so /usr/lib/libssl.so
	rm -rf /usr/lib/libcrypto.so && ln -s $nginx_install_path/openssl/lib64/libcrypto.so /usr/lib/libcrypto.so
	rm -rf /usr/lib64/libssl.so && ln -s $nginx_install_path/openssl/lib64/libcrypto.so /usr/lib64/libssl.so
	rm -rf /usr/lib64/libcrypto.so && ln -s $nginx_install_path/openssl/lib64/libcrypto.so /usr/lib64/libcrypto.so
	echo $nginx_install_path"/openssl/lib64" >> /etc/ld.so.conf
	ldconfig -v
	echo $openssl' install finished...'
fi

#再解压一次给nginx编译用
rm -rf $install_path/$openssl
cd $base_path && tar zxvf $base_path/$openssl.tar.gz -C $install_path || exit

#安装libatomic
libatomic='libatomic_ops-1.1'
if [ ! -d $install_path/$libatomic ]; then
	echo 'installing '$libatomic' ...'
	if [ ! -f $base_path/$libatomic.tar.gz ]; then
		echo $libatomic'.tar.gz is not exists, system will going to download it...'
		wget -O $base_path/$libatomic.tar.gz https://install.ruanzhijun.cn/$libatomic.tar.gz || exit
		echo 'download '$libatomic' finished...'
	fi
	tar zxvf $base_path/$libatomic.tar.gz -C $install_path || exit
fi

#安装libmaxminddb
geoip='libmaxminddb-1.6.0'
if [ ! -d $install_path/$geoip ]; then
	echo 'installing '$geoip' ...'
	if [ ! -f $base_path/$geoip.tar.gz ]; then
		echo $geoip'.tar.gz is not exists, system will going to download it...'
		wget -O $base_path/$geoip.tar.gz https://install.ruanzhijun.cn/$geoip.tar.gz || exit
		echo 'download '$geoip' finished...'
	fi
	tar zxvf $base_path/$geoip.tar.gz -C $install_path || exit
	cd $install_path/$geoip
	./configure && make -j $worker_processes && make install || exit
fi

########## 增加nginx第三方模块：https://www.nginx.com/resources/wiki/modules/index.html ##########

#geoip2：https://github.com/leev/ngx_http_geoip2_module
wget -O $install_path/ngx_http_geoip2_module.zip https://install.ruanzhijun.cn/ngx_http_geoip2_module.zip || exit
cd $install_path && unzip ngx_http_geoip2_module.zip && mv ngx_http_geoip2_module-master ngx_http_geoip2_module || exit

#brotli压缩：https://github.com/google/ngx_brotli
wget -O $install_path/ngx_brotli.zip https://install.ruanzhijun.cn/ngx_brotli.zip || exit
cd $install_path && unzip ngx_brotli.zip && mv ngx_brotli-master ngx_brotli || exit
cd $install_path/ngx_brotli/deps && rm -rf brotli && wget https://install.ruanzhijun.cn/brotli.zip && unzip brotli.zip && mv brotli-master brotli || exit

#文件合并：https://github.com/alibaba/nginx-http-concat
wget -O $install_path/nginx-http-concat.zip https://install.ruanzhijun.cn/nginx-http-concat.zip || exit
cd $install_path && unzip nginx-http-concat.zip && mv nginx-http-concat-master nginx-http-concat || exit

#安装nginx
nginx='nginx-'$nginx_version
echo 'installing '$nginx' ...'
if [ ! -d $nginx_install_path/nginx ]; then
	if [ ! -f $base_path/$nginx.tar.gz ]; then
		echo $nginx'.tar.gz is not exists, system will going to download it...'
		wget -O $base_path/$nginx.tar.gz https://install.ruanzhijun.cn/$nginx.tar.gz || exit
		echo 'download '$nginx' finished...'
	fi
	tar zxvf $base_path/$nginx.tar.gz -C $install_path || exit
fi
cd $install_path/$nginx
./configure --prefix=$nginx_install_path/nginx --user=root --group=root --with-ld-opt="-Ljemalloc -Wl,-E" --with-http_stub_status_module --with-http_v2_module --with-select_module --with-poll_module --with-file-aio --with-ipv6 --with-http_gzip_static_module --with-http_sub_module --with-http_ssl_module --with-pcre=$install_path/$pcre --with-zlib=$install_path/$zlib --with-openssl=$install_path/$openssl --with-md5=/usr/lib --with-sha1=/usr/lib --with-md5-asm --with-sha1-asm --with-mail --with-threads --with-mail_ssl_module --with-compat --with-http_realip_module --with-http_addition_module --with-stream_ssl_preread_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_random_index_module --with-http_slice_module --with-http_secure_link_module --with-http_degradation_module --with-http_auth_request_module --with-http_stub_status_module --with-stream --with-stream_ssl_module --add-module=$install_path/ngx_http_geoip2_module --add-module=$install_path/ngx_brotli --add-module=$install_path/nginx-http-concat --with-libatomic=$install_path/$libatomic && sed -i 's/-Werror//' $install_path/$nginx/objs/Makefile && make -j $worker_processes && make install || exit

#写入nginx配置文件
echo 'create nginx.conf...'
ulimit='65535' #单个进程最大打开文件数
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
	
	fastcgi_connect_timeout 600;
	fastcgi_send_timeout 600;
	fastcgi_read_timeout 600;
	fastcgi_buffer_size 64k;
	fastcgi_buffers 4 64k;
	fastcgi_busy_buffers_size 128k;
	fastcgi_temp_file_write_size 128k;

	#开启gzip压缩
	gzip on;
	gzip_min_length 1k;
	gzip_buffers 4 16k;
	gzip_comp_level 9;
	gzip_types text/plain application/json application/javascript application/x-javascript text/css application/xml text/javascript application/x-httpd-php image/jpeg image/gif image/png image/svg+xml image/x-icon;
	gzip_vary off;	

	#不显示nginx的版本号
	server_tokens off;    
	   
	include "$nginx_install_path"/nginx/conf/web/*.conf;
}
" > $nginx_install_path/nginx/conf/nginx.conf || exit
rm -rf $nginx_install_path/nginx/conf/web/
mkdir $nginx_install_path/nginx/conf/web/
echo 'create nginx.conf finished...'

#创建网站文件存放目录
echo 'create "www" root...'
web_root='www'
mv $nginx_install_path/nginx/html $nginx_install_path/nginx/$web_root

#创建一个demo配置文件
echo 'create a demo conf , demo.conf...'
echo "
server {
	listen 80;
	rewrite ^/(.*) https://\$host/\$1 permanent;
}

server {
	listen 443 ssl http2;
	listen [::]:443 ssl http2;
	root  "$web_root";
	index index.html index.php;
	
	ssl_certificate /letsencrypt/letsencrypt/demo.crt;
	ssl_certificate_key /letsencrypt/letsencrypt/demo.key;
	ssl_ciphers 	\"TLS13-AES-256-GCM-SHA384:TLS13-CHACHA20-POLY1305-SHA256:TLS13-AES-128-GCM-SHA256:TLS13-AES-128-CCM-8-SHA256:TLS13-AES-128-CCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA\";
	ssl_protocols TLSv1.3;
	ssl_dhparam /letsencrypt/letsencrypt/demo.pem;
	ssl_prefer_server_ciphers on;
	ssl_early_data on;
	ssl_session_cache shared:SSL:10m;
	ssl_ecdh_curve secp384r1;
	
	ssl_stapling on;
	ssl_stapling_verify on;
	resolver 8.8.4.4 8.8.8.8 valid=300s;
	resolver_timeout 10s;
	
	#强制忽略缓存
	add_header Cache-Control no-store,no-cache,must-revalidate,max-age=0;
	
	#记录客户端真实ip
	proxy_set_header X-Real-IP \$remote_addr;
	proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
	
	#隐藏某些关键的header
	proxy_hide_header X-Powered-By;
	proxy_hide_header ETag;
	
	#允许跨域
	add_header Access-Control-Allow-Origin '*';
	add_header Access-Control-Allow-Credentials 'true';
	add_header Access-Control-Allow-Methods 'GET,POST,OPTIONS,PUT,DELETE,PATCH';
	add_header Access-Control-Allow-Headers 'Keep-Alive,User-Agent,X-Requested-With,Content-Type,token,lang';

	#不允许用框架、强制用https
	add_header x-Content-Type-Options nosniff;
	add_header X-Frame-Options deny;
	add_header Strict-Transport-Security 'max-age=3153600000; includeSubDomains; preload;';
}" > $nginx_install_path/nginx/conf/web/demo.conf

#修改环境变量
echo 'modify /etc/profile...'
echo "ulimit -SHn "$ulimit >> /etc/profile
$(source /etc/profile)

#复制demo https证书
mkdir -p /letsencrypt/letsencrypt/
cd /letsencrypt/letsencrypt/
wget --no-check-certificate --no-cache https://raw.staticdn.net/share-group/shell/master/cert/demo.crt
wget --no-check-certificate --no-cache https://raw.staticdn.net/share-group/shell/master/cert/demo.key
wget --no-check-certificate --no-cache https://raw.staticdn.net/share-group/shell/master/cert/demo.pem

#启动nginx
yes|cp -rf $nginx_install_path/nginx/sbin/nginx /usr/bin/
nginx

#开机自启动
echo '' >> /etc/rc.d/rc.local
echo 'systemctl stop firewalld' >> /etc/rc.d/rc.local
echo 'nginx' >> /etc/rc.d/rc.local
$(source /etc/rc.d/rc.local)

# Nginx内核参数优化 https://www.cnblogs.com/suihui/p/3799683.html#id23
