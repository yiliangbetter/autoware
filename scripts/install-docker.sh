#!/usr/bin/env bash
# Install Docker Engine on Ubuntu 22.04 and allow non-root usage.
# Run in an interactive terminal: ./scripts/install-docker.sh
set -euo pipefail

echo "==> Fixing hostname in /etc/hosts (stops sudo warnings)..."
if ! grep -q "$(hostname)" /etc/hosts 2>/dev/null; then
  echo "127.0.1.1 $(hostname)" | sudo tee -a /etc/hosts
fi

echo "==> Installing Docker Engine..."
sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  ca-certificates curl \
  docker.io docker-compose-v2

echo "==> Starting Docker service..."
sudo systemctl enable --now docker

echo "==> Adding ${USER} to the docker group..."
sudo usermod -aG docker "${USER}"

echo "==> Verifying installation (as root)..."
sudo docker run --rm hello-world

echo ""
echo "Docker installed successfully."
echo ""
echo "Next steps:"
echo "  1. Activate the docker group in this shell:"
echo "       newgrp docker"
echo "  2. Verify without sudo:"
echo "       docker info"
echo "  3. Run the Autoware planning simulator:"
echo "       ./scripts/setup-planning-sim.sh"
