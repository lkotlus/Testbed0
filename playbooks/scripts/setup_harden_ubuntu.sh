#!/bin/bash

# 
# Make SSH relatively secure
#
SSHDPATH="/etc/ssh/sshd_config"

sudo sed -i 's/^#PermitRootLogin/PermitRootLogin/' $SSHDPATH
sudo sed -i 's/^PermitRootLogin .*/PermitRootLogin no/' $SSHDPATH

sudo systemctl restart ssh
# 
# Actually create user passwords
#
touch ignore_users.txt

mapfile users < <(awk -F: '($3>=1000||$1=="root")&&($1!="nobody") {print $1}' /etc/passwd | grep -v -x -f ignore_users.txt)

cat <<EOF > create_passwords.py
import sys
import string
import random
characters = string.ascii_letters + string.digits
out = ''
for user in sys.argv[1:]:
    passwd = ''.join([random.choice(characters) for _ in range(16)])
    out += f"{user.strip()}:{passwd}\n"
out = out.strip()
print(out)
EOF

python3 ./create_passwords.py "${users[@]}" > passwords.txt

cat passwords.txt | sudo chpasswd

rm create_passwords.py passwords.txt
rm ignore_users.txt
