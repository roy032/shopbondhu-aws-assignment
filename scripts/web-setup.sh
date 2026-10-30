#!/usr/bin/env bash
# Run on shopbondhu-web (Tasks 7-8). Copy frontend/ to ~/frontend first (scp or git clone).
set -euo pipefail
sudo apt update && sudo apt install -y nginx
sudo systemctl enable --now nginx
sudo cp -r ~/frontend/* /var/www/html/
sudo nginx -t && sudo systemctl reload nginx
curl -I http://localhost
