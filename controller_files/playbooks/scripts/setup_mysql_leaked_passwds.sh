#!/bin/bash

USERNAME=mgebril
PASSWORD=sopmac6yelhsa

SSHDPATH="/etc/ssh/sshd_config"
SSHDCLOUDPATH="/etc/ssh/sshd_config.d/60-cloudimg-settings.conf"

sudo sed -i 's/^#PasswordAuthentication/PasswordAuthentication/' $SSHDPATH
sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' $SSHDPATH

rm $SSHDCLOUDPATH

sudo useradd -m $USERNAME
sudo chpasswd <<< "$USERNAME:$PASSWORD"

echo "dta_flag{cfa34008-38db-4f22-9756-d90f43c215c4}" > /home/mgebril/flag.txt

sudo systemctl restart ssh
