#定义本程序的当前目录
base_path=$(pwd)  
source /etc/profile || exit

#配置raw.staticdn.net的host，使得国内服务器可以下载github的文件
hosts=$(cat /etc/hosts | grep 'raw.staticdn.net')
if [ ! -n "$hosts" ]; then
	echo '199.232.28.133  raw.staticdn.net' >> /etc/hosts
fi

#处理外部参数
nginx_version=$1
nginx_install_path=$2
if [ ! $nginx_version ] || [ ! $nginx_install_path ]; then
	echo 'error command!!! you must input nginx version and install path...'
	echo 'for example: sh install-nginx-quic.sh quic /usr/local'
	exit
fi

worker_processes=$(cat /proc/cpuinfo | grep name | cut -f3 -d: | uniq -c | cut -b 7) #查询cpu逻辑个数
yum remove -y go && yum -y install make gcc gcc-c++ openssl openssl-devel sed curl wget rsync patch lrzsz bzip2 mercurial

#建立临时安装目录
echo 'preparing working path...'
install_path='/install'
rm -rf $install_path
mkdir -p $install_path

#安装libunwind库
libunwind='libunwind-1.4.0'
if [ ! -d $nginx_install_path/libunwind ]; then
	if [ ! -d $install_path/$libunwind ]; then
		echo 'installing '$libunwind' ...'
		if [ ! -f $base_path/$libunwind.tar.gz ]; then
			echo $libunwind'.tar.gz is not exists, system will going to download it...'
			wget -O $base_path/$libunwind.tar.gz https://install.ruanzhijun.cn/$libunwind.tar.gz || exit
			echo 'download '$libunwind' finished...'
		fi
		tar zxvf $base_path/$libunwind.tar.gz -C $install_path || exit
		cd $install_path/$libunwind
		CFLAGS=-fPIC ./configure --prefix=$nginx_install_path/libunwind && make CFLAGS=-fPIC -j $worker_processes && make CFLAGS=-fPIC install || exit
		echo $nginx_install_path"/libunwind/lib" >> /etc/ld.so.conf || exit
		ldconfig
	fi 
fi 

#安装jemalloc
jemalloc='jemalloc-5.2.1'
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

#下载zlib
zlib='zlib-1.2.11'
echo 'installing '$zlib' ...'
if [ ! -f $base_path/$zlib.tar.gz ]; then
	echo $zlib'.tar.gz is not exists, system will going to download it...'
	wget -O $base_path/$zlib.tar.gz https://install.ruanzhijun.cn/$zlib.tar.gz || exit
	echo 'download '$zlib' finished...'
fi
rm -rf $install_path/$zlib && tar zxvf $base_path/$zlib.tar.gz -C $install_path || exit
is_install_zlib=$(cat /etc/ld.so.conf | grep '/zlib/lib')
if [ ! -n "$is_install_zlib" ]; then
	cd $install_path/$zlib
	./configure --prefix=$nginx_install_path/zlib --shared && make -j $worker_processes && make test && make install || exit
	yes | cp $install_path/$zlib/zutil.h /usr/local/include
	yes | cp $install_path/$zlib/zutil.c /usr/local/include
	yes | cp $nginx_install_path/zlib/include/zlib.h /usr/local/include
	yes | cp $nginx_install_path/zlib/include/zconf.h /usr/local/include
	cd /usr/local/lib && ln -s $nginx_install_path/zlib/lib/libz.a libz.a
	cd /usr/local/lib && ln -s $nginx_install_path/zlib/lib/libz.so libz.so
	cd /usr/local/lib && ln -s $nginx_install_path/zlib/lib/libz.so.1 libz.so.1
	cd /usr/local/lib && ln -s $nginx_install_path/zlib/lib/libz.so.1.2.11 libz.so.1.2.11
	echo $nginx_install_path"/zlib/lib" >> /etc/ld.so.conf
	ldconfig
fi

