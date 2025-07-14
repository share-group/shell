#linux nginx自动安装程序
#运行例子：mkdir -p /shell && cd /shell && rm -rf install-nginx.sh && wget --no-check-certificate --no-cache https://raw.githubusercontents.com/share-group/shell/master/install-nginx.sh && sh install-nginx.sh 1.28.0 /usr/local

#定义本程序的当前目录
base_path=$(pwd)

#处理外部参数
nginx_version=$1
nginx_install_path=$2
if [ ! $nginx_version ] || [ ! $nginx_install_path ]; then
	echo 'error command!!! you must input nginx version and install path...'
	echo 'for example: sh install-nginx.sh 1.28.0 /usr/local'
	exit
fi

worker_processes=$(cat /proc/cpuinfo | grep "processor" | wc -l) #查询cpu逻辑个数
dnf -y install lrzsz vim gcc gcc-c++ make perl-core patch unzip tar bzip2 || DEBIAN_FRONTEND=noninteractive apt install -yq lrzsz vim gcc g++ make libssl-dev perl patch unzip tar bzip2

#建立临时安装目录
echo 'preparing working path...'
install_path='/install'
rm -rf $install_path
mkdir -p $install_path

#下载zlib
zlib='zlib-1.3.1'
if [ ! -d $install_path/$zlib ]; then
	echo 'installing '$zlib' ...'
	if [ ! -f $base_path/$zlib.tar.gz ]; then
		echo $zlib'.tar.gz is not exists, system will going to download it...'
		wget --no-check-certificate --no-cache -O $base_path/$zlib.tar.gz https://install.ruanzhijun.cn/$zlib.tar.gz || exit
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
	cd /usr/local/lib && ln -s $nginx_install_path/zlib/lib/libz.so.1.3.1 libz.so.1.3.1
	echo $nginx_install_path"/zlib/lib" >> /etc/ld.so.conf
	ldconfig
fi

#下载pcre
pcre='pcre-8.45'
if [ ! -d $install_path/$pcre ]; then
	echo 'installing '$pcre' ...' 
	if [ ! -f $base_path/$pcre.tar.gz ]; then
		echo $pcre'.tar.gz is not exists, system will going to download it...'
		wget --no-check-certificate --no-cache -O $base_path/$pcre.tar.gz https://install.ruanzhijun.cn/$pcre.tar.gz || exit
		echo 'download '$pcre' finished...'
	fi
	tar zxvf $base_path/$pcre.tar.gz -C $install_path || exit
fi 

#安装libiconv
if [ ! -d $nginx_install_path/libiconv ]; then
	libiconv='libiconv-1.17'
	if [ ! -f $base_path/$libiconv.tar.gz ]; then
		wget --no-check-certificate --no-cache -O $base_path/$libiconv.tar.gz https://install.ruanzhijun.cn/$libiconv.tar.gz || exit
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
			wget --no-check-certificate --no-cache -O $base_path/$jemalloc.tar.bz2 https://install.ruanzhijun.cn/$jemalloc.tar.bz2 || exit
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
openssl='openssl-3.5.1'
if [ ! -f $base_path/$openssl.tar.gz ]; then
	echo $openssl'.tar.gz is not exists, system will going to download it...'
	wget --no-check-certificate --no-cache -O $base_path/$openssl.tar.gz https://install.ruanzhijun.cn/$openssl.tar.gz || exit
	echo 'download '$openssl' finished...'
fi
rm -rf $install_path/$openssl && cd $install_path && tar zxvf $base_path/$openssl.tar.gz -C $install_path || exit

#安装libatomic
libatomic='libatomic_ops-1.1'
if [ ! -d $install_path/$libatomic ]; then
	echo 'installing '$libatomic' ...'
	if [ ! -f $base_path/$libatomic.tar.gz ]; then
		echo $libatomic'.tar.gz is not exists, system will going to download it...'
		wget --no-check-certificate --no-cache -O $base_path/$libatomic.tar.gz https://install.ruanzhijun.cn/$libatomic.tar.gz || exit
		echo 'download '$libatomic' finished...'
	fi
	tar zxvf $base_path/$libatomic.tar.gz -C $install_path || exit
fi

