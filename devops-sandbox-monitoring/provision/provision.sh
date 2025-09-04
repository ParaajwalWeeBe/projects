#!/usr/bin/env bash
# provision/provision.sh
set -euo pipefail

PROM_VER="2.53.0"
ALERT_VER="0.27.0"
NODE_VER="1.8.1"

echo "[+] Apt update and base packages"
sudo apt-get update -y
sudo apt-get install -y curl wget tar jq unzip apt-transport-https software-properties-common gnupg ca-certificates

echo "[+] Create users and dirs"
sudo useradd --no-create-home --shell /usr/sbin/nologin prometheus || true
sudo useradd --no-create-home --shell /usr/sbin/nologin node_exporter || true
sudo useradd --no-create-home --shell /usr/sbin/nologin alertmanager || true

sudo mkdir -p /etc/prometheus /var/lib/prometheus
sudo mkdir -p /etc/alertmanager /var/lib/alertmanager

echo "[+] Install Prometheus $PROM_VER"
cd /tmp
wget -q https://github.com/prometheus/prometheus/releases/download/v${PROM_VER}/prometheus-${PROM_VER}.linux-amd64.tar.gz
tar -xzf prometheus-${PROM_VER}.linux-amd64.tar.gz
cd prometheus-${PROM_VER}.linux-amd64
sudo cp prometheus promtool /usr/local/bin/
sudo cp -r consoles console_libraries /etc/prometheus/
sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus

echo "[+] Install Node Exporter $NODE_VER"
cd /tmp
wget -q https://github.com/prometheus/node_exporter/releases/download/v${NODE_VER}/node_exporter-${NODE_VER}.linux-amd64.tar.gz
tar -xzf node_exporter-${NODE_VER}.linux-amd64.tar.gz
cd node_exporter-${NODE_VER}.linux-amd64
sudo cp node_exporter /usr/local/bin/
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter || true

echo "[+] Install Alertmanager $ALERT_VER"
cd /tmp
wget -q https://github.com/prometheus/alertmanager/releases/download/v${ALERT_VER}/alertmanager-${ALERT_VER}.linux-amd64.tar.gz
tar -xzf alertmanager-${ALERT_VER}.linux-amd64.tar.gz
cd alertmanager-${ALERT_VER}.linux-amd64
sudo cp alertmanager amtool /usr/local/bin/
sudo chown alertmanager:alertmanager /usr/local/bin/alertmanager /usr/local/bin/amtool || true
sudo chown -R alertmanager:alertmanager /var/lib/alertmanager

echo "[+] Install Grafana OSS"
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://packages.grafana.com/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/grafana.gpg
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt-get update -y
sudo apt-get install -y grafana

echo "[+] Copy configs from synced folder"
# /vagrant is the repo root inside the VM
sudo cp /vagrant/configs/prometheus/prometheus.yml /etc/prometheus/prometheus.yml
sudo cp /vagrant/configs/prometheus/alerts.yml /etc/prometheus/alerts.yml
sudo chown -R prometheus:prometheus /etc/prometheus

sudo cp /vagrant/configs/alertmanager/alertmanager.yml /etc/alertmanager/alertmanager.yml
sudo chown -R alertmanager:alertmanager /etc/alertmanager

sudo mkdir -p /etc/grafana/provisioning/datasources /etc/grafana/provisioning/dashboards /var/lib/grafana/dashboards
sudo cp /vagrant/configs/grafana/provisioning/datasources/datasource.yml /etc/grafana/provisioning/datasources/datasource.yml
sudo cp /vagrant/configs/grafana/provisioning/dashboards/dashboards.yml /etc/grafana/provisioning/dashboards/dashboards.yml
sudo cp /vagrant/configs/grafana/dashboards/sandbox-overview.json /var/lib/grafana/dashboards/sandbox-overview.json
sudo chown -R grafana:grafana /etc/grafana /var/lib/grafana

echo "[+] Systemd units"
sudo cp /vagrant/systemd/prometheus.service /etc/systemd/system/prometheus.service
sudo cp /vagrant/systemd/node_exporter.service /etc/systemd/system/node_exporter.service
sudo cp /vagrant/systemd/alertmanager.service /etc/systemd/system/alertmanager.service

echo "[+] Enable and start services"
sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter
sudo systemctl enable --now alertmanager
sudo systemctl enable --now prometheus
sudo systemctl enable --now grafana-server

echo "[+] Install stress-ng for testing alerts"
sudo apt-get install -y stress-ng

echo "[✓] Provisioning complete"