#安装cmake
cmake='cmake-3.17.3'
if [ ! -d $nginx_install_path/cmake ]; then
	echo 'installing '$cmake'...'
	if [ ! -f $base_path/$cmake.tar.gz ]; then
		echo $cmake'.tar.gz is not exists, system will going to download it...'
		wget -O $base_path/$cmake.tar.gz https://install.ruanzhijun.cn/$cmake.tar.gz || exit
		echo 'download '$cmake' finished...'
	fi
	tar zxvf $base_path/$cmake.tar.gz -C $install_path || exit
	cd $install_path/$cmake
	./bootstrap --no-system-curl --prefix=$nginx_install_path/cmake && make -j $worker_processes && make install || exit
	cd /usr/bin && ln -s $nginx_install_path/cmake/bin/cmake cmake && chmod 777 cmake || exit
fi

#下载pcre
pcre='pcre-8.44'
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
	libiconv='libiconv-1.16'
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

#安装go
go='1.14.4'
if [ ! -d $nginx_install_path/go ]; then
	echo 'installing '$go'...'
	if [ ! -f $base_path/go$go.linux-amd64.tar.gz ]; then
		echo 'go'$go'.linux-amd64.tar.gz not exists, system will going to download it...'
		wget -O $base_path/go$go.linux-amd64.tar.gz https://install.ruanzhijun.cn/go$go.linux-amd64.tar.gz || exit
		echo 'download '$go' finished...'
	fi
	tar zxvf $base_path/go$go.linux-amd64.tar.gz -C $nginx_install_path || exit
	echo 'export PATH=$PATH:'$nginx_install_path'/go/bin' >> /etc/profile || exit
	echo 'export GOROOT='$nginx_install_path'/go' >> /etc/profile || exit
	echo 'export GOBIN=$GOROOT/bin' >> /etc/profile || exit
	source /etc/profile || exit
fi

# 安装boringssl
boringssl='boringssl'
if [ ! -f $base_path/$boringssl.tar.bz2 ]; then
	echo $boringssl'.tar.gz is not exists, system will going to download it...'
	wget -O $base_path/$boringssl.tar.bz2 https://install.ruanzhijun.cn/$boringssl.tar.bz2 || exit
	echo 'download '$boringssl' finished...'
fi

#编译boringssl
mkdir -p $install_path/boringssl && tar jxvf $base_path/$boringssl.tar.bz2 -C $install_path || exit
cd $install_path/boringssl && mkdir -p $install_path/boringssl/build $install_path/boringssl/.openssl/lib $install_path/boringssl/.openssl/include || exit
ln -sf $install_path/boringssl/include/openssl $install_path/boringssl/.openssl/include/openssl || exit
touch $install_path/boringssl/.openssl/include/openssl/ssl.h || exit
cmake -B$install_path/boringssl/build -H$install_path/boringssl || exit
make -j $worker_processes -C $install_path/boringssl/build || exit
cp $install_path/boringssl/build/crypto/libcrypto.a $install_path/boringssl/build/ssl/libssl.a $install_path/boringssl/.openssl/lib || exit


#增加第三方模块：https://www.nginx.com/resources/wiki/modules/index.html
############# 查询字符串进行排序模块 #############
if [ ! -f $base_path/nginx-sorted-querystring-module.tar.bz2 ]; then
	wget -O $base_path/nginx-sorted-querystring-module.tar.bz2 https://install.ruanzhijun.cn/nginx-sorted-querystring-module.tar.bz2
fi
tar jxvf $base_path/nginx-sorted-querystring-module.tar.bz2 -C $install_path || exit

############# Brotli压缩算法模块 #############
if [ ! -f $base_path/ngx_brotli.tar.bz2 ]; then
	wget -O $base_path/ngx_brotli.tar.bz2 https://install.ruanzhijun.cn/ngx_brotli.tar.bz2
fi
tar jxvf $base_path/ngx_brotli.tar.bz2 -C $install_path || exit

