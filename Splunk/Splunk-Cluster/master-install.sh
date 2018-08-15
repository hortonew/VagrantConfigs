#!/bin/bash

# Create license location to use this server as license master
sudo su - splunk -c "mkdir -p /opt/splunk/etc/licenses/enterprise/"
sudo cp /media/splunk-license/Splunk.License /opt/splunk/etc/licenses/enterprise/enterprise.lic
sudo chown splunk.splunk /opt/splunk/etc/licenses/enterprise/enterprise.lic

# Add license into Splunk, making this server the license master for the environment
sudo su - splunk -c "splunk add licenses /opt/splunk/etc/licenses/enterprise/enterprise.lic -auth admin:vagrant"
sudo su - splunk -c "splunk restart"