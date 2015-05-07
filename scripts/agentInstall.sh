#!/bin/bash

#Author Jordan Bruce

#takes up aprox 384Mb

#		[for best results, run as sudoer]
# "--------------------------------------------------"
# "By installing this scirpt, you will be downloading"
# "all packages nessissary to run Snort with Barnyard2" 
# "and MySQL. As well as configuration changes. Do NOT
# "continue unless you have permission and have read"
# "through all the changes it will make"
# "--------------------------------------------------"


apt-get update -y; apt-get upgrade -y;

#Auto add IP for snort HOME_NET
SNORTIP=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2| cut -d' ' -f1)
echo snort snort/address_range  string  $SNORTIP | debconf-set-selections

#snort dependicies
for i in snort make gcc flex bison libpcap-dev
do
	apt-get install $i -y;
done

if [ ! -d /opt/daq-2.0.4/ ]; then

	wget -O /opt/daq-2.0.4.tar.gz https://www.snort.org/downloads/snort/daq-2.0.4.tar.gz
	tar xvfz /opt/daq-2.0.4.tar.gz -C /opt
	cd /opt/daq-2.0.4
	./configure; make; make install
	#uncomment output alert
	sed -i 's/# output alert_syslog: LOG_AUTH LOG_ALERT/output alert_syslog: LOG_AUTH LOG_ALERT/g' /etc/snort/snort.conf

	sed -i "s/^include\ \$RULE_PATH/#include\ \$RULE_PATH/g" /etc/snort/snort.conf
	
	sed -i "s|^#include \$RULE_PATH/local.rules|include \$RULE_PATH/local.rules|g" /etc/snort/snort.conf

	sed -i 's/output unified2: filename snort.log, limit 128, nostamp, mpls_event_types, vlan_event_types/output unified2: filename snort.log, limit 128, mpls_event_types, vlan_event_types/g' /etc/snort/snort.conf


	echo -e "alert icmp \$HOME_NET any -> any any (msg:\"ICMP Test NOW! \"; classtype:not-suspicious; sid:1000001; rev:1;)" >> /etc/snort/rules/local.rules


	rm /var/log/snort/snort.log
	rm -r /opt/daq-2.0.4.tar.gz; cd
    service snort restart
fi;



#Barnyard

for i in autoconf libtool build-essential libmysqld-dev checkinstall git
do
	apt-get install $i -y;
done

if [ ! -d /opt/libdnet-1.12/ ]; then

	wget -O /opt/libdnet-1.12.tgz https://libdnet.googlecode.com/files/libdnet-1.12.tgz --no-check-certificate
	tar xvfz /opt/libdnet-1.12.tgz -C /opt
	cd /opt/libdnet-1.12/
	./configure; make; checkinstall -y
	dpkg -i /opt/libdnet_1.12-1_amd64.deb
	rm -r /opt/libdnet-1.12.tgz; cd
fi;

if [ ! -d /usr/src/barnyard2/ ]; then
	cd /usr/src; git clone git://github.com/firnsy/barnyard2.git
	cd barnyard2

	./autogen.sh
	autoreconf -fvi -I ./m4
	./configure --with-mysql --with-mysql-libraries=/usr/lib/x86_64-linux-gnu
	make; make install
	cp /usr/local/etc/barnyard2.conf /etc/snort
	cp schemas/create_mysql /usr/src
	mkdir /var/log/barnyard2

	#Barnyard configure

	sed -i 's/output alert_fast: stdout/output alert_fast/g' /etc/snort/barnyard2.conf

	sed -i 's/#   output database: log, mysql, user=root password=test dbname=db host=localhost/output database: log, mysql, user=snort password=password dbname=snort host=localhost/g' /etc/snort/barnyard2.conf

	bash -c "sudo . /usr/share/oinkmaster/create-sidmap.pl /etc/snort/rules > /etc/snort/sid-msg.map"
fi;


#mysql install
debconf-set-selections <<< 'mysql-server mysql-server/root_password password password' #sets auto mysql prompt password to 'password'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password password' #sets auto mysql prompt comfirm password to 'password'
apt-get install mysql-server -y


#Snort MySQL set up

if [ ! -d /var/lib/mysql/snort ]; then
	for mysqlCommand in "CREATE DATABASE snort;" "CREATE DATABASE archive;" "GRANT USAGE ON snort.* to snort@localhost;" "GRANT USAGE ON archive.* to snort@localhost;" "set password for snort@localhost=PASSWORD('password');" "GRANT ALL PRIVILEGES ON snort.* to snort@localhost;" "GRANT ALL PRIVILEGES ON archive.* to snort@localhost;" "FLUSH PRIVILEGES;" "USE snort;" "SOURCE /usr/src/create_mysql;"
	do
		    echo $mysqlCommand >> mysqlCommands
	done
	mysql -u root -p --password='password'<mysqlCommands
	rm mysqlCommands
fi;

#SysLog MySQL set up

if [ ! -d /var/lib/mysql/syslog ]; then
    for mysqlCommand in "CREATE DATABASE syslog;" "CREATE USER 'syslog'@'localhost' IDENTIFIED BY 'password';" "GRANT USAGE ON syslog.* to syslog@localhost;" "GRANT ALL PRIVILEGES ON syslog.* to syslog@localhost;" "FLUSH PRIVILEGES;" "USE syslog;" "SOURCE /usr/local/src/ais/tablesmysql/create_mysql_syslog;"
    do
            echo $mysqlCommand >> mysqlCommands
    done
    mysql -u root -p --password='password'<mysqlCommands
    rm mysqlCommands
fi;

#Ban list MySQL set up

if [ ! -d /var/lib/mysql/banlist ]; then
    for mysqlCommand in "CREATE DATABASE banlist;" "CREATE USER 'banlist'@'localhost' IDENTIFIED BY 'password';" "GRANT USAGE ON banlist.* to banlist@localhost;" "GRANT ALL PRIVILEGES ON banlist.* to banlist@localhost;" "FLUSH PRIVILEGES;" "USE banlist;" "SOURCE /usr/local/src/ais/tablesmysql/create_mysql_banlist_agent;"
    do
            echo $mysqlCommand >> mysqlCommands
    done
    mysql -u root -p --password='password'<mysqlCommands
    rm mysqlCommands
fi;


#Python install

#apt-get install
for i in python-pip python-mysqldb python-dev
do
	apt-get install $i -y;
done

#pip install
for i in python-iptables netifaces
do
	pip install $i;
done
service snort restart

#get apache2 to act as a web server
apt-get install apache2 -y

#crontab
CRONFILE=mycrontab
crontab -l > $CRONFILE
echo "* * * * * /usr/local/src/ais/agents/netagent.py" >> $CRONFILE #look in db for snort rules and potentially ban ips
echo "* * * * * /usr/local/src/ais/agents/sysagent.py" >> $CRONFILE #look at system data and potentially ban ips
echo "* * * * * /usr/local/src/ais/scripts/collectAndFlush.sh" >> $CRONFILE #send banlist to collector and flush local db
crontab $CRONFILE
rm $CRONFILE

echo "Done!"