############# 文件合并模块 #############
if [ ! -f $base_path/nginx-http-concat.tar.bz2 ]; then
	wget -O $base_path/nginx-http-concat.tar.bz2 https://install.ruanzhijun.cn/nginx-http-concat.tar.bz2
fi
tar jxvf $base_path/nginx-http-concat.tar.bz2 -C $install_path || exit

############# nginx访问redis模块 #############
if [ ! -f $base_path/redis2-nginx-module.tar.bz2 ]; then
	wget -O $base_path/redis2-nginx-module.tar.bz2 https://install.ruanzhijun.cn/redis2-nginx-module.tar.bz2
fi
tar jxvf $base_path/redis2-nginx-module.tar.bz2 -C $install_path || exit

############# 清除缓存模块 #############
if [ ! -f $base_path/ngx_cache_purge.tar.bz2 ]; then
	wget -O $base_path/ngx_cache_purge.tar.bz2 https://install.ruanzhijun.cn/ngx_cache_purge.tar.bz2
fi
tar jxvf $base_path/ngx_cache_purge.tar.bz2 -C $install_path || exit

############# 服务开发套件模块 #############
if [ ! -f $base_path/ngx_devel_kit.tar.bz2 ]; then
	wget -O $base_path/ngx_devel_kit.tar.bz2 https://install.ruanzhijun.cn/ngx_devel_kit.tar.bz2
fi
tar jxvf $base_path/ngx_devel_kit.tar.bz2 -C $install_path || exit

############# http-flv模块 #############
if [ ! -f $base_path/nginx-http-flv-module-1.2.7.tar.gz ]; then
	wget -O $base_path/nginx-http-flv-module-1.2.7.tar.gz https://install.ruanzhijun.cn/nginx-http-flv-module-1.2.7.tar.gz
fi
tar zxvf $base_path/nginx-http-flv-module-1.2.7.tar.gz -C $install_path || exit

############# vts监控模块 #############
if [ ! -f $base_path/nginx-module-vts-0.1.18.tar.gz ]; then
	wget -O $base_path/nginx-module-vts-0.1.18.tar.gz https://install.ruanzhijun.cn/nginx-module-vts-0.1.18.tar.gz
fi
tar zxvf $base_path/nginx-module-vts-0.1.18.tar.gz -C $install_path || exit

############# xss支持模块 #############
if [ ! -f $base_path/xss-nginx-module-0.06.tar.gz ]; then
	wget -O $base_path/xss-nginx-module-0.06.tar.gz https://install.ruanzhijun.cn/xss-nginx-module-0.06.tar.gz
fi
tar zxvf $base_path/xss-nginx-module-0.06.tar.gz -C $install_path || exit

#安装nginx
nginx='nginx-'$nginx_version
echo 'installing '$nginx' ...'
if [ ! -d $nginx_install_path/nginx ]; then
	if [ ! -f $base_path/$nginx.tar.bz2 ]; then
		echo $nginx'.tar.gz is not exists, system will going to download it...'
		wget -O $base_path/$nginx.tar.bz2 https://install.ruanzhijun.cn/$nginx.tar.bz2 || exit
		echo 'download '$nginx' finished...'
	fi
	tar jxvf $base_path/$nginx.tar.bz2 -C $install_path || exit
fi
cd $install_path/$nginx

#打个补丁，让boringssl支持ocsp
wget -O Enable_BoringSSL_OCSP.patch https://install.ruanzhijun.cn/Enable_BoringSSL_OCSP.patch && patch -p1 < ./Enable_BoringSSL_OCSP.patch

