#!/bin/bash

# Разворачиваем ВМ с помощью Vagrant
vagrant up

# Настраиваем ВМ с Ansible
ansible-playbook main.yml
