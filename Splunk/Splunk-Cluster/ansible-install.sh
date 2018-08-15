#!/bin/bash
sudo yum -y install epel-release
sudo yum -y install ansible

# Dynamically build ansible inventory based on parameters from vagrant
# Format of each argument: "ansible_group hostname ip"
# Servers of the same ansible_group should be adjacent in order
for var in "$@"
do    
    ans_group=$(echo "$var" | awk '{print $1}')
    ans_host=$(echo "$var" | awk '{print $2}')
    ans_ip=$(echo "$var" | awk '{print $3}')

    # if current group unset, define first ansible group
    if [ -z ${current_group+x} ]; then
    	current_group=$(echo "$var" | awk '{print $1}')
    	ansible_config="[$current_group]\n"
    # if we detect a new group, write new group
    elif [ "$current_group" != "$ans_group"  ]; then
    	ansible_config="$ansible_config\n[$ans_group]\n"
    	current_group="$ans_group"
    fi

    # Write the host into ansible inventory
    ansible_config="$ansible_config$ans_host ansible_host=$ans_ip\n"
done

# Create parent-child relationships for Splunk servers
ansible_config="$ansible_config\n[splunk_servers:children]\nsplunk_master\nsplunk_indexers\nsplunk_search\nsplunk_search_deployer\nsplunk_hf\nsplunk_ds\n"

# Add defaults to ansible config
ansible_config="$ansible_config\n[all:vars]\nansible_ssh_user=vagrant\nansible_ssh_pass=vagrant"

# Build ansible working directory / inventory
mkdir -p /home/vagrant/ansible
cd /home/vagrant/ansible

# Bring over all ansible configurations built on the vagrant host
sudo cp -r /media/ansible/* /home/vagrant/ansible
sudo chown -R vagrant.vagrant /home/vagrant/ansible

printf "$ansible_config" > /home/vagrant/ansible/hosts

echo '[defaults]
inventory = /home/vagrant/ansible/hosts
host_key_checking = False
remote_tmp = /tmp/.ansible/tmp
gathering = smart
forks = 50
' > /home/vagrant/ansible/ansible.cfg

# Verify Ansible can talk to all hosts in vagrant config
ansible all -m ping