#执行nginx安装
./auto/configure --prefix=$nginx_install_path/nginx --user=root --group=root --with-http_stub_status_module --with-http_v3_module --with-cc-opt="-I../boringssl/include" --with-ld-opt="-Ljemalloc -L../boringssl/build/ssl -L../boringssl/build/crypto -Wl,-E -D_GNU_SOURCE" --with-http_v2_module --with-select_module --with-poll_module --with-file-aio --with-ipv6 --with-http_gzip_static_module --with-http_sub_module --with-http_ssl_module --with-pcre-jit --with-pcre=$install_path/$pcre --with-zlib=$install_path/$zlib --with-md5=/usr/lib --with-sha1=/usr/lib --with-md5-asm --with-sha1-asm --with-mail --with-threads --with-mail_ssl_module --with-compat --with-http_realip_module --with-http_addition_module --with-stream_ssl_preread_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_random_index_module --with-http_slice_module --with-http_secure_link_module --with-http_degradation_module --with-http_auth_request_module --with-http_stub_status_module --with-stream --with-stream_ssl_module --with-libatomic=$install_path/$libatomic --add-module=$install_path/nginx-sorted-querystring-module --add-module=$install_path/ngx_brotli --add-module=$install_path/nginx-http-concat --add-module=$install_path/redis2-nginx-module --add-module=$install_path/ngx_cache_purge --add-module=$install_path/ngx_devel_kit --add-module=$install_path/nginx-http-flv-module-1.2.7 --add-module=$install_path/nginx-module-vts-0.1.18 --add-module=$install_path/xss-nginx-module-0.06 && sed -i 's/-Werror//' $install_path/$nginx/objs/Makefile && make -j $worker_processes && make install || exit

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
	
	add_header X-Real-IP \$remote_addr;
	
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
	listen [::]:80;
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
	
	#允许所有method跨域
	#location ~ .*$ {
	#	if ($request_method = "OPTIONS") {
	#		add_header Access-Control-Allow-Origin "*";
	#		add_header Access-Control-Allow-Credentials "true";
	#		add_header Access-Control-Allow-Methods "GET,POST,OPTIONS,PUT,DELETE,PATCH";
	#		add_header Access-Control-Allow-Headers "DNT,X-Mx-ReqToken,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type";
	#		return 204;
	#	}
	#}
		
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
	#		auth_basic_user_file /usr/local/nginx/conf/web/htpasswd;  #密码文件格式：baidu.com:/XJt5jAl/dKTI
	#}
	
	#查看nginx状态
	#location /status {
	#	stub_status		on;
	#}
}
' > $nginx_install_path/nginx/conf/web/80.conf

#创建一个https的配置文件
echo 'create 443.conf...'

#首先自己生成证书，可以实现https，但是不受浏览器信任
echo "
#https
server {
	listen 443 ssl http2;
	listen 443 http3 reuseport;
	listen [::]:443 ssl http2;
	listen [::]:443 http3 reuseport;
	server_name _;
	root  "$web_root";
	index index.html index.php;
	
	ssl_certificate /letsencrypt/letsencrypt/demo.crt;
	ssl_certificate_key /letsencrypt/letsencrypt/demo.key;
	ssl_ciphers 	\"TLS13-AES-256-GCM-SHA384:TLS13-CHACHA20-POLY1305-SHA256:TLS13-AES-128-GCM-SHA256:TLS13-AES-128-CCM-8-SHA256:TLS13-AES-128-CCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA\";
	ssl_protocols TLSv1.3;
	ssl_dhparam /letsencrypt/letsencrypt/demo.pem;
	ssl_prefer_server_ciphers on;
	ssl_session_cache shared:SSL:10m;
	ssl_ecdh_curve secp384r1;
	ssl_early_data on;
	quic_retry on;
	
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
	add_header Strict-Transport-Security 'max-age=31536000; includeSubDomains; preload;';
	add_header alt-svc 'quic=\":443\"; ma=2592000; v=\"46,43\",h3-27=\":443\"; ma=2592000,h3-25=\":443\"; ma=2592000,h3-T050=\":443\"; ma=2592000,h3-Q050=\":443\"; ma=2592000,h3-Q049=\":443\"; ma=2592000,h3-Q048=\":443\"; ma=2592000,h3-Q046=\":443\"; ma=2592000,h3-Q043=\":443\"; ma=2592000';
}" > $nginx_install_path/nginx/conf/web/443.conf

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
