#!/bin/bash

# Configure remote licensing
sudo su - splunk -c "splunk edit licenser-localslave -master_uri 'https://10.0.3.100:8089'"
sudo su - splunk -c "splunk restart"