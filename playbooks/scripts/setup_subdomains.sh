sudo apt update
sudo apt install -y nginx ufw

sudo mv /home/ubuntu/subdomains.conf /etc/nginx/sites-available/subdomains.conf
sudo ln -sf /etc/nginx/sites-available/subdomains.conf /etc/nginx/sites-enabled/subdomains.conf
sudo rm /etc/nginx/sites-available/default
sudo rm /etc/nginx/sites-enabled/default

sudo nginx -t

sudo ufw default deny incoming
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

sudo systemctl enable nginx
sudo systemctl restart nginx
