#!/bin/bash

LOG_FILE="/var/log/infra-demo/maintenance.log"

echo "=================================" >> "$LOG_FILE"
echo "Maintenance Run: $(date)" >> "$LOG_FILE"
echo "=================================" >> "$LOG_FILE"

echo "Disk Usage:" >> "$LOG_FILE"
df -h >> "$LOG_FILE"

echo "" >> "$LOG_FILE"

echo "Memory Usage:" >> "$LOG_FILE"
free -h >> "$LOG_FILE"

echo "" >> "$LOG_FILE"
