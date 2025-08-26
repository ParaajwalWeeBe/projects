# Self-Healing Infrastructure: NGINX Monitoring Stack

This project demonstrates a self-healing pipeline using Prometheus, Blackbox Exporter, Alertmanager, and a recovery webhook to automatically restart NGINX when it becomes unreachable.

## 🔧 Tech Stack

- Prometheus for monitoring
- Blackbox Exporter for HTTP probing
- Alertmanager for alert routing
- Webhook + Ansible for automated recovery

## 🎯 What It Solves

When NGINX (port 8090) goes down, Prometheus detects the outage, Alertmanager triggers a webhook, and Ansible restarts the container — all within 60 seconds.
