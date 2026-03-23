#!/bin/bash

cd /root

apt update
apt install -y wget tar

wget https://github.com/garethgeorge/backrest/releases/download/v1.12.1/backrest_Linux_x86_64.tar.gz
mkdir backrest
tar -xzvf backrest_Linux_x86_64.tar.gz -C backrest && cd backrest

mkdir ~/.config/
mkdir ~/.config/backrest/
mv ~/config.json ~/.config/backrest/config.json

./install.sh
