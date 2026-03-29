#!/bin/bash

sudo apt update
sudo apt install -y wget unzip

wget https://github.com/lkotlus/Testbed0/releases/download/Dependencies/duckdb_cli-linux-amd64.zip
wget https://github.com/lkotlus/Testbed0/releases/download/Dependencies/grafana_11.0.0_amd64.deb
wget https://github.com/lkotlus/Testbed0/releases/download/Dependencies/motherduck-duckdb-datasource-0.4.1.zip

sudo apt install -y ./grafana_11.0.0_amd64.deb
rm ./grafana_11.0.0_amd64.deb

sudo systemctl start grafana-server
sudo systemctl enable grafana-server

sudo grafana-cli admin reset-admin-password admin

unzip duckdb_cli-linux-amd64.zip
rm duckdb_cli-linux-amd64.zip
chmod +x duckdb
sudo mv duckdb /usr/local/bin/

PLUGIN_NAME="motherduck-duckdb-datasource"
PLUGIN_DIR="/var/lib/grafana/plugins"
PROVISIONING_DIR="/etc/grafana/provisioning/datasources"

mv motherduck-duckdb-datasource-0.4.1.zip /tmp/${PLUGIN_NAME}.zip

sudo mkdir -p $PLUGIN_DIR

cd /tmp
sudo unzip -o ${PLUGIN_NAME}.zip -d $PLUGIN_DIR/
sudo mv $PLUGIN_DIR/${PLUGIN_NAME}* $PLUGIN_DIR/${PLUGIN_NAME} 2>/dev/null || true

sudo sed -i '/^\[plugins\]/,/^\[/{s/^;*allow_loading_unsigned_plugins.*/allow_loading_unsigned_plugins = motherduck-duckdb-datasource/}' /etc/grafana/grafana.ini

grep -q "allow_loading_unsigned_plugins" /etc/grafana/grafana.ini || \
    echo -e "\n[plugins]\nallow_loading_unsigned_plugins = motherduck-duckdb-datasource" | \
    sudo tee -a /etc/grafana/grafana.ini

sudo mkdir -p $PROVISIONING_DIR
sudo tee $PROVISIONING_DIR/duckdb.yaml > /dev/null <<EOF
apiVersion: 1

datasources:
  - name: DuckDB
    type: motherduck-duckdb-datasource
    access: proxy
    isDefault: true
    editable: true
    jsonData:
      path: /tmp/test.duckdb
EOF

touch /tmp/test.duckdb

sudo chown -R grafana:grafana $PLUGIN_DIR
sudo chown -R grafana:grafana /tmp/test.duckdb

sudo mkdir -p /etc/systemd/system/grafana-server.service.d

sudo tee /etc/systemd/system/grafana-server.service.d/override.conf > /dev/null <<EOF
[Service]
Environment="HOME=/tmp"
EOF

GRAFANA_URL="http://localhost:3000"
ADMIN_USER="admin"
ADMIN_PASS="admin"

NEW_USER="entrypoint-admin"
NEW_PASS="P@\$\$w0rd123!"
NEW_EMAIL="entrypoint-admin@entrypoint.dta"

curl -s -X POST "$GRAFANA_URL/api/admin/users" \
  -u "$ADMIN_USER:$ADMIN_PASS" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"$NEW_USER\",
    \"email\": \"$NEW_EMAIL\",
    \"login\": \"$NEW_USER\",
    \"password\": \"$NEW_PASS\"
  }"

sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl restart grafana-server
