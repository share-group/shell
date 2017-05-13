#查看某个进程的线程数
 
name=$1
time=$2

while(true)
	do
		echo `date '+%Y-%m-%d %-H:%-M:%-S'` process $name threads: `ps -eLf | grep $name | wc -l`
		sleep $time
	done  