#!/usr/bin/env bash
set -Eeuo pipefail

APP_NAME="infra-demo"
APP_USER="infraadmin"
APP_PORT="${APP_PORT:-8080}"
APP_DIR="/opt/${APP_NAME}"
LOG_DIR="/var/log/${APP_NAME}"
ENV_FILE="/etc/${APP_NAME}.env"
SERVICE_FILE="/etc/systemd/system/${APP_NAME}.service"
TIMER_NAME="infra-maintenance.timer"

PASS_COUNT=0
FAIL_COUNT=0

pass() { echo "✓ $*"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { echo "✗ $*"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
section() { echo; echo "================================="; echo "$*"; echo "================================="; }
check_cmd() { local description="$1"; shift; if "$@" >/dev/null 2>&1; then pass "${description}"; else fail "${description}"; fi; }

section "Infrastructure Validation"
echo "Host: $(hostname)"
echo "Time: $(date -Iseconds)"
echo "Uptime: $(uptime -p 2>/dev/null || uptime)"

section "User and directories"
check_cmd "Operational user ${APP_USER} exists" id "${APP_USER}"
check_cmd "Application directory exists" test -d "${APP_DIR}"
check_cmd "Log directory exists" test -d "${LOG_DIR}"
check_cmd "Environment file exists" test -f "${ENV_FILE}"
check_cmd "Systemd service file exists" test -f "${SERVICE_FILE}"

section "Permissions"
if [[ -f "${ENV_FILE}" ]]; then
    ENV_STAT="$(stat -c '%U %G %a %n' "${ENV_FILE}")"
    echo "ENV: ${ENV_STAT}"
    ENV_MODE="$(stat -c '%a' "${ENV_FILE}")"
    if [[ "${ENV_MODE}" == "640" || "${ENV_MODE}" == "600" ]]; then
        pass "Environment file permissions are restricted"
    else
        fail "Environment file permissions are too open"
    fi
else
    fail "Environment file missing, cannot inspect permissions"
fi

[[ -d "${APP_DIR}" ]] && echo "APP_DIR: $(stat -c '%U %G %a %n' "${APP_DIR}")"
[[ -d "${LOG_DIR}" ]] && echo "LOG_DIR: $(stat -c '%U %G %a %n' "${LOG_DIR}")"

section "Service state"
check_cmd "Service is enabled" systemctl is-enabled "${APP_NAME}"
check_cmd "Service is active" systemctl is-active "${APP_NAME}"
check_cmd "Maintenance timer is enabled" systemctl is-enabled "${TIMER_NAME}"
check_cmd "Maintenance timer is active" systemctl is-active "${TIMER_NAME}"

section "HTTP health"
HTTP_BODY="$(curl -fsS "http://127.0.0.1:${APP_PORT}/health" 2>/dev/null || true)"
if [[ -n "${HTTP_BODY}" ]]; then
    echo "${HTTP_BODY}"
    if echo "${HTTP_BODY}" | grep -q '"status"[[:space:]]*:[[:space:]]*"ok"'; then
        pass "Health endpoint returned expected JSON"
    else
        fail "Health endpoint reachable but response content unexpected"
    fi
else
    fail "Health endpoint not reachable on port ${APP_PORT}"
fi

section "Ports and firewall"
if ss -tulpn 2>/dev/null | grep -q ":${APP_PORT}\b"; then
    pass "Expected application port ${APP_PORT} is listening"
    ss -tulpn | grep ":${APP_PORT}\b" || true
else
    fail "Expected application port ${APP_PORT} is not listening"
fi

if command -v ufw >/dev/null 2>&1; then
    echo
    echo "UFW status:"
    ufw status verbose || true
    if ufw status | grep -q "Status: active"; then
        pass "UFW firewall is active"
    else
        fail "UFW firewall is not active"
    fi
elif command -v firewall-cmd >/dev/null 2>&1; then
    echo
    echo "firewalld status:"
    firewall-cmd --state || true
    firewall-cmd --list-all || true
    if firewall-cmd --state 2>/dev/null | grep -q "running"; then
        pass "firewalld is active"
    else
        fail "firewalld is not active"
    fi
else
    fail "No supported firewall tool found for validation"
fi

section "Recent logs"
if journalctl -u "${APP_NAME}" --no-pager -n 20 >/dev/null 2>&1; then
    pass "Recent service logs are readable"
    journalctl -u "${APP_NAME}" --no-pager -n 20 || true
else
    fail "Unable to read recent service logs"
fi

section "Timer details"
systemctl list-timers --all | grep -E 'infra-maintenance|NEXT|LEFT' || true

section "Result"
echo "Passed: ${PASS_COUNT}"
echo "Failed: ${FAIL_COUNT}"

if [[ "${FAIL_COUNT}" -gt 0 ]]; then
    exit 1
fi

echo "Validation complete."
