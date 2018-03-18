#自签通配符证书
cd /letsencrypt

rm -rf /root/.acme.sh
mkdir /root/.acme.sh

#下载最新的acme.sh脚本
rm -rf /letsencrypt/acme.sh
wget --no-cache https://raw.githubusercontent.com/Neilpang/acme.sh/master/acme.sh || exit
chmod 777 acme.sh

#强制更新一次，实时使用最新的协议
sh acme.sh --upgrade || exit

#xxxxxxxxxxx
export Ali_Key="xxxxxxxxxxxxxxxx"
export Ali_Secret="xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
sh acme.sh --issue --dns dns_ali -d xxxxx.com -d *.xxxxx.com --keylength 4096 --force || exit
openssl dhparam -out /root/.acme.sh/xxxxx.com/dhparam.xxxxx.pem 2048 || exit

#重启nginx
nginx -t && nginx -s reload