#!/bin/bash

# how to deploy individual containers in separate servers

# install ansible docker
ansible-galaxy collection install community.docker

# create and copy deploy_apps.yml
vi deploy_apps.yml
ansible-playbook -i inventory.ini deploy_apps.yml
