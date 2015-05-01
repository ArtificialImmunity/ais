#!/usr/bin/python
from agentlib import *
import MySQLdb
import subprocess

class Collector():
    allAgents = []
    allBannedIPs = []
    bannedIPs = {'127.0.0.1' : 0}
    globalBanList = []

    threshold = 0

    #Gets ip source addresses from collector bannedIPs table and puts them in allBannedIPs
    def getBannedIPs(self):
        con = MySQLdb.Connection(host='localhost', user='banlist', passwd='password', db='banlist')

        cur = con.cursor()

        cur.execute("SELECT ip_src FROM bannedIPs;")

        for row in cur.fetchall():
            #print row[0]
            ip = ipDecToOct(row[0])
            self.allBannedIPs.append(ip)

        if con:
            con.close()
        return

    #Gets all ips in allBannedIPs and puts them in bannedIPs dict with number of times they've been banned
    def getNumberedBanList(self):
        for ip in self.allBannedIPs: #cycle through all ips found
            if ip in self.bannedIPs:
                self.bannedIPs[ip] = self.bannedIPs[ip] + 1 #count No times for each ip
            else:
                self.bannedIPs[ip] = 1 #else create new dict entry
        return

    #Gets all the registered agents on the network and adds them to allAgents whilst updating threshold
    def getAllAgents(self):
        for agent in open("allAgentIPs", "r"):
            self.allAgents.append(agent.strip("\n"))
        self.threshold = len(self.allAgents)*0.35  # threshold is set to 35% of the network
        return

    #Gets all IPs in bannedIPs who exceed threshold and puts them in global ban list
    def addToGlobalBanList(self):
        for ip in self.bannedIPs:
            if self.bannedIPs[ip] > self.threshold:#if src ip is banned on more than 35% of the number of agents, global ban them
                self.globalBanList.append(ip)
        return

    #Get all ips from global ban list and runs script to add iptables rules to ban all incomming and outgoing
    #traffic on all nodes from that ip
    def banFromAllAgents(self):
        #for ip in banGlobalIPs
        #run subprocess bash script
        #-bash script takes in ip and sets iptables rule to ban all traffic from that ip
        banScript = "/usr/local/src/ais/scripts/banGlobalIP.sh"
        for ip in self.globalBanList:
            subprocess.call([banScript, ip.strip()], shell=False)
        #subprocess.call("test.sh", shell=True) #needs to be updated to /usr/local/src/ais/scripts/*banGlobalAgents*
        return
collector = Collector()

#class containing sensor methods for collector
class Sensor:
    def __init__(self):
        pass

    #Contains all sensor methods for collector
    def sense(self):
        collector.getBannedIPs()
        print collector.allBannedIPs
        collector.getNumberedBanList()
        print collector.bannedIPs
        collector.getAllAgents()
        print collector.allAgents
        collector.addToGlobalBanList()
        print collector.globalBanList
        return

#class containing actuator methods for all rules
class Actuator:
    def __init__(self):
        pass

    #Contains all actuating methods for collector
    def actuate(self):
        collector.banFromAllAgents()
        return

def main():
    sensor = Sensor()
    sensor.sense()

    actuator= Actuator()
    actuator.actuate()
    return


if __name__ == '__main__':
    main()