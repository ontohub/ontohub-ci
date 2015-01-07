#!/bin/bash

# create jenkins user
adduser --disabled-password --gecos '' --home /home/jenkins jenkins

# allow jenkins to use sudo command
adduser jenkins sudo
echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# create ssh key for jenkins
echo ""
echo "========================================"
echo "Generating SSH keypair for user jenkins"
mkdir ~jenkins/.ssh
ssh-keygen -t rsa -b 4096 -N '' -C jenkins@ontohub-test-server -f ~jenkins/.ssh/id_rsa
chown -R jenkins:jenkins ~jenkins/.ssh
chmod 700 ~jenkins/.ssh
echo "--- BEGIN SSH public key for jenkins ---"
cat ~jenkins/.ssh/id_rsa.pub
echo "---  END SSH public key for jenkins  ---"
echo "========================================"
echo ""
