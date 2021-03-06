#!/bin/bash

#Author Jordan Bruce

apt-get update -y; apt-get upgrade -y;

#mysql install
debconf-set-selections <<< 'mysql-server mysql-server/root_password password password' #sets auto mysql prompt password to 'password'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password password' #sets auto mysql prompt comfirm password to 'password'
apt-get install mysql-server -y


#Ban list MySQL set up

if [ ! -d /var/lib/mysql/banlist ]; then
    for mysqlCommand in "CREATE DATABASE banlist;" "CREATE USER 'banlist'@'localhost' IDENTIFIED BY 'password';" "GRANT USAGE ON banlist.* to banlist@localhost;" "GRANT ALL PRIVILEGES ON banlist.* to banlist@localhost;" "FLUSH PRIVILEGES;" "USE banlist;" "SOURCE /usr/local/src/ais/tablesmysql/create_mysql_banlist_collector;"
    do
            echo $mysqlCommand >> mysqlCommands
    done
    mysql -u root -p --password='password'<mysqlCommands
    rm mysqlCommands
fi;

#get the current ip
THISIP="$(ifconfig | grep -A 1 'eth0' | tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1)"

#replace bind address to current ip
#This is needed so MySQL can be accessed over the internet
sed -i "s/bind-address.*/bind-address=$THISIP/g" /etc/mysql/my.cnf


sudo service mysql restart

#added privlidges to access over the network
echo "GRANT ALL ON banlist.* TO banlist@'%' IDENTIFIED BY 'password';" >> mysqlNetUsage
echo "FLUSH PRIVILEGES" >> mysqlNetUsage
mysql -u root -p --password='password'<mysqlNetUsage
rm mysqlNetUsage

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

#crontab
CRONFILE=mycrontab
crontab -l > $CRONFILE
echo "* * * * * /usr/local/src/ais/agents/collectoragent.py" >> $CRONFILE #look in db for snort rules and potentially ban ips
crontab $CRONFILE
rm $CRONFILE

echo "Done!"