# ais
<h1>Artifical Immune System for Linux Servers<h1>

Author: <i>Jordan Bruce</i>

This is a final year project for University. It is a simple ais system which can be installed on a node in a network. For testing purposes I have been using an Ubuntu Server 14.0.4 LTS. 

It will capture all network traffic and log it to a local mysql database. Every ~60 seconds (depending on crontab configurations), the database is examined by the python code to determin if there is any suspicious traffic. If there is, the src IP will be banned. After the 60 seconds are up, the local database is copied to a central collector database (not implimented yet) and the local database is flushed. This improves both time when searching, and reduces excess space being used up.

<h2>To set up<h2>

<b><i>It is STRONGLY recommended that you only install this if you are using a fresh install of Ubuntu Server and that you know what the code is doing. An uninstall script has not been created, and as such, I will not be held responsible for any changes you make to you own system as a result of this code</i></b>

Now all the serious stuff is out the way. You can download the git repository:

<code>git clone https://github.com/ArtificialImmunity/ais</code>

And run the installation script:
(takes ~4mins and ~400MB)

<code>cd /path/to/ais/</code>

<code>sudo ./install.sh</code>

The installation script will:
    <\t><li>Install dependincies for Snort, Barnyard, MySQL, and Python</li>
    <li>Configure nessiscary files for the aforementioned programs</li>
    <li>Create a 'Testbarnyard.sh' file, which will run barnyard to log to packets MySQL</li>
    

Next, set a crontab timer for the python code, 'agent.py'.

<code>crontab -e</code>

Append to the file:

<code>* * * * * /path/to/ais/agent.py</code>

You can now run the 'Testbarnyard.sh' in the back ground.

The testbarnyard logs ICMP (ping) packets to the database while the agent.py runs every 60 seconds to read from the database. If a user has more than 10 ping requests in the past 60 seconds, their IP src Address will be put on a ban list using IPTables.


<h3>To Do:<h3>

I still need to impliment more rules for barnyard to log. This will inculde, SSH Auth Failure, HTTP 404, nmap scans. This is then need more python code to check for and block IPs. The logic will be the same with all of them.

I would like to impliment a way to also log system data. This will look for things like, failed changing to root user, failed running programs as root, creating new accounts.

A central collector also needs to be implimented. After to 60 seconds of python parsing, it should send the data to a central MySQL database and then flush to local database. When all nodes do this, the collector can make decisions based on a group decision e.g. one IP has been blocked on the same network by x nodes, so ban IP on all other nodes, as traffic is most likely malicious. 

