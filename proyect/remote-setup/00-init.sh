#!/bin/bash

# remote-setup/init.sh

# Update the package manager
sudo yum update -y

# Install Python3 and Pip (Ansible requires Python)
sudo yum install python3-pip vim -y

# Install Ansible using Pip
pip3 install ansible

## ========== ##

# create setup/ folder
cd $HOME && mkdir setup && cd setup

# create my-key.pem, inventory.ini, setup.yml files
touch my-key.pem && touch inventory.ini && touch setup.yml

## PASTE labuser.pem CONTENTS
vi my-key.pem

# change file permissions
chmod 0400 my-key.pem

## PASTE inventory.ini CONTENTS
vi inventory.ini

## PASTE setup.yml CONTENTS
vi setup.yml

# execute ansible playbook
ansible-playbook -i inventory.ini setup.yml
