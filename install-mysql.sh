#linux mysql自动安装程序 
#运行例子：mkdir -p /shell && cd /shell && rm -rf install-mysql.sh && wget --no-cache https://raw.githubusercontent.com/share-group/shell/master/install-mysql.sh && sh install-mysql.sh /usr/local
 
#定义本程序的当前目录
base_path=$(pwd)
ntpdate ntp.api.bz

#处理外部参数
mysql_install_path=$1
if [ ! $mysql_install_path ] ; then
	echo 'error command!!! you must input mysql install path...'
	echo 'for example: sh install-mysql.sh /usr/local'
	exit
fi

#建立临时安装目录
echo 'preparing working path...'
install_path='/install'
rm -rf $install_path
mkdir -p $install_path

yum -y install libtool sed gcc gcc-c++ make net-snmp net-snmp-devel net-snmp-utils libc6-dev python-devel rsync perl bc libxslt-dev lrzsz ncurses-devel perl bzip2 unzip vim iptables-services httpd-tools socat

#安装cmake
cmake='cmake-3.13.2'
if [ ! -d $mysql_install_path/cmake ]; then
	echo 'installing '$cmake'...'
	if [ ! -f $base_path/$cmake.tar.gz ]; then
		echo $cmake'.tar.gz is not exists, system will going to download it...'
		wget -O $base_path/$cmake.tar.gz http://install.ruanzhijun.cn/$cmake.tar.gz || exit
		echo 'download '$cmake' finished...'
	fi
	tar zxvf $base_path/$cmake.tar.gz -C $install_path || exit
	cd $install_path/$cmake
	./bootstrap --system-curl --prefix=$mysql_install_path/cmake && make && make install || exit
	yes|cp $mysql_install_path/cmake/bin/* /usr/bin/
	echo 'export PATH='$mysql_install_path'/cmake/bin:$PATH' >> ~/.bash_profile
	source ~/.bash_profile
fi

#安装jemalloc
jemalloc='jemalloc-5.1.0'
if [ ! -d $mysql_install_path/jemalloc ]; then
	echo 'installing '$jemalloc' ...'
	if [ ! -f $base_path/$jemalloc.tar.bz2 ]; then
		echo $jemalloc'.tar.bz2 is not exists, system will going to download it...'
		wget -O $base_path/$jemalloc.tar.bz2 http://install.ruanzhijun.cn/$jemalloc.tar.bz2 || exit
		echo 'download '$jemalloc' finished...'
	fi
	tar xvf $base_path/$jemalloc.tar.bz2 -C $install_path || exit
	cd $install_path/$jemalloc
	./configure && make && make install || exit
	echo '/usr/local/lib' > /etc/ld.so.conf.d/local.conf
	ldconfig
fi

#下载boost包
boost='boost_1_59_0'
if [ ! -d $install_path/$boost ]; then
	echo 'installing '$boost' ...'
	if [ ! -f $base_path/$boost.tar.gz ]; then
		echo $boost'.tar.gz is not exists, system will going to download it...'
		wget -O $base_path/$boost.tar.gz http://install.ruanzhijun.cn/$boost.tar.gz || exit
		echo 'download '$boost' finished...'
	fi
	tar zxvf $base_path/$boost.tar.gz -C $install_path || exit
fi

#添加mysql用户
user=$(id -nu mysql)
if [ ! $user ]; then
	user='mysql'
	group='mysql'
	/usr/sbin/groupadd -f $group
	/usr/sbin/useradd -g $group $user
fi

#建立数据目录
mysql_data_path=$mysql_install_path/mysql/data
mkdir -p $mysql_data_path

#赋予数据存放目录权限
chown mysql.mysql -R $mysql_data_path || exit

#安装mysql
echo 'installing mysql...'
mysql='mysql-5.7.19'
if [ ! -d $install_path/$mysql ]; then
	if [ ! -f $base_path/$mysql.tar.gz ]; then
		echo $mysql'.tar.gz is not exists, system will going to download it...'
		wget -O $base_path/$mysql.tar.gz http://install.ruanzhijun.cn/$mysql.tar.gz || exit
		echo 'download '$mysql' finished...'
	fi
	tar zxvf $base_path/$mysql.tar.gz -C $install_path || exit
fi
cd $install_path/$mysql

#删除编译缓存
rm -rf $install_path/$mysql/CMakeCache.txt 

$mysql_install_path/cmake/bin/cmake . -DCMAKE_INSTALL_PREFIX=$mysql_install_path/mysql -DMYSQL_UNIX_ADDR=$mysql_data_path/mysql.sock -DSYSCONFDIR=/etc -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DCMAKE_EXE_LINKER_FLAGS="-ljemalloc" -DWITH_SAFEMALLOC=ON -DWITH_EXTRA_CHARSETS:STRING=utf8 -DWITH_BOOST=$install_path/$boost -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_DEBUG=0 -DWITH_MEMORY_STORAGE_ENGINE=1 -DWITH_READLINE=1 -DENABLED_LOCAL_INFILE=1 -DMYSQL_DATADIR=$mysql_data_path -DMYSQL_USER=mysql || exit

#查询cpu逻辑个数
cpus=$(cat /proc/cpuinfo | grep name | cut -f3 -d: | uniq -c | cut -b 7)

make || exit
make -j `expr 4 \* $cpus` || exit
make install || exit

#复制配置文件
rm -rf /etc/my.cnf
echo "[client]
port = 3306
socket = "$mysql_install_path"/mysql/data/mysql.sock

[mysqld]
port = 3306
socket = "$mysql_install_path"/mysql/data/mysql.sock
basedir = "$mysql_install_path"/mysql
datadir = "$mysql_data_path"
skip-grant-tables
skip-name-resolve
skip-external-locking
key_buffer_size = 100K
max_allowed_packet = 200K
table_open_cache = 64
sort_buffer_size = 100K
net_buffer_length = 100K
read_buffer_size = 400K
read_rnd_buffer_size = 400K
myisam_sort_buffer_size = 100K
max_connections = 100
back_log = 100
join_buffer_size = 200K
thread_cache_size = 1024

#mysql主从配置(主)
#server-id = 1
#log-bin = master-bin
#log-bin-index = master-bin.index
#replicate-ignore-db = sys
#replicate-ignore-db = mysql
#replicate-ignore-db = information_schema
#replicate-ignore-db = performance_schema

#mysql主从配置(从)
#server-id = 2
#relay-log = slave-relay-bin 
#relay-log-index = slave-relay-bin.index
#replicate-ignore-db = sys
#replicate-ignore-db = mysql
#replicate-ignore-db = information_schema
#replicate-ignore-db = performance_schema

innodb_buffer_pool_size = 200K
innodb_log_file_size = 200K
innodb_log_buffer_size = 200K
innodb_flush_log_at_trx_commit = 0
innodb_lock_wait_timeout = 50
key_buffer_size = 200K
sort_buffer_size = 200K
sql-mode=\"STRICT_TRANS_TABLES,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION\"
default_password_lifetime = 0
long_query_time = 0
slow_query_log = 0
log_queries_not_using_indexes = 0
#log-slow-queries = "$mysql_install_path"/mysql/data/slowquery.log
#log-slow-admin-statements
#log-queries-not-using-indexes
explicit_defaults_for_timestamp = true

[mysqldump]
quick
max_allowed_packet = 200K

[mysql]
no-auto-rehash

[myisamchk]
key_buffer_size = 200K
sort_buffer_size = 400K
read_buffer = 200K
write_buffer = 200K

[mysqlhotcopy]
interactive-timeout" > /etc/my.cnf || exit

#初始化数据库
rm -rf $mysql_data_path
$mysql_install_path/mysql/bin/mysqld --initialize --user=mysql --basedir=$mysql_install_path/mysql --datadir=$mysql_data_path

#启动mysql服务
rm -rf /etc/init.d/mysqld
yes|cp -rf $mysql_install_path/mysql/support-files/mysql.server /etc/init.d/mysqld || exit
chmod 755 /etc/init.d/mysqld
yes|cp -rf $mysql_install_path/mysql/bin/* /usr/bin/ || exit

service mysqld start

#修改root密码
mysql -u root -e "truncate mysql.user;" || exit
mysql -u root -e "INSERT INTO mysql.user (Host,User,Select_priv,Insert_priv,Update_priv,Delete_priv,Create_priv,Drop_priv,Reload_priv,Shutdown_priv,Process_priv,File_priv,Grant_priv,References_priv,Index_priv,Alter_priv,Show_db_priv,Super_priv,Create_tmp_table_priv,Lock_tables_priv,Execute_priv,Repl_slave_priv,Repl_client_priv,Create_view_priv,Show_view_priv,Create_routine_priv,Alter_routine_priv,Create_user_priv,Event_priv,Trigger_priv,Create_tablespace_priv,ssl_type,ssl_cipher,x509_issuer,x509_subject,max_questions,max_updates,max_connections,max_user_connections,plugin,authentication_string,password_expired,password_last_changed,password_lifetime,account_locked) VALUES ('%', 'root', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','','','','', 0, 0, 0, 0,'mysql_native_password', password('root'),'N', NULL, NULL,'N');" || exit

sed -i 's/skip-grant-tables/#skip-grant-tables/' /etc/my.cnf || exit

service mysqld restart

#关闭防火墙
systemctl stop firewalld
systemctl disable firewalld.service

#开机自启动
echo '' >> /etc/rc.d/rc.local
echo 'service mysqld start' >> /etc/rc.local
source /etc/rc.d/rc.local

#输出版本
mysql -uroot -proot -e "select VERSION();" || exit

#mysql主从配置命令
#主：GRANT REPLICATION SLAVE ON *.* to 'slave-user'@'mysql.slave.com' identified by 'slave-password'; 
#    show master status;
#    执行完此步骤后不要再操作主服务器MYSQL，防止主服务器状态值变化
#    复制 File 和 Position 的值到slave
#    
#    
#    
#从：change master to master_host='mysql.master.com',master_user='slave-user',master_password='slave-password',master_log_file='mysql-bin.000004',master_log_pos=308;
#     start slave;
#	  show slave status;
#     出现下面的信息，证明主从同步成功
#     Slave_IO_Running: Yes    //此状态必须YES     
#     Slave_SQL_Running: Yes    //此状态必须YES

# alter 修改密码方式：alter user user() identified by "123456";
