#!/bin/bash

set -euo pipefail

echo "================================="
echo "Linux Infra Provisioning Started"
#!/bin/bash

set -euo pipefail

echo "================================="
echo "Linux Infra Provisioning Started"
echo "================================="

# --------------------------------
# Root Check
# --------------------------------

if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo."
    exit 1
fi

# --------------------------------
# OS Detection
# --------------------------------

echo ""
echo "Detecting operating system..."

if [ -f /etc/os-release ]; then
    . /etc/os-release
else
    echo "Unable to detect operating system."
    exit 1
fi

echo "Detected: $NAME $VERSION_ID"

# --------------------------------
# Package Updates
# --------------------------------

echo ""
echo "Updating package index..."

apt-get update

# --------------------------------
# Install Required Packages
# --------------------------------

echo ""
echo "Installing required packages..."

apt-get install -y \
    curl \
    git \
    ufw \
    python3 \
    python3-venv

echo "Cleaning up unused packages..."

apt-get autoremove -y

# --------------------------------
# Create Operational User
# --------------------------------

echo ""
echo "Checking infraadmin user..."

if id "infraadmin" >/dev/null 2>&1; then
    echo "User already exists."
else
    useradd -m -s /bin/bash infraadmin
    usermod -aG sudo infraadmin
    echo "User created successfully."
fi

# --------------------------------
# Create Application Directories
# --------------------------------

echo ""
echo "Creating application directories..."

mkdir -p /opt/infra-demo
mkdir -p /var/log/infra-demo

# --------------------------------
# Create Environment File
# --------------------------------

echo ""
echo "Checking environment file..."

if [ ! -f config/infra-demo.env ]; then
    cat > config/infra-demo.env <<EOF
PORT=8080
LOG_DIR=/var/log/infra-demo
EOF
    echo "Environment file created."
else
    echo "Environment file already exists."
fi

# --------------------------------
# Set Ownership
# --------------------------------

echo ""
echo "Setting permissions..."

chown -R infraadmin:infraadmin /opt/infra-demo
chown -R infraadmin:infraadmin /var/log/infra-demo

# --------------------------------
# Verification
# --------------------------------

echo ""
echo "Verifying setup..."

id infraadmin >/dev/null 2>&1 && echo "✓ User exists"

[ -d /opt/infra-demo ] && echo "✓ Application directory exists"

[ -d /var/log/infra-demo ] && echo "✓ Log directory exists"

[ -f config/infra-demo.env ] && echo "✓ Environment file exists"

# --------------------------------
# Finished
# --------------------------------

echo ""
echo "================================="
echo "Provisioning completed successfully."
echo "================================="#!/bin/bash

set -euo pipefail

echo "================================="
echo "Linux Infra Provisioning Started"
echo "================================="

# --------------------------------
# Root Check
# --------------------------------

if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo."
    exit 1
fi

# --------------------------------
# OS Detection
# --------------------------------

echo ""
echo "Detecting operating system..."

if [ -f /etc/os-release ]; then
    . /etc/os-release
else
    echo "Unable to detect operating system."
    exit 1
fi

echo "Detected: $NAME $VERSION_ID"

# --------------------------------
# Package Updates
# --------------------------------

echo ""
echo "Updating package index..."

apt-get update

# --------------------------------
# Install Required Packages
# --------------------------------

echo ""
echo "Installing required packages..."

apt-get install -y \
    curl \
    git \
    ufw \
    python3 \
    python3-venv

echo "Cleaning up unused packages..."

apt-get autoremove -y

# --------------------------------
# Create Operational User
# --------------------------------

echo ""
echo "Checking infraadmin user..."

if id "infraadmin" >/dev/null 2>&1; then
    echo "User already exists."
else
    useradd -m -s /bin/bash infraadmin
    usermod -aG sudo infraadmin
    echo "User created successfully."
fi

# --------------------------------
# Create Application Directories
# --------------------------------

echo ""
echo "Creating application directories..."

mkdir -p /opt/infra-demo
mkdir -p /var/log/infra-demo

# --------------------------------
# Create Environment File
# --------------------------------

echo ""
echo "Checking environment file..."

if [ ! -f config/infra-demo.env ]; then
    cat > config/infra-demo.env <<EOF
PORT=8080
LOG_DIR=/var/log/infra-demo
EOF
    echo "Environment file created."
else
    echo "Environment file already exists."
fi

# --------------------------------
# Set Ownership
# --------------------------------

echo ""
echo "Setting permissions..."

chown -R infraadmin:infraadmin /opt/infra-demo
chown -R infraadmin:infraadmin /var/log/infra-demo

# --------------------------------
# Verification
# --------------------------------

echo ""
echo "Verifying setup..."

id infraadmin >/dev/null 2>&1 && echo "✓ User exists"

[ -d /opt/infra-demo ] && echo "✓ Application directory exists"

[ -d /var/log/infra-demo ] && echo "✓ Log directory exists"
#!/bin/bash

set -euo pipefail

echo "================================="
echo "Linux Infra Provisioning Started"
echo "================================="

# --------------------------------
# Root Check
# --------------------------------

if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo."
    exit 1
fi

# --------------------------------
# OS Detection
# --------------------------------

echo ""
echo "Detecting operating system..."

if [ -f /etc/os-release ]; then
    . /etc/os-release
else
    echo "Unable to detect operating system."
    exit 1
fi

echo "Detected: $NAME $VERSION_ID"

# --------------------------------
# Package Updates
# --------------------------------

echo ""
echo "Updating package index..."

apt-get update

# --------------------------------
# Install Required Packages
# --------------------------------

echo ""
echo "Installing required packages..."

apt-get install -y \
    curl \
    git \
    ufw \
    python3 \
    python3-venv

echo "Cleaning up unused packages..."

apt-get autoremove -y

# --------------------------------
# Create Operational User
# --------------------------------

echo ""
echo "Checking infraadmin user..."

if id "infraadmin" >/dev/null 2>&1; then
    echo "User already exists."
else
    useradd -m -s /bin/bash infraadmin
    usermod -aG sudo infraadmin
    echo "User created successfully."
fi

# --------------------------------
# Create Application Directories
# --------------------------------

echo ""
echo "Creating application directories..."

mkdir -p /opt/infra-demo
mkdir -p /var/log/infra-demo

# --------------------------------
# Create Environment File
# --------------------------------

echo ""
echo "Checking environment file..."

if [ ! -f config/infra-demo.env ]; then
    cat > config/infra-demo.env <<EOF
PORT=8080
LOG_DIR=/var/log/infra-demo
EOF
    echo "Environment file created."
else
    echo "Environment file already exists."
fi

# --------------------------------
# Set Ownership
# --------------------------------

echo ""
echo "Setting permissions..."

chown -R infraadmin:infraadmin /opt/infra-demo
chown -R infraadmin:infraadmin /var/log/infra-demo

# --------------------------------
# Verification
# --------------------------------

echo ""
echo "Verifying setup..."

id infraadmin >/dev/null 2>&1 && echo "✓ User exists"

[ -d /opt/infra-demo ] && echo "✓ Application directory exists"

[ -d /var/log/infra-demo ] && echo "✓ Log directory exists"

[ -f config/infra-demo.env ] && echo "✓ Environment file exists"

# --------------------------------
# Finished
# --------------------------------

echo ""
echo "================================="
echo "Provisioning completed successfully."
echo "================================="
