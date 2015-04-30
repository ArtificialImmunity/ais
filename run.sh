#!/bin/bash
sudo /usr/local/bin/barnyard2 -c /etc/snort/barnyard2.conf -d /var/log/snort -f snort.log -w /var/log/barnyard2/bylog.waldo -C /etc/snort/classification.config

