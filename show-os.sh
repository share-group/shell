#返回linux操作系统类型

result=$(cat /etc/issue | grep  'Ubuntu')
if [ "$result" != "" ]; then
  echo "Ubuntu"
else
  echo "CentOS"
fi