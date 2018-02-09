#运行例子：sh install-erlang.sh /usr/local 17.5
 
#定义本程序的当前目录
base_path=$(pwd)
ntpdate ntp.api.bz

#处理外部参数
erlang_install_path=$1
erlang_install_version=$2
if [ ! $erlang_install_path ] || [ ! $erlang_install_version ]; then
	echo 'error command!!! you must input erlang install path and install version...'
	echo 'for example: sh install-erlang.sh /usr/local 17.4'
	exit
fi

yum -y install gmake libtool sed gcc gcc-c++ make net-snmp net-snmp-devel net-snmp-utils libc6-dev python-devel rsync perl bc lrzsz openssh-server postfix cronie vim-enhanced readline readline-devel ncurses-devel gdbm-devel glibc-devel tcl-devel openssl-devel curl-devel expat-devel db4-devel byacc sqlite-devel libyaml libyaml-devel libffi libffi-devel libxml2 libxml2-devel libxslt libxslt-devel libicu libicu-devel system-config-firewall-tui python-devel crontabs logwatch logrotate perl-Time-HiRes autoconf 

#建立临时安装目录
echo 'preparing working path...'
install_path='/install'
rm -rf $install_path
mkdir -p $install_path

# 安装OpenSSL
openssl='openssl-1.1.0g'
if [ ! -d $erlang_install_path/openssl ]; then
	echo 'installing '$openssl' ...'
	if [ ! -f $base_path/$openssl.tar.gz ]; then
		echo $openssl'.tar.gz is not exists, system will going to download it...'
		wget -O $base_path/$openssl.tar.gz http://install.ruanzhijun.cn/$openssl.tar.gz || exit
		echo 'download '$openssl' finished...'
	fi
	tar zxvf $base_path/$openssl.tar.gz -C $install_path || exit
	cd $install_path/$openssl
	./config --prefix=$erlang_install_path/openssl && $install_path/$openssl/config -t && make && make test && make install || exit
	yes|cp $erlang_install_path/openssl/bin/* /usr/bin/
	echo $openssl' install finished...'
fi

#安装erlang
erlang=$erlang_install_version 
if [ ! -d $erlang_install_path/erlang ]; then 
	echo 'installing erlang '$erlang'...'
	if [ ! -f $base_path/otp_src_$erlang.tar.gz ]; then
		echo 'otp_src_'$erlang'.tar.gz is not exists, system will going to download it...'
		wget -O $base_path/otp_src_$erlang.tar.gz http://install.ruanzhijun.cn/otp_src_$erlang.tar.gz || exit
		echo 'download erlang'$erlang' finished...'
	fi
	tar zxvf $base_path/otp_src_$erlang.tar.gz -C $install_path || exit
	cd $install_path/otp_src_$erlang/lib/crypto/c_src
	replace='11111111111111'
	sed -i 's/&& !defined(OPENSSL_NO_EC)/'$replace'/' crypto.c || exit
	sed -i 's/'$replace'/\&\& !defined(OPENSSL_NO_EC) \&\& !defined(OPENSSL_NO_EC2M)/' crypto.c || exit
	cd $install_path/otp_src_$erlang
	./configure --with-ssl --enable-sctp --enable-kernel-poll --enable-smp-support --enable-threads --enable-halfword-emulator --disable-hipe --enable-native-libs --enable-m64-build --prefix=$erlang_install_path/erlang && make && make install || exit
	cd $erlang_install_path/erlang/lib/erlang/bin
	yes | cp -rf ct_run /usr/bin/ || exit
	yes | cp -rf erlc /usr/bin/ || exit
	yes | cp -rf erl /usr/bin/ || exit
	yes | cp -rf escript /usr/bin/ || exit
	yes | cp -rf dialyzer /usr/bin/ || exit
	yes | cp -rf start_erl /usr/bin/ || exit
	yes | cp -rf to_erl /usr/bin/ || exit
	yes | cp -rf run_erl /usr/bin/ || exit
	yes | cp -rf typer /usr/bin/ || exit
fi
