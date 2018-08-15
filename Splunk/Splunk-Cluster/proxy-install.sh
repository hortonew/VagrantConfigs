#!/bin/bash
sudo yum -y install epel-release
sudo yum -y install haproxy

# TODO: Create SSL cert (letsencrypt?)

# Make sure haproxy is stopped to reconfigure
sudo systemctl stop haproxy

sudo mkdir -p /etc/firewalld/services/

sudo echo '<?xml version="1.0" encoding="utf-8"?>
<service>
<short>HAProxy-HTTP</short>
<description>HAProxy load-balancer</description>
<port protocol="tcp" port="80"/>
</service>' > /etc/firewalld/services/haproxy-http.xml

sudo restorecon /etc/firewalld/services/haproxy-http.xml
sudo chmod 640 /etc/firewalld/services/haproxy-http.xml


sudo echo '<?xml version="1.0" encoding="utf-8"?>
<service>
<short>HAProxy-HTTPS</short>
<description>HAProxy load-balancer</description>
<port protocol="tcp" port="443"/>
</service>' > /etc/firewalld/services/haproxy-https.xml

sudo restorecon /etc/firewalld/services/haproxy-https.xml
sudo chmod 640 /etc/firewalld/services/haproxy-https.xml

sudo echo 'global
	maxconn     4096
	nbproc      1
	debug
	daemon
	log         127.0.0.1    local0
 defaults
	mode        http
	option      httplog
	log         global
	timeout connect 5000ms
	timeout client 50000ms
	timeout server 50000ms

frontend http_web *:80
    mode http
    default_backend splunk-search

frontend http_splunk_ds *:8089
    mode http
    default_backend splunk-ds

backend splunk-search
    balance roundrobin
    mode http
    cookie SRV insert indirect nocache
    server search1 10.0.3.121:8000 cookie splnksh1 weight 1 maxconn 512 check port 8000
    server search2 10.0.3.122:8000 cookie splnksh2 weight 1 maxconn 512 check port 8000
    server search3 10.0.3.123:8000 cookie splnksh3 weight 1 maxconn 512 check port 8000

backend splunk-ds
    balance roundrobin
    mode http
    cookie SRV insert indirect nocache
    server ds1 10.0.3.151:8089 cookie splnkds1 weight 1 maxconn 512 check port 8089
    server ds2 10.0.3.152:8089 cookie splnkds2 weight 1 maxconn 512 check port 8089' > /etc/haproxy/haproxy.cfg

# Make sure haproxy is started
sudo systemctl enable haproxy
sudo systemctl start haproxy