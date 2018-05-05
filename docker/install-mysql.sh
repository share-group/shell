#linux mysql自动安装程序 
#运行例子：mkdir -p /shell && cd /shell && rm -rf install-mysql.sh && wget --no-cache https://raw.githubusercontent.com/share-group/shell/master/docker/install-mysql.sh && sh install-mysql.sh 8.0.11 /usr/local

#处理外部参数
mysql_version=$1
mysql_install_path=$2
if [ ! $mysql_version ] || [ ! $mysql_install_path ]; then
	echo 'error command!!! you must input mysql install path...'
	echo 'for example: sh install-mysql.sh 8.0.11 /usr/local'
	exit
fi
 
#建立临时安装目录
echo 'preparing working path...'
install_path='/install'
rm -rf $install_path
mkdir -p $install_path

#建立数据目录
mysql_data_path=$mysql_install_path/mysql/data
rm -rf $mysql_data_path
mkdir -p $mysql_data_path

#创建配置文件
rm -rf /etc/my.cnf
echo "[client]
port = 3306

[mysqld]
port = 3306
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
max_connections = 1000
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

#用docker安装
docker pull daocloud.io/library/mysql:$mysql_version

#启动mysql
docker run --name mysql -p 3306:3306 -v /etc/my.cnf:/etc/mysql/my.cnf -v $mysql_data_path:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=root -d hub.c.163.com/library/mysql:$mysql_version

echo '' >> /etc/rc.d/rc.local
echo 'docker mysql start' >> /etc/rc.local

#输出版本号
docker exec mysql sh -c 'mysql -uroot -proot -e "select VERSION();"' || exit

#长连命令：docker exec -it mysql bash 

#mysql主从配置命令
#主：GRANT REPLICATION SLAVE ON *.* to 'slave'@'192.168.142.130' identified by 'slave'; 
#    FLUSH PRIVILEGES;
#    show master status;
#    执行完此步骤后不要再操作主服务器MYSQL，防止主服务器状态值变化
#    复制 File 和 Position 的值到slave
#    
#    
#    
#从：change master to master_host='mysql.master.com',master_port=3306,master_user='slave-user',master_password='slave-password',master_log_file='mysql-bin.000004',master_log_pos=308;
#     start slave;
#	  show slave status;
#     出现下面的信息，证明主从同步成功
#     Slave_IO_Running: Yes    //此状态必须YES     
#     Slave_SQL_Running: Yes    //此状态必须YES
#	  stop slave;