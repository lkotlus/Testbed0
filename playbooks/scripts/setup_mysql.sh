#!/bin/bash
# SQL MACHINE

sudo apt update
sudo apt install -y curl

# now for the mysql server
sudo apt install -y mysql-server
sudo mysql <<EOF
CREATE DATABASE IF NOT EXISTS users;
USE users;
CREATE TABLE IF NOT EXISTS users (id INT AUTO_INCREMENT PRIMARY KEY, username VARCHAR(100), password VARCHAR(100));
INSERT INTO users (username, password) VALUES ('admin', 'password');

CREATE USER IF NOT EXISTS 'flask'@'10.0.2.%' IDENTIFIED BY 'sudo';
GRANT ALL PRIVILEGES ON users.* TO 'flask'@'10.0.2.%';
FLUSH PRIVILEGES;
EOF

# change config
sudo sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql
