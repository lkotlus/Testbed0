#!/bin/bash
# FLASK MACHINE

sudo apt update
sudo apt install -y curl

# install app.py dependencies
sudo apt install -y python3-pip mysql-client-core-8.0
pip install flask
pip install mysql-connector-python 

# install app.py and run
cat <<EOF > app.py 
from flask import Flask
import mysql.connector
import os
import time

app = Flask(__name__)

IP_ADDR = os.getenv("IP_ADDR")

db = None
while db is None:
    try:
        db = mysql.connector.connect(host=IP_ADDR, username='flask', password = 'sudo', database='users')
    except mysql.connector.Error as e:
        print(f"Waiting for MySQL: {e}")
        time.sleep(2)

cursor = db.cursor()

@app.route('/')
def hello_world():
    cursor.execute('SELECT * FROM users')
    result = cursor.fetchall()
    return f'<p>{result}</p>'
EOF

cat <<EOF > /etc/systemd/system/flask.service
[Unit]
Description=Flask App
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu
Environment="IP_ADDR=${IP_ADDR}"
ExecStart=python3 -m flask run --host=0.0.0.0
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable flask
systemctl start flask
