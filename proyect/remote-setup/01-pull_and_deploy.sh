#!/bin/bash

# remote-setup/pull_and_deploy.sh

# in $HOME/setup, create the new playbook
touch deploy.yml

# PASTE the contents of deploy.yml
vi deploy.yml

# execute it
ansible-playbook -i inventory.ini deploy.yml
