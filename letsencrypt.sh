#自签https证书
rm -rf /letsencrypt && mkdir /letsencrypt
cd /letsencrypt && cp /srv/flow/flow-deploy/production/letsencrypt.sh /letsencrypt/letsencrypt.sh && chmod 777 /letsencrypt/letsencrypt.sh

rm -rf /root/.acme.sh
mkdir -p /root/.acme.sh

#下载最新的acme.sh脚本
rm -rf /letsencrypt/acme.sh && rm -rf /letsencrypt/*.zip && rm -rf /letsencrypt/acme.sh-master
wget --no-check-certificate --no-cache https://github.com/acmesh-official/acme.sh/archive/master.zip || exit
unzip master.zip || exit
mv /letsencrypt/acme.sh-master/acme.sh /letsencrypt/acme.sh
chmod 777 acme.sh

#强制更新一次，实时使用最新的协议
sh acme.sh --upgrade || exit

#通配符方案
export Ali_Key="xxxxxxxxxxxxxxxx"
export Ali_Secret="xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
sh acme.sh --issue --dns dns_ali -d xxxxx.com -d *.xxxxx.com --keylength 4096 --force || exit
openssl dhparam -out /root/.acme.sh/xxxxx.com/dhparam.xxxxx.pem 2048 || exit

#单域名方案
sh acme.sh --issue -d xxxx.com -d yyyy.com --webroot /your/path --keylength 4096 --force || exit
openssl dhparam -out /root/.acme.sh/xxxx.com/xxxx.com.pem 2048 || exit

#重启nginx
nginx -t && nginx -s reload
