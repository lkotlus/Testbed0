#!/bin/bash
# FLASK MACHINE

# install app.py dependencies
sudo apt update
sudo apt install -y python3-pip mysql-client-core-8.0
pip install flask mysql-connector-python

# Create a service file
cat <<EOF > /etc/systemd/system/flask.service
[Unit]
Description=Flask App
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu
ExecStart=python3 -m flask run --host=0.0.0.0
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable flask
systemctl start flask
