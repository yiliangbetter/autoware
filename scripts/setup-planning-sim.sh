#!/usr/bin/env bash
# Install Docker + demo data, then run Autoware planning simulator with RViz.
# Requires: Ubuntu 22.04, sudo, X11 display (DISPLAY set).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MAP_DIR="${HOME}/autoware_data/maps/sample-map-planning"
MAP_ZIP="${HOME}/autoware_data/maps/sample-map-planning.zip"
MAP_URL="https://autoware-files.s3.us-west-2.amazonaws.com/maps/demos/sample-map-planning.zip"
DEMO_DIR="${REPO_ROOT}/docker/examples/demos/planning-simulator"

echo "==> Checking prerequisites..."
if ! command -v docker >/dev/null 2>&1; then
  echo "Installing Docker (requires sudo password in an interactive terminal)..."
  # Fix 'unable to resolve host' sudo warning if hostname is missing from /etc/hosts
  if ! grep -q "$(hostname)" /etc/hosts 2>/dev/null; then
    echo "Tip: if sudo warns about host resolution, run: echo \"127.0.1.1 $(hostname)\" | sudo tee -a /etc/hosts"
  fi
  sudo apt-get update -qq
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y docker.io docker-compose-v2 curl unzip
  sudo systemctl enable --now docker
  sudo usermod -aG docker "${USER}"
  echo "Added ${USER} to the docker group."
  echo "Run: newgrp docker   (or log out and back in), then re-run this script."
  exit 0
fi

if ! docker info >/dev/null 2>&1; then
  if groups | grep -q docker; then
    echo "Docker daemon not reachable. Try: sudo systemctl start docker"
  else
    echo "Permission denied for docker. Run: newgrp docker   then re-run this script."
  fi
  exit 1
fi

echo "==> Downloading sample map (if missing)..."
mkdir -p "${HOME}/autoware_data/maps"
if [[ ! -d "${MAP_DIR}" ]]; then
  if command -v curl >/dev/null 2>&1; then
    curl -fL -o "${MAP_ZIP}" "${MAP_URL}"
  else
    wget -O "${MAP_ZIP}" "${MAP_URL}"
  fi
  unzip -q -o "${MAP_ZIP}" -d "${HOME}/autoware_data/maps/"
fi
echo "Map ready at ${MAP_DIR}"

echo "==> Tuning host network buffers for ROS 2 / Cyclone DDS..."
# Required by Autoware DDS; containers cannot always set these themselves.
# https://autowarefoundation.github.io/autoware-documentation/main/installation/additional-settings-for-developers/network-configuration/dds-settings/
if [[ "$(sysctl -n net.core.rmem_max 2>/dev/null || echo 0)" -lt 10485760 ]]; then
  echo "Applying sysctl settings (sudo password may be required)..."
  sudo sysctl -w net.core.rmem_max=2147483647
  sudo sysctl -w net.ipv4.ipfrag_time=3
  sudo sysctl -w net.ipv4.ipfrag_high_thresh=134217728
fi

echo "==> Allowing Docker to use X11..."
if command -v xhost >/dev/null 2>&1; then
  xhost +local:docker
fi

echo "==> Pulling Autoware image (large download, may take a while)..."
docker pull ghcr.io/autowarefoundation/autoware:universe-jazzy

echo "==> Launching planning simulator with RViz..."
cd "${DEMO_DIR}"
HOST_UID="$(id -u)" HOST_GID="$(id -g)" \
  AUTOWARE_REPO_ROOT="${REPO_ROOT}" \
  docker compose run --rm planning-simulator
