#!/bin/sh

# Set Linux PATH Environment Variables
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Check If You Are Root
if [ $(id -u) != "0" ]; then
    clear
    echo -e "\033[31m Error: You must be root to run this script! \033[0m"
    exit 1
fi

SysName='';
egrep -i "centos" /etc/issue && SysName='centos';
egrep -i "debian" /etc/issue && SysName='debian';
egrep -i "ubuntu" /etc/issue && SysName='ubuntu';


if [ $(arch) == x86_64 ]; then
    OSB=x86_64
elif [ $(arch) == i686 ]; then
    OSB=i386
else
    echo "\033[31m Error: Unable to Determine OS Bit. \033[0m"
    exit 1
fi
if egrep -q "5\." /etc/issue; then
    OST=5
    wget http://dl.fedoraproject.org/pub/epel/5/${OSB}/epel-release-5-4.noarch.rpm
elif egrep -q "6\." /etc/issue; then
    OST=6
    wget http://dl.fedoraproject.org/pub/epel/6/${OSB}/epel-release-6-8.noarch.rpm
else
    echo "\033[31m Error: Unable to Determine OS Version. \033[0m"
    exit 1
fi

rpm -Uvh epel-release*rpm
rm -rf /etc/yum.repos.d/epel.repo
rm -rf /etc/yum.repos.d/epel-testing.repo
wget http://github.itzmx.com/1265578519/mirrors/master/EPEL/epel.repo -O /etc/yum.repos.d/epel.repo
wget http://github.itzmx.com/1265578519/mirrors/master/EPEL/epel-testing.repo -O /etc/yum.repos.d/epel-testing.repo
yum install -y libnet libnet-devel libpcap libpcap-devel gcc

wget -c http://github.itzmx.com/1265578519/net-speeder/master/net_speeder.c -O net_speeder.c
wget -c http://github.itzmx.com/1265578519/net-speeder/master/build.sh -O build.sh
if [ -f /proc/user_beancounters ] || [ -d /proc/bc ]; then
    sh build.sh -DCOOKED
    INTERFACE=venet0
else
    sh build.sh
    INTERFACE=eth0
fi

NS_PATH=/usr/local/netspeeder
mkdir -p $NS_PATH
cp -Rf net_speeder $NS_PATH/net_speeder

echo "#!/bin/bash
#chkconfig: 345 85 15
#description: netspeeder start script.
### BEGIN INIT INFO
# Provides:          LZH
# Required-Start:    $remote_fs $network
# Required-Stop:     $remote_fs $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: The NetSpeeder
### END INIT INFO

start() {
	nohup ${NS_PATH}/net_speeder $INTERFACE \"ip\" >/dev/null 2>&1 &
	echo 'NetSpeeder Started!';
}

stop() {
	sync;
	for PID in \`ps aux|grep -E 'net_speeder'|grep -v grep|awk '{print \$2}'\`; do
		kill -s 9 \$PID >/dev/null;
	done;
	echo 'NetSpeeder Stoped!';
}

case \"\$1\" in
	start)
		start
		;;
	stop)
		stop
		;;
	restart)
		stop
		start
		;;
	*)
		echo \$\"Usage: \$prog {start|stop|restart}\"
		exit 1
esac">/etc/rc.d/init.d/netspeederd
chmod 775 /etc/rc.d/init.d/netspeederd

if [ "$SysName" == 'centos' ]; then
	chkconfig netspeederd on;
else
	update-rc.d -f netspeederd defaults;
fi;

cd ..
rm -rf epel-release-5-4.noarch.rpm epel-release-6-8.noarch.rpm epel-release-5-4.noarch.rpm net_speeder

service netspeederd start
echo -e "\033[36m net_speeder installed. \033[0m"
