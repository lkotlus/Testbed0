#!/bin/bash

USERNAME=mgebril
PASSWORD=sopmac6yelhsa

SSHDPATH="/etc/ssh/sshd_config"

sudo sed -i 's/^#PasswordAuthentication/PasswordAuthentication/' $SSHDPATH
sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' $SSHDPATH

sudo useradd -m $USERNAME
sudo chpasswd <<< "$USERNAME:$PASSWORD"

sudo systemctl restart ssh
