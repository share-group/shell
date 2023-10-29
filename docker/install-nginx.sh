#linux nginx自动安装程序 
#运行例子：mkdir -p /shell && cd /shell && rm -rf install-nginx.sh && wget --no-cache https://raw.staticdn.net/share-group/shell/master/docker/install-nginx.sh && sh install-nginx.sh 1.10.3 /usr/local
 

#处理外部参数
nginx_version=$1
nginx_install_path=$2
if [ ! $nginx_version ] || [ ! $nginx_install_path ]; then
	echo 'error command!!! you must input nginx version and install path...'
	echo 'for example: sh install-nginx.sh 1.10.3 /usr/local'
	exit
fi

#创建ngxin安装目录
nginx_install_path=$nginx_install_path'/nginx'
rm -rf $nginx_install_path
mkdir -p $nginx_install_path/logs
mkdir -p $nginx_install_path/www
mkdir -p $nginx_install_path/conf/web

#创建nginx配置文件
echo 'create nginx.conf...'
ulimit='65535' #单个进程最大打开文件数
worker_processes=$(nproc --all) #查询cpu逻辑个数
echo "user root root;
worker_processes "$worker_processes";
#worker_rlimit_nofile "$ulimit";

events {
	use epoll;
	worker_connections "$ulimit";
}

http {
	include mime.types;
	charset utf-8;
	default_type application/octet-stream;
	access_log off;
	error_log logs/error.log crit;
	sendfile on;
	tcp_nopush on;
	tcp_nodelay on;
	keepalive_timeout 60;
	client_header_buffer_size 32k;
	client_max_body_size 200m;
	
	#强制忽略缓存
	add_header Cache-Control no-store,no-cache,must-revalidate,max-age=0;
	
	proxy_set_header X-Real-IP \$remote_addr;
	proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
	
	#允许跨域
	add_header Access-Control-Allow-Origin '*';
	add_header Access-Control-Allow-Credentials 'true';
	add_header Access-Control-Allow-Methods 'GET,POST,OPTIONS,PUT,DELETE,PATCH';
	add_header Access-Control-Allow-Headers 'DNT,X-Mx-ReqToken,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type';
	
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
	   
	include conf/web/*.conf;
}
" > $nginx_install_path/conf/nginx.conf || exit
echo 'create nginx.conf finished...'

#创建网站文件存放目录
echo "hello world!" > $nginx_install_path/www/index.html || exit
echo "<?php phpinfo(); ?>" > $nginx_install_path/www/phpinfo.php || exit

#创建一个80端口的配置文件(作为demo)
echo 'create a demo conf , 80.conf...'
echo '
#80
server {
	listen 80;
	server_name _;
	root '$nginx_install_path'/www;
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
' > $nginx_install_path/conf/web/80.conf

#创建一个https的配置文件
echo 'create 443.conf...'

#首先自己生成证书，可以实现https，但是不受浏览器信任
echo "
#https
#server {
	#listen  443;
	#server_name _;
	#root '$nginx_install_path'/www;
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
	#add_header Strict-Transport-Security 'max-age=31536000; includeSubDomains; preload;';
#}" > $nginx_install_path/conf/web/443.conf

#docker安装nginx
docker pull hub.c.163.com/library/alpine:latest
docker pull hub.c.163.com/library/nginx:$nginx_version-alpine

#修改环境变量
echo 'modify /etc/profile...'
echo "ulimit -SHn "$ulimit >> /etc/profile
$(source /etc/profile)

#启动nginx
docker run --name nginx -p 80:80 -p 443:443 -v $nginx_install_path/www:/usr/share/nginx/html -v $nginx_install_path/conf:/etc/nginx/conf -v $nginx_install_path/logs:/etc/nginx/logs -v $nginx_install_path/conf/nginx.conf:/etc/nginx/nginx.conf -d hub.c.163.com/library/nginx:$nginx_version-alpine

#开机自启动
echo '' >> /etc/rc.d/rc.local
echo 'docker start nginx' >> /etc/rc.d/rc.local
