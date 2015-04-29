#!/usr/bin/python
# -*- coding: utf-8 -*-

#This is the agent coding for the raw networking side of the ais
#It uses the snort rules and MySQL database to determine bad traffic

import MySQLdb
import sys
import struct
import socket
import iptc


class PingFlood:

    allIPPF = [] #list for all ips found with 404 errors
    ipsPF = {'127.0.0.1' : 0} #dict for all ips found, with number of occurances
    banIPPF = [] #list for all ips who number of occurances exceed threshold
    thisIP = '192.168.224.137'

    #Convert hex to string (used for packet analysis)
    def hexToString(data):
        return ''.join(chr(int(data[i:i+2], 16)) for i in range(0, len(data), 2))

    #Converts ip from 32 bit integer to 4 dotted octets
    def ipDecToOct(data):
        t = struct.pack("!I", data)
        return socket.inet_ntoa(t)


    #Gets all ICMP packets from database (from snort alerts)
    def fetchIPs(self):
        con = MySQLdb.Connection(host='localhost', user='root', passwd='password', db='snort')

        cur = con.cursor()

        cur.execute("SELECT event.cid, iphdr.ip_src, iphdr.ip_dst, event.timestamp\
                    FROM iphdr\
                    INNER JOIN event\
                    ON event.cid=iphdr.cid\
                    WHERE timestamp > date_sub(now(), interval 60 second);")

        for row in cur.fetchall():
            print row[1]
            ip = self.ipDecToOct(row[1])
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
        threshold = 10
        for ip in self.ipsPF:
            if self.ipsPF[ip] > threshold:
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


pingFlood = PingFlood()

class Sensor:

    def sense(self):
        pingFlood.fetchIPs()
        pingFlood.getSrcCount()
        pingFlood.icmpPingFlood()

class Actuator:

    def actuate(self):
        pingFlood.banICMPFlood()







def main():

    print "- All IPs with ICMP amount -"
    print pingFlood.ips

    print "Done"

    return

if __name__ == '__main__':
    main()
