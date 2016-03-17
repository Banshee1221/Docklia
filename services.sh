#!/bin/bash
ln -sf /usr/share/zoneinfo/Arfica/Johannesburg /etc/localtime
touch /var/log/ganglia/gmetad.log
touch /var/log/ganglia/gmond.log
service httpd start
gmetad -d 10 >> /var/log/ganglia/gmetad.log 2>&1 &
gmond -d 10 >> /var/log/ganglia/gmond.log 2>&1 &
bash