#安装libmaxminddb
geoip='libmaxminddb-1.12.2'
if [ ! -d $install_path/$geoip ]; then
	echo 'installing '$geoip' ...'
	if [ ! -f $base_path/$geoip.tar.gz ]; then
		echo $geoip'.tar.gz is not exists, system will going to download it...'
		wget --no-check-certificate --no-cache -O $base_path/$geoip.tar.gz https://install.ruanzhijun.cn/$geoip.tar.gz || exit
		echo 'download '$geoip' finished...'
	fi
	tar zxvf $base_path/$geoip.tar.gz -C $install_path || exit
	cd $install_path/$geoip && ./configure && make -j $worker_processes && make install || exit
fi

########## 增加nginx第三方模块：https://www.nginx.com/resources/wiki/modules/index.html ##########

#geoip2：https://github.com/leev/ngx_http_geoip2_module
wget --no-check-certificate --no-cache -O $install_path/ngx_http_geoip2_module.zip https://install.ruanzhijun.cn/ngx_http_geoip2_module.zip || exit
cd $install_path && unzip ngx_http_geoip2_module.zip && mv ngx_http_geoip2_module-master ngx_http_geoip2_module || exit

#brotli压缩：https://github.com/google/ngx_brotli
wget --no-check-certificate --no-cache -O $install_path/ngx_brotli.zip https://install.ruanzhijun.cn/ngx_brotli.zip || exit
cd $install_path && unzip ngx_brotli.zip && mv ngx_brotli-master ngx_brotli || exit
cd $install_path/ngx_brotli/deps && rm -rf brotli && wget --no-check-certificate --no-cache https://install.ruanzhijun.cn/brotli.zip && unzip brotli.zip && mv brotli-master brotli || exit

#文件合并：https://github.com/alibaba/nginx-http-concat
wget --no-check-certificate --no-cache -O $install_path/nginx-http-concat.zip https://install.ruanzhijun.cn/nginx-http-concat.zip || exit
cd $install_path && unzip nginx-http-concat.zip && mv nginx-http-concat-master nginx-http-concat || exit


#安装nginx
nginx='nginx-'$nginx_version
echo 'installing '$nginx' ...'
if [ ! -d $nginx_install_path/nginx ]; then
	if [ ! -f $base_path/$nginx.tar.gz ]; then
		echo $nginx'.tar.gz is not exists, system will going to download it...'
		wget --no-check-certificate --no-cache -O $base_path/$nginx.tar.gz https://install.ruanzhijun.cn/$nginx.tar.gz || exit
		echo 'download '$nginx' finished...'
	fi
	tar zxvf $base_path/$nginx.tar.gz -C $install_path || exit
fi
cd $install_path/$nginx

# 编译
./configure --prefix=$nginx_install_path/nginx --user=root --group=root --with-cc=gcc --with-ld-opt="-Ljemalloc -Wl,-E" --with-http_stub_status_module --with-http_v2_module --with-http_v3_module --with-select_module --with-poll_module --with-file-aio --with-http_gzip_static_module --with-http_sub_module --with-http_ssl_module --with-pcre=$install_path/$pcre --with-openssl=$install_path/$openssl --with-openssl-opt=enable-tls1_3 --with-zlib=$install_path/$zlib --with-mail --with-threads --with-mail_ssl_module --with-compat --with-http_realip_module --with-http_addition_module --with-stream_ssl_preread_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_random_index_module --with-http_slice_module --with-http_secure_link_module --with-http_degradation_module --with-http_auth_request_module --with-http_stub_status_module --with-stream --with-stream_ssl_module --add-module=$install_path/ngx_http_geoip2_module --add-module=$install_path/ngx_brotli --add-module=$install_path/nginx-http-concat --with-libatomic=$install_path/$libatomic && sed -i 's/-Werror//' $install_path/$nginx/objs/Makefile && make -j $worker_processes && make install || exit

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

  #开启brotli压缩
  brotli on;
  brotli_min_length 1;
  brotli_buffers 16 8k;
  brotli_comp_level 6;
  brotli_static always;
  brotli_types *;

  #不显示nginx的版本号
  server_tokens off;

  #GeoIP配置
  geoip2 /usr/share/GeoIP/GeoLite2-ASN.mmdb {
    auto_reload 5m;
    \$geoip2_asn source = \$remote_addr autonomous_system_number;
    \$geoip2_organization source = \$remote_addr autonomous_system_organization;
  }

  geoip2 /usr/share/GeoIP/GeoLite2-City.mmdb {
    \$geoip2_city_name_en source = \$remote_addr city names en;
    \$geoip2_data_city_code source = \$remote_addr city geoname_id;
  }

  geoip2 /usr/share/GeoIP/GeoLite2-Country.mmdb {
  auto_reload 5m;
    \$geoip2_country_code source = \$remote_addr country iso_code;
    \$geoip2_country_name_en source = \$remote_addr country names en;
  }

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
  http2 on;
  listen 80;
  listen [::]:80;
  rewrite ^/(.*) https://\$host/\$1 permanent;
}

