# 使用Let's Encrypt生成https证书
# 参考文章：http://www.tuicool.com/articles/yyEvmau

#运行例子：mkdir -p /shell && cd /shell && rm -rf letsencrypt.sh && wget --no-cache https://raw.githubusercontent.com/ruanzhijun/share/master/shell/letsencrypt.sh && chmod 777 letsencrypt.sh && sh letsencrypt.sh

# 每个域名，每周只能签20次

#建立临时安装目录
echo 'preparing working path...'
install_path='/letsencrypt/letsencrypt'
rm -rf $install_path
mkdir -p $install_path

# 下载所需文件
cd $install_path
rm -rf *.pem *.key *.conf *.csr *.crt
if [ ! -f letsencrypt.sh ]; then
	wget --no-cache https://raw.githubusercontent.com/xdtianyu/scripts/master/lets-encrypt/letsencrypt.sh  
	chmod 777 letsencrypt.sh 
fi

# 准备验证域名需要的目录
rm -rf /srv/.well-known/
mkdir -p /srv/.well-known/

# 创建配置文件
rm -rf letsencrypt.conf
touch letsencrypt.conf
echo 'ACCOUNT_KEY="letsencrypt-account.key"' >> letsencrypt.conf
echo 'DOMAIN_KEY="trustdream.com.key"' >> letsencrypt.conf
echo 'DOMAIN_DIR="/srv"' >> letsencrypt.conf
echo 'DOMAINS="DNS:trustdream.com,DNS:www.trustdream.com"' >> letsencrypt.conf
echo '#ECC=TRUE' >> letsencrypt.conf
echo '#LIGHTTPD=TRUE' >> letsencrypt.conf

# 生成证书
./letsencrypt.sh letsencrypt.conf
openssl dhparam -out dhparam.lifution.pem 2048

# 重启nginx
nginx -s reload

# 删除临时文件夹
rm -rf /srv/.well-known/

# 定时任务 0 4 1 2,4,6,7,10,12 * root sh /letsencrypt/letsencrypt.sh 
# https://www.ssllabs.com/ssltest
