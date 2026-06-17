#!/usr/bin/env bash
set -Eeuo pipefail

APP_NAME="infra-demo"
APP_PORT="${APP_PORT:-8080}"
LOG_DIR="/var/log/${APP_NAME}"
SNAPSHOT_DIR="${LOG_DIR}/health-snapshots"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
TIMESTAMP="$(date -u +'%Y-%m-%dT%H-%M-%SZ')"
SNAPSHOT_FILE="${SNAPSHOT_DIR}/health-${TIMESTAMP}.log"

log() { echo "[maintenance] $*"; }

mkdir -p "${LOG_DIR}" "${SNAPSHOT_DIR}"

{
    echo "timestamp=${TIMESTAMP}"
    echo "hostname=$(hostname -f 2>/dev/null || hostname)"
    echo "uptime=$(uptime -p 2>/dev/null || uptime)"
    echo "disk_usage="
    df -h /
    echo
    echo "memory_usage="
    free -h || true
    echo
    echo "service_status="
    systemctl is-active "${APP_NAME}" || true
    echo
    echo "health_response="
    curl -fsS "http://127.0.0.1:${APP_PORT}/health" || echo "health_check_failed=true"
    echo
    echo "recent_logs="
    journalctl -u "${APP_NAME}" --no-pager -n 20 || true
} > "${SNAPSHOT_FILE}"

find "${SNAPSHOT_DIR}" -type f -name 'health-*.log' -mtime +"${RETENTION_DAYS}" -delete
find "${LOG_DIR}" -type f -name '*.log.*' -mtime +"${RETENTION_DAYS}" -delete || true

chmod 0640 "${SNAPSHOT_FILE}"
log "Wrote maintenance snapshot to ${SNAPSHOT_FILE}"