server {
  http2 on;
  autoindex off;
  listen 443 ssl;
  listen 443 quic reuseport;
  root  "$web_root";
  index index.html;

  ssl_certificate /letsencrypt/letsencrypt/demo.cer;
  ssl_certificate_key /letsencrypt/letsencrypt/demo.key;
  ssl_ciphers 'TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384';
  ssl_protocols TLSv1.3;
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
  proxy_hide_header ETag;
  proxy_hide_header X-Powered-By;

  #允许跨域
  add_header Access-Control-Allow-Origin '*';
  add_header Access-Control-Allow-Credentials 'true';
  add_header Access-Control-Allow-Methods '*';
  add_header Access-Control-Allow-Headers '*';

  #不允许用框架、强制是使用https
  add_header X-Frame-Options deny;
  add_header x-Content-Type-Options nosniff;
  add_header Strict-Transport-Security 'max-age=315360000; includeSubDomains; preload;';

  #http3配置
  add_header QUIC-Status \$http3;
  add_header Alt-Svc 'h3=\":443\"; ma=315360000;quic=\":443\"; ma=315360000; v=\"46,43\",h3-27=\":443\"; ma=315360000,h3-25=\":443\"; ma=315360000,h3-T050=\":443\"; ma=315360000,h3-Q050=\":443\"; ma=315360000,h3-Q049=\":443\"; ma=315360000,h3-Q048=\":443\"; ma=315360000,h3-Q046=\":443\"; ma=315360000,h3-Q043=\":443\"; ma=315360000';
}" > $nginx_install_path/nginx/conf/web/demo.conf

#修改环境变量
echo 'modify /etc/profile...'
echo "ulimit -SHn "$ulimit >> /etc/profile
$(source /etc/profile)

#复制demo https证书
mkdir -p /letsencrypt/letsencrypt/
cd /letsencrypt/letsencrypt/
wget --no-check-certificate --no-cache https://raw.staticdn.net/share-group/shell/master/cert/demo.cer
wget --no-check-certificate --no-cache https://raw.staticdn.net/share-group/shell/master/cert/demo.key

#下载GeoIp数据库
geoip_asn_version='20250713'
geoip_city_version='20250711'
geoip_country_version='20250711'
rm -rf /usr/share/GeoIP
cd $base_path && wget --no-check-certificate --no-cache https://install.ruanzhijun.cn/GeoLite2-ASN_$geoip_asn_version.tar.gz && tar zxvf $base_path/GeoLite2-ASN_$geoip_asn_version.tar.gz -C $install_path || exit
cd $base_path && wget --no-check-certificate --no-cache https://install.ruanzhijun.cn/GeoLite2-City_$geoip_city_version.tar.gz && tar zxvf $base_path/GeoLite2-City_$geoip_city_version.tar.gz -C $install_path || exit
cd $base_path && wget --no-check-certificate --no-cache https://install.ruanzhijun.cn/GeoLite2-Country_$geoip_country_version.tar.gz && tar zxvf $base_path/GeoLite2-Country_$geoip_country_version.tar.gz -C $install_path || exit
mkdir -p /usr/share/GeoIP && cp -rf $install_path/GeoLite2-ASN_$geoip_asn_version/GeoLite2-ASN.mmdb /usr/share/GeoIP/GeoLite2-ASN.mmdb || exit
mkdir -p /usr/share/GeoIP && cp -rf $install_path/GeoLite2-City_$geoip_city_version/GeoLite2-City.mmdb /usr/share/GeoIP/GeoLite2-City.mmdb || exit
mkdir -p /usr/share/GeoIP && cp -rf $install_path/GeoLite2-Country_$geoip_country_version/GeoLite2-Country.mmdb /usr/share/GeoIP/GeoLite2-Country.mmdb || exit

#启动nginx
yes|cp -rf $nginx_install_path/nginx/sbin/nginx /usr/bin/
nginx

#开机自启动
echo '' >> /etc/rc.d/rc.local
echo 'systemctl stop firewalld' >> /etc/rc.d/rc.local
echo 'nginx' >> /etc/rc.d/rc.local
$(source /etc/rc.d/rc.local)

# Nginx内核参数优化 https://www.cnblogs.com/suihui/p/3799683.html#id23