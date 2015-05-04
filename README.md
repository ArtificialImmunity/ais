# ais
<h1>Artifical Immune System for Linux Servers<h1>

Author: <i>Jordan Bruce</i>

This is a final year project for University. It is a simple ais system which can be installed on a node in a network. For testing purposes I have been using an Ubuntu Server 14.0.4 LTS. 

It will capture all network traffic and log it to a local mysql database. Every ~60 seconds the database is examined by the python code to determine if there is any suspicious traffic (ping flood, ssh brute force, directory scans). If there is, the src IP will be banned. After the 60 seconds are up, the banned IP's are sent to thecentral collector database and the local database is flushed. This improves both time when searching, and reduces excess space being used up. The collector will then look at the global ban list to see if there is one IP that is constantly being banned, if this is the case, the collector will signal all the other agents to ban that IP from all in-going and out-going traffic.

<h2>To set up<h2>

<b><i>It is STRONGLY recommended that you only install this if you are using a fresh install of Ubuntu Server and that you know what the code is doing. An uninstall script has not been created, and as such, I will not be held responsible for any changes you make to you own system as a result of this code</i></b>

Now all the serious stuff is out the way...

You are going to want to start out by setting up a collector on a Linux server.

This can be down by downloading the soruce code from the git repository. The code should be downloaded to the /usr/local/src/ folder.

<code>git clone https://github.com/ArtificialImmunity/ais</code>

You will now be able to run the script:

/usr/local/src/ais/scripts/collectorInstall.sh

This will set up the MySQL database configurations as well as crontab timers for the collector agent.

From the collector you can deploy agents to other servers. First, it is wise to create ssh keys to the agent you are deploying. From the collector run these commands:

<code>su root</code>
<code>ssh-keygen -t rsa</code>
<ssh-copy-id <i>hostname/IP of agent</i></code>
<code>exit</code>

Once the keys are set up, you are now ready to deploy an agent:

<code>sudo ./deployAgent <i>hostname/ IP of agent</i></code>

The agent deploy script will:
    <li>Set up the file structure on the node, and copy over essential node files</li>
    <li>Install dependencies for Snort, Barnyard, MySQL, and Python on the node</li>
    <li>Configure necessary files for the aforementioned programs on the node</li>
    <li>Set crontab timers for netagent.py and sysagent.py on the node</li>

Once the node install script is finished, everything will be set up and configured to run automatically in the background.

The agent will run snort and barnyard2 to monitor and collect network traffic to the MySQL database according to the snort rules and system python script.

The netagent.py and sysagent.py will be added to the crontab and ran on the minute, every minute

The agent will automatically send IPs that have been banned to the collector, the collector will look for IPs that have banned multiple times, over all agents, and set a global ban on IPs with repeated convictions.
