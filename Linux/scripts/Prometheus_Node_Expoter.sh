#!/bin/bash

# Set variables
NODE_EXPORTER_VERSION="1.6.1"  # Replace with the desired version
NODE_EXPORTER_USER="node_exporter"
DOWNLOAD_URL="https://github.com/prometheus/node_exporter/releases/download/v$NODE_EXPORTER_VERSION/node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz"
INSTALL_DIR="/usr/local/bin"
SERVICE_FILE="/etc/systemd/system/node_exporter.service"

# Update and install prerequisites
echo "Updating system and installing prerequisites..."
sudo apt update -y && sudo apt install -y wget tar

# Create a dedicated user for Node Exporter
echo "Creating node_exporter user..."
if ! id -u $NODE_EXPORTER_USER >/dev/null 2>&1; then
    sudo useradd --no-create-home --shell /usr/sbin/nologin $NODE_EXPORTER_USER
else
    echo "User $NODE_EXPORTER_USER already exists."
fi

# Download and install Node Exporter
echo "Downloading Node Exporter..."
wget -q $DOWNLOAD_URL -O /tmp/node_exporter.tar.gz

echo "Extracting Node Exporter..."
tar -xzf /tmp/node_exporter.tar.gz -C /tmp

echo "Installing Node Exporter..."
sudo mv /tmp/node_exporter-$NODE_EXPORTER_VERSION.linux-amd64/node_exporter $INSTALL_DIR

# Set permissions
sudo chown $NODE_EXPORTER_USER:$NODE_EXPORTER_USER $INSTALL_DIR/node_exporter
sudo chmod 755 $INSTALL_DIR/node_exporter

# Clean up
echo "Cleaning up..."
rm -rf /tmp/node_exporter*

# Create systemd service file
echo "Creating systemd service file..."
sudo bash -c "cat > $SERVICE_FILE" <<EOF
[Unit]
Description=Prometheus Node Exporter
Documentation=https://prometheus.io/docs/guides/node-exporter/
Wants=network-online.target
After=network-online.target

[Service]
User=$NODE_EXPORTER_USER
Group=$NODE_EXPORTER_USER
Type=simple
ExecStart=$INSTALL_DIR/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, start, and enable the Node Exporter service
echo "Reloading systemd, starting, and enabling Node Exporter..."
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter

# Verify installation
echo "Verifying Node Exporter installation..."
if systemctl is-active --quiet node_exporter; then
    echo "Node Exporter is running."
    echo "You can access it at http://<server-ip>:9100/metrics"
else
    echo "Node Exporter failed to start. Check logs using: sudo journalctl -u node_exporter"
fi
