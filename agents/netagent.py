#!/usr/bin/python
# -*- coding: utf-8 -*-

#This is the agent coding for the raw networking side of the ais
#It uses the snort rules and MySQL database to determine bad traffic

from agentlib import *
import MySQLdb
import iptc

class PingFlood:

    def __init__(self):
        pass

    allIPPF = [] #list for all ips found with 404 errors
    ipsPF = {'127.0.0.1' : 0} #dict for all ips found, with number of occurrences
    banIPPF = [] #list for all ips who number of occurrences exceed threshold
    thisIP = getThisIP()
    threshold = 15 #amount of ping requests allow per minute
    reason = "Ping Flood Attempt"


    #Gets all ICMP packets from database (from snort alerts)
    def fetchIPs(self):
        con = MySQLdb.Connection(host='localhost', user='snort', passwd='password', db='snort')

        cur = con.cursor()

        cur.execute("SELECT event.cid, iphdr.ip_src, iphdr.ip_dst, event.timestamp\
                    FROM iphdr\
                    INNER JOIN event\
                    ON event.cid=iphdr.cid\
                    WHERE timestamp > date_sub(now(), interval 60 second);")

        for row in cur.fetchall():
            #print row[1]
            ip = ipDecToOct(row[2])
            if ip != self.thisIP:
                self.allIPPF.append(ip)

        if con:
            con.close()
        return

    #Gets all ping request source IPs ad put them in dict with number of ping requests
    def getSrcCount(self):
        for ip in self.allIPPF: #cycle through all ips found
            if ip in self.ipsPF:
                self.ipsPF[ip] = self.ipsPF[ip] + 1 #count No times for each ip
            else:
                self.ipsPF[ip] = 1 #else create new dict entry
        return

    #Puts ip in ban list if number of ping requests is over the threshold
    def icmpPingFlood(self):
        for ip in self.ipsPF:
            if self.ipsPF[ip] >= self.threshold:
                self.banIPPF.append(ip)

    #Adds rule to IPTables if ip is in the ban list
    def banICMPFlood(self):
        #Cycle through ban list
        for ip in self.banIPPF:
            #Add IPTables rule for ping requests
            chain = iptc.Chain(iptc.Table(iptc.Table.FILTER), "INPUT")
            rule = iptc.Rule()
            rule.in_interface = "eth0"
            rule.src = ip
            rule.protocol = "icmp"
            target = iptc.Target(rule, "DROP")
            rule.target = target
            chain.insert_rule(rule)
        updateBanList(banlist=self.banIPPF, mysqlhost=collectorIP, mysqluser='banlist', mysqlpass='password',\
                        mysqldb='banlist', dstip=self.thisIP, reason=self.reason)
        return

pingFlood = PingFlood()

#class containing sensor methods for all rules
class Sensor:
    def __init__(self):
        pass

    def sense(self):
        pingFlood.fetchIPs()
        pingFlood.getSrcCount()
        pingFlood.icmpPingFlood()
        return

#class containing actuator methods for all rules
class Actuator:
    def __init__(self):
        pass

    def actuate(self):
        pingFlood.banICMPFlood()
        return


def main():

    sensor = Sensor()
    sensor.sense()

    actuator= Actuator()
    actuator.actuate()

    #print "- All IPs with ICMP amount -"
    #print pingFlood.ips

    #print "Done"

    return

if __name__ == '__main__':
    main()
