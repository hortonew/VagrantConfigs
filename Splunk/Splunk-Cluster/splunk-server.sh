#!/bin/bash
cd /media/rpms

# Install Splunk, accepting the default license.  Verify it starts on boot as splunk user
sudo rpm -ivh splunk-6.4.4-b53a5c14bb5e-linux-2.6-x86_64.rpm
sudo su - splunk -c "splunk start --accept-license"
sudo /opt/splunk/bin/splunk enable boot-start -user splunk

# Modify default password
sudo su - splunk -c "splunk edit user admin -password vagrant -auth admin:changeme"

# Make sure Splunk is listening on default port - output to user
netstat -an | grep -i 8000 | grep -i LIST