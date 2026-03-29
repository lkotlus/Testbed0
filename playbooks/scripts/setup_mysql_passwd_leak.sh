#!/bin/bash
# SQL MACHINE

echo "creating users database"
# We need a set of secure passwords and one bad password. mgebril's password can be found in rockyou.txt.
declare -A users=(
    [jdonin]="SoSk47eI6ieeqDio"
    [breaper5]="FcjLXGhvjxVsWt1R"
    [lkotlus]="cu5KbU7svreG7g6k"
    [rsimonpi]="QBMklAwaTfsvssI8"
    [mgebril]="sopmac6yelhsa"
)

sql_values=()
for user in "${!users[@]}"
do
    hashed=$(printf "%s" "${users[$user]}" | sha256sum | awk '{ print $1 }')
    sql_values+=("('$user','$hashed')")
done

password_db=$(IFS=,; echo "${sql_values[*]}")

# now for the mysql server
echo "creating mysql service"
sudo apt install -y mysql-server

sudo mysql <<EOF
CREATE DATABASE IF NOT EXISTS users;
USE users;
CREATE TABLE IF NOT EXISTS users (id INT AUTO_INCREMENT PRIMARY KEY, username VARCHAR(100), password VARCHAR(100));
INSERT INTO users (username, password) VALUES $password_db;

CREATE USER IF NOT EXISTS 'flask'@'10.0.2.%' IDENTIFIED BY 'sudo';
CREATE USER IF NOT EXISTS 'sql'@'localhost' IDENTIFIED BY 'sudo';
GRANT ALL PRIVILEGES ON users.* TO 'flask'@'10.0.2.%';
GRANT ALL PRIVILEGES ON users.* TO 'sql'@'localhost';
FLUSH PRIVILEGES;
EOF

# change config
sudo sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql
