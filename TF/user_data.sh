#!/bin/bash
sudo apt -y update
sudo apt install git -y
sudo apt-add-repository ppa:ansible/ansible -y
sudo apt install ansible -y
sudo git clone https://github.com/silver2mike/ProdEnv.git
ansible-playbook ProdEnv/prod.yml
