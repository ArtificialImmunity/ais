#!/usr/bin/python
import MySQLdb
import sys
from datetime import datetime
import iptc


#crontab runs on the minute
#this get the minute that it just was
now = datetime.now()
currentMinute = now.minute

#class containing sensor and actuator methods for 404 not found errors
class Error404():

    allIP404 = [] #list for all ips found with 404 errors
    ips404 = {'127.0.0.1' : 0} #dict for all ips found, with number of occurances
    banIP404 = [] #list for all ips who number of occurances exceed threshold

    #Gets all 404 errors in the past minute from /var/log/apache2/access.log
    def get404(self):
         #cycle through lines of apache2 access log in reverse order
        for lines in reversed(open("/var/log/apache2/access.log", "r").readlines()):
            #search apache log for 404 errors
            if '404' in lines:
                line = lines.split(" ")
                time = line[3].split(":")
                #get the minute the log was made
                minute = int(time[2])

                #print "Minute = " + str(minute)
                #print "Current Minute = " + str(currentMinute)

                #if it's over the last 60 seconds, break
                if currentMinute != minute:
                    break
                else:
                    #else put the 404 error ip in ip list
                    self.allIP404.append(line[0])


        for allips in self.allIP404: #cycle through all ips found
            if allips in self.ips404:
                self.ips404[allips] = self.ips404[allips] + 1 #count No times for each ip
            else:
                self.ips404[allips] = 1 #else create new dict entry
        return

    #Puts ip into ban list if number of ping requests is over the threshold
    def dirScan(self):
        threshold = 1 #threshold for 404 errors allowed per minute
        for ip in self.ips404:
            if self.ips404[ip] > threshold:#if ip 404 errors is over threshold, add to ban list
                self.banIP404.append(ip)
        return

    #Creates iptables rules to ban all ips in ban ip list
    def ban404Scan(self):
        #cycle through ban list
        for ip in self.banIP404:
            #make an IPTables rule for the ban ip on port 80 (HTTP)
            chain = iptc.Chain(iptc.Table(iptc.Table.FILTER), "INPUT")
            rule = iptc.Rule()
            rule.in_interface = "eth0"
            rule.src = ip
            rule.protocol = "tcp"
            match = iptc.Match(rule, "tcp")
            match.dport = "80"
            rule.add_match(match)
            target = iptc.Target(rule, "DROP")
            rule.target = target
            chain.insert_rule(rule)
        return
error404 = Error404()

#class containing sensor and actuator methods for ssh auth failures
class SSHAuthFail():

    allIPSSH = [] #list for all ips found with SSH auth failures
    ipsSSH = {'127.0.0.1' : 0} #dict for all ips found, with number of occurances
    banIPSSH = [] #list for all ips who number of occurances exceed threshold

    #Gets all SSH auth fails and puts respective Ips in allIPSSH
    def getSSHAuthFail(self):
        for lines in reversed(open("/var/log/auth.log", "r").readlines()): #cycle through lines of ssh authentication log.
            if 'sshd' in lines:
                if 'Failed' in lines:
                    line = lines.split(" ")
                    time = line[2].split(":")
                    #get the minute the log was made
                    minute = int(time[1])

                    #print "Minute = " + str(minute)
                    #print "Current Minute = " + str(currentMinute)

                    #if it's over the last 60 seconds, break
                    if currentMinute != minute:
                        break
                    else:
                        #else put the SSH Auth Fail ip in ip list
                        self.allIPSSH.append(line[10])

        for allips in self.allIPSSH: #cycle through all ips found
            if allips in self.ipsSSH:
                self.ipsSSH[allips] = self.ipsSSH[allips] + 1 #count No times for each ip
            else:
                self.ipsSSH[allips] = 1 #else create new dict entry
        return

    #Puts ip in ban list if number of ping requests is over the threshold
    def SSHBruteForce(self):
        threshold = 1 #threshold for 404 errors allowed per minute
        for ip in self.ipsSSH:
            if self.ipsSSH[ip] > threshold:#if ip 404 errors is over threshold, add to ban list
                self.banIPSSH.append(ip)
        return

    #Creates iptables rules to ban all ips in ban ip list
    def banSSH(self):
        #cycle through ban list
        for ip in self.banIPSSH:
            #make an IPTables rule for the ban ip on port 22 (SSH)
            chain = iptc.Chain(iptc.Table(iptc.Table.FILTER), "INPUT")
            rule = iptc.Rule()
            rule.in_interface = "eth0"
            rule.src = ip
            rule.protocol = "tcp"
            match = iptc.Match(rule, "tcp")
            match.dport = "22"
            rule.add_match(match)
            target = iptc.Target(rule, "DROP")
            rule.target = target
            chain.insert_rule(rule)
        return
sshAuthFail = SSHAuthFail()

#class containing sensor methods for all rules
class Sensor():

    def sense(self):
        error404.get404()
        error404.dirScan()

        sshAuthFail.getSSHAuthFail()
        sshAuthFail.SSHBruteForce()
        return

#class containing actuator methods for all rules
class Actuator():

    def actuate(self):
        error404.ban404Scan()

        sshAuthFail.banSSH()
        return

def main():

    sensor = Sensor()
    sensor.sense()

    actuator= Actuator()
    actuator.actuate()

    print "404 ips = "
    print error404.ips404
    print "SSH ips = "
    print sshAuthFail.ipsSSH
    return


if __name__ == '__main__':
    main()