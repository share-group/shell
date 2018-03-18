#自签通配符证书

rm -rf /root/.acme.sh
export Ali_Key="LTAI4rx2G4I3F6sx"
export Ali_Secret="ghN1PjKHn9Eos3uGNDK8njWrtlC6Hh"

cd /letsencrypt
if [ ! -f acme.sh ]; then
	wget --no-cache https://raw.githubusercontent.com/Neilpang/acme.sh/master/acme.sh || exit
	chmod 777 acme.sh
fi

sh acme.sh --issue --dns dns_ali -d api.garybros.com -d *.garybros.com --keylength 4096 --webroot /srv/ --force || exit
rm -rf /srv/.well-known

nginx -t && nginx -s reload