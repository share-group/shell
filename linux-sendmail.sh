# 没安装邮件工具的第一次会提示安装
apt install -y mailutils

# 配置邮件发送参数
echo "set from=xxxxxxxxxxxxxxxxxxxxxxxxx@xxxxxxxxxxxxxxxxx.com.cn
set smtp=\"smtps://xxxxxxxxxxxxxxxxx.com.cn:25\"
set smtp-auth=login
set smtp-auth-user=xxxxxxxxxxxxxxxx@xxxxxxxxxxxxxxx.com.cn
set smtp-auth-password=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" > /etc/s-nail.rc

# 配置邮件接收人员(如需发送多个人员用英文逗号“,”分割)
recv='xxxxxxxxxxxxxxx@gf.com.cn,xxxxxxxxxxxxxxx@gf.com.cn'

function check() {
  url=$1
  ip=`ifconfig ens160 | grep "inet addr" | awk -F "[: ]+" '{print $4}'`
  code=`curl -I -s ${url} | head -1 | cut -d " " -f2`
  if [ $code != "200" ]; then
    echo "$url 访问出现异常，请联系相关人员进行处理！" | mail -s "服务异常告警" $recv -aFrom:邮件发送来源\<xxxxxxxxxxxxxxxxx@com.cn\>
  fi
}

check https://xxxxxxxxxxx.xxxxxxxxxxxxx.com