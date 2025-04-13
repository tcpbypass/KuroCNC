#!/bin/bash

# Kuro CNC Installation Script for Ubuntu/Debian
# Developed By Bane On a random ass sunday night

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Display banner
echo -e "${BLUE}"
echo "=============================="
echo "   Kuro CNC Installer"
echo "   Developed By Bane"
echo "=============================="
echo -e "${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root (use sudo)${NC}"
  exit 1
fi

# Check if this is Ubuntu or Debian
if [ ! -f /etc/debian_version ]; then
    echo -e "${YELLOW}Warning: This script is optimized for Ubuntu/Debian. Your system may not be fully compatible.${NC}"
    echo -e "Continuing anyway in 5 seconds... Press Ctrl+C to cancel."
    sleep 5
fi

# Installation directory
INSTALL_DIR="/opt/KuroCnc"

# GitHub release information
GITHUB_USER="tcpbypass"
GITHUB_REPO="KuroCNC"
VERSION="v1.0.0"

# Detect architecture
if [ $(uname -m) == "x86_64" ]; then
    ARCH="amd64"
elif [ $(uname -m) == "aarch64" ]; then
    ARCH="arm64"
else
    echo -e "${RED}Unsupported architecture: $(uname -m)${NC}"
    exit 1
fi

echo -e "${YELLOW}Installing dependencies...${NC}"
apt-get update
apt-get install -y wget unzip postgresql postgresql-contrib

echo -e "${YELLOW}Creating installation directory: $INSTALL_DIR${NC}"
mkdir -p "$INSTALL_DIR"

# Download URL
DOWNLOAD_URL="https://github.com/$GITHUB_USER/$GITHUB_REPO/releases/download/$VERSION/KuroCnc_linux_${ARCH}.zip"

echo -e "${YELLOW}Downloading Kuro CNC package...${NC}"
echo "From: $DOWNLOAD_URL"

# Download and extract
wget "$DOWNLOAD_URL" -O /tmp/kurocnc.zip
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Download failed. Please check your internet connection or the download URL.${NC}"
    exit 1
fi

echo -e "${YELLOW}Extracting files...${NC}"
unzip -o /tmp/kurocnc.zip -d /tmp
cp -R /tmp/KuroCnc_linux_${ARCH}/* "$INSTALL_DIR/"
rm -f /tmp/kurocnc.zip
rm -rf /tmp/KuroCnc_linux_${ARCH}

# Set proper permissions
chmod +x "$INSTALL_DIR/KuroCnc"

# Configure PostgreSQL
echo -e "${YELLOW}Setting up PostgreSQL database...${NC}"
systemctl start postgresql
systemctl enable postgresql

# Create a PostgreSQL user and database if it doesn't exist
su - postgres -c "psql -c \"CREATE USER kurocnc WITH PASSWORD 'kurocnc';\""
su - postgres -c "psql -c \"CREATE DATABASE kurocnc;\""
su - postgres -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE kurocnc TO kurocnc;\""
echo -e "${GREEN}PostgreSQL database setup complete${NC}"

# Create a systemd service file
echo -e "${YELLOW}Creating systemd service...${NC}"
cat > /etc/systemd/system/kurocnc.service << EOL
[Unit]
Description=Kuro CNC Server
After=network.target postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/KuroCnc
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOL

# Create environment file with database credentials
cat > $INSTALL_DIR/.env << EOL
PGHOST=localhost
PGPORT=5432
PGUSER=kurocnc
PGPASSWORD=kurocnc
PGDATABASE=kurocnc
DATABASE_URL=postgres://kurocnc:kurocnc@localhost:5432/kurocnc
EOL

# Reload systemd
systemctl daemon-reload

echo -e "${GREEN}Installation completed successfully!${NC}"
echo -e "${YELLOW}To run the setup wizard:${NC}"
echo -e "cd $INSTALL_DIR"
echo -e "./KuroCnc -setup"
echo
echo -e "${YELLOW}To start the CNC server as a service:${NC}"
echo -e "systemctl start kurocnc"
echo
echo -e "${YELLOW}To enable automatic startup:${NC}"
echo -e "systemctl enable kurocnc"
echo
echo -e "${BLUE}=============================="
echo -e "   Kuro CNC Has Been Installed"
echo -e "   Developed By Bane"
echo -e "==============================${NC}"