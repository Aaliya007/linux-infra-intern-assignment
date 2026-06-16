#!/bin/bash

echo "================================="
echo "Infrastructure Validation"
echo "================================="

echo ""

if id infraadmin >/dev/null 2>&1; then
    echo "✓ infraadmin user exists"
else
    echo "✗ infraadmin user missing"
fi

if [ -d /opt/infra-demo ]; then
    echo "✓ application directory exists"
else
    echo "✗ application directory missing"
fi

if [ -d /var/log/infra-demo ]; then
    echo "✓ log directory exists"
else
    echo "✗ log directory missing"
fi

if systemctl is-active --quiet infra-demo; then
    echo "✓ service is running"
else
    echo "✗ service is not running"
fi

if systemctl is-enabled --quiet infra-demo; then
    echo "✓ service is enabled"
else
    echo "✗ service is not enabled"
fi

if curl -s http://localhost:8080/health >/dev/null; then
    echo "✓ health endpoint reachable"
else
    echo "✗ health endpoint failed"
fi

echo ""
echo "Validation complete."
