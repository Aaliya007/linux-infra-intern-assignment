#!/usr/bin/env bash
set -Eeuo pipefail

APP_NAME="infra-demo"
APP_USER="infraadmin"
APP_GROUP="infraadmin"
APP_DIR="/opt/${APP_NAME}"
APP_LOG_DIR="/var/log/${APP_NAME}"
APP_RUN_DIR="/var/lib/${APP_NAME}"
APP_PORT="${APP_PORT:-8080}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="${REPO_ROOT}/config"
SYSTEMD_DIR="${REPO_ROOT}/systemd"
SCRIPTS_DIR="${REPO_ROOT}/scripts"

ENV_FILE_SRC="${CONFIG_DIR}/${APP_NAME}.env"
SERVICE_FILE_SRC="${SYSTEMD_DIR}/${APP_NAME}.service"
MAINT_SERVICE_SRC="${SYSTEMD_DIR}/infra-maintenance.service"
MAINT_TIMER_SRC="${SYSTEMD_DIR}/infra-maintenance.timer"

SERVICE_FILE_DEST="/etc/systemd/system/${APP_NAME}.service"
MAINT_SERVICE_DEST="/etc/systemd/system/infra-maintenance.service"
MAINT_TIMER_DEST="/etc/systemd/system/infra-maintenance.timer"
ENV_FILE_DEST="/etc/${APP_NAME}.env"

OS_ID=""
OS_VERSION_ID=""
PKG_INSTALL=""
PKG_UPDATE=""
SUDO_GROUP="sudo"
FIREWALL_BACKEND="none"

log() { echo "[INFO] $*"; }
warn() { echo "[WARN] $*" >&2; }
fail() { echo "[ERROR] $*" >&2; exit 1; }

require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        fail "Please run this script as root or with sudo."
    fi
}

detect_os() {
    log "Detecting operating system..."
    if [[ -r /etc/os-release ]]; then
        . /etc/os-release
        OS_ID="${ID:-unknown}"
        OS_VERSION_ID="${VERSION_ID:-unknown}"
        log "Detected OS: ${PRETTY_NAME:-$OS_ID}"
    else
        fail "Unable to detect operating system from /etc/os-release."
    fi

    case "${OS_ID}" in
        ubuntu|debian)
            PKG_UPDATE="apt-get update -y"
            PKG_INSTALL="apt-get install -y"
            SUDO_GROUP="sudo"
            FIREWALL_BACKEND="ufw"
            ;;
        rocky|rhel|almalinux|centos|fedora)
            if command -v dnf >/dev/null 2>&1; then
                PKG_UPDATE="dnf makecache -y"
                PKG_INSTALL="dnf install -y"
            else
                PKG_UPDATE="yum makecache -y"
                PKG_INSTALL="yum install -y"
            fi
            SUDO_GROUP="wheel"
            FIREWALL_BACKEND="firewalld"
            ;;
        *)
            fail "Unsupported distribution: ${OS_ID}."
            ;;
    esac
}

run_pkg_update() {
    log "Updating package metadata..."
    eval "${PKG_UPDATE}"
}

install_packages() {
    log "Installing required packages..."
    case "${OS_ID}" in
        ubuntu|debian)
            eval "${PKG_INSTALL} curl git ufw python3 python3-venv python3-pip openssh-server"
            ;;
        rocky|rhel|almalinux|centos|fedora)
            eval "${PKG_INSTALL} curl git firewalld python3 python3-pip openssh-server"
            ;;
    esac
}

ensure_user() {
    log "Ensuring operational user ${APP_USER} exists..."
    if id "${APP_USER}" >/dev/null 2>&1; then
        log "User ${APP_USER} already exists."
    else
        useradd -m -s /bin/bash "${APP_USER}"
        log "Created user ${APP_USER}."
    fi

    if getent group "${SUDO_GROUP}" >/dev/null 2>&1; then
        usermod -aG "${SUDO_GROUP}" "${APP_USER}"
    fi
}

ensure_directories() {
    log "Ensuring required directories..."
    mkdir -p "${APP_DIR}" "${APP_LOG_DIR}" "${APP_RUN_DIR}" "${CONFIG_DIR}" "${SYSTEMD_DIR}" "${SCRIPTS_DIR}"
    chown -R "${APP_USER}:${APP_GROUP}" "${APP_DIR}" "${APP_LOG_DIR}" "${APP_RUN_DIR}"
    chmod 0755 "${APP_DIR}" "${APP_LOG_DIR}" "${APP_RUN_DIR}"
}

deploy_app() {
    log "Deploying Python application..."
    [[ -f "${REPO_ROOT}/app.py" ]] || fail "Expected app.py at repository root."
    install -o "${APP_USER}" -g "${APP_GROUP}" -m 0755 "${REPO_ROOT}/app.py" "${APP_DIR}/app.py"
}

write_env_file() {
    log "Writing environment file..."
    cat > "${ENV_FILE_DEST}" <<EOF
PORT=${APP_PORT}
HOST=0.0.0.0
LOG_DIR=${APP_LOG_DIR}
PYTHONUNBUFFERED=1
EOF
    chown root:"${APP_GROUP}" "${ENV_FILE_DEST}"
    chmod 0640 "${ENV_FILE_DEST}"
    cp "${ENV_FILE_DEST}" "${ENV_FILE_SRC}"
    chmod 0640 "${ENV_FILE_SRC}" || true
}

write_systemd_units() {
    log "Writing systemd unit files..."
    cat > "${SERVICE_FILE_DEST}" <<EOF
[Unit]
Description=Infra Demo Python Health Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=${APP_USER}
Group=${APP_GROUP}
EnvironmentFile=${ENV_FILE_DEST}
WorkingDirectory=${APP_DIR}
ExecStart=/usr/bin/python3 ${APP_DIR}/app.py
Restart=on-failure
RestartSec=3
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=full
ProtectHome=true
ReadWritePaths=${APP_LOG_DIR} ${APP_RUN_DIR}
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    cat > "${MAINT_SERVICE_DEST}" <<EOF
[Unit]
Description=Infra Demo Maintenance Task

[Service]
Type=oneshot
User=root
Group=root
ExecStart=/usr/bin/env bash ${APP_DIR}/maintenance.sh
EOF

    cat > "${MAINT_TIMER_DEST}" <<EOF
[Unit]
Description=Run Infra Demo Maintenance Periodically

[Timer]
OnBootSec=2min
OnUnitActiveSec=15min
Persistent=true
Unit=infra-maintenance.service

[Install]
WantedBy=timers.target
EOF

    cp "${SERVICE_FILE_DEST}" "${SERVICE_FILE_SRC}"
    cp "${MAINT_SERVICE_DEST}" "${MAINT_SERVICE_SRC}"
    cp "${MAINT_TIMER_DEST}" "${MAINT_TIMER_SRC}"
    chmod 0644 "${SERVICE_FILE_DEST}" "${MAINT_SERVICE_DEST}" "${MAINT_TIMER_DEST}"
}

deploy_maintenance_script() {
    log "Deploying maintenance script..."
    [[ -f "${SCRIPTS_DIR}/maintenance.sh" ]] || fail "Expected scripts/maintenance.sh in repository."
    install -o root -g root -m 0755 "${SCRIPTS_DIR}/maintenance.sh" "${APP_DIR}/maintenance.sh"
}

configure_ssh_hardening() {
    log "Applying conservative SSH hardening..."
    local sshd_dropin_dir="/etc/ssh/sshd_config.d"
    local sshd_dropin_file="${sshd_dropin_dir}/99-${APP_NAME}-hardening.conf"
    mkdir -p "${sshd_dropin_dir}"

    cat > "${sshd_dropin_file}" <<'EOF'
PasswordAuthentication yes
PermitRootLogin no
MaxAuthTries 3
X11Forwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
EOF

    chmod 0644 "${sshd_dropin_file}"

    local ssh_service=""
    if systemctl list-unit-files | grep -q '^ssh\.service'; then
        ssh_service="ssh"
    elif systemctl list-unit-files | grep -q '^sshd\.service'; then
        ssh_service="sshd"
    else
        warn "SSH service unit not found; skipping SSH restart."
        return
    fi

    if sshd -t; then
        systemctl restart "${ssh_service}" || warn "SSH restart failed; verify manually."
        systemctl enable "${ssh_service}" || warn "Could not enable SSH service."
    else
        fail "sshd configuration test failed."
    fi
}

configure_firewall() {
    log "Configuring firewall..."
    case "${FIREWALL_BACKEND}" in
        ufw)
            ufw --force default deny incoming
            ufw --force default allow outgoing
            ufw allow OpenSSH
            ufw allow "${APP_PORT}/tcp"
            ufw --force enable
            ;;
        firewalld)
            systemctl enable --now firewalld
            firewall-cmd --permanent --add-service=ssh
            firewall-cmd --permanent --add-port="${APP_PORT}/tcp"
            firewall-cmd --reload
            ;;
        *)
            warn "No supported firewall backend selected; skipping firewall configuration."
            ;;
    esac
}

disable_unused_services() {
    log "Disabling unused web services if present..."
    for svc in apache2 httpd; do
        if systemctl list-unit-files | grep -q "^${svc}\\.service"; then
            systemctl disable --now "${svc}" || warn "Could not disable ${svc}."
        fi
    done
}

enable_services() {
    log "Reloading systemd and enabling services..."
    systemctl daemon-reload
    systemctl enable --now "${APP_NAME}.service"
    systemctl enable --now infra-maintenance.timer
}

verify() {
    log "Running quick verification..."
    systemctl is-enabled "${APP_NAME}.service" >/dev/null && log "Service enabled."
    systemctl is-active "${APP_NAME}.service" >/dev/null && log "Service active."
    systemctl is-enabled infra-maintenance.timer >/dev/null && log "Maintenance timer enabled."
    systemctl is-active infra-maintenance.timer >/dev/null && log "Maintenance timer active."
    id "${APP_USER}" >/dev/null && log "Operational user exists."
    [[ -f "${ENV_FILE_DEST}" ]] && log "Environment file present."
    [[ -f "${SERVICE_FILE_DEST}" ]] && log "Service unit present."

    if curl -fsS "http://127.0.0.1:${APP_PORT}/health" >/dev/null; then
        log "Health endpoint reachable."
    else
        fail "Health endpoint check failed after provisioning."
    fi
}

main() {
    log "================================="
    log "Linux Infra Provisioning Started"
    log "================================="
    require_root
    detect_os
    run_pkg_update
    install_packages
    ensure_user
    ensure_directories
    deploy_app
    write_env_file
    deploy_maintenance_script
    write_systemd_units
    configure_ssh_hardening
    configure_firewall
    disable_unused_services
    enable_services
    verify
    log "================================="
    log "Provisioning completed successfully"
    log "================================="
}

main "$@"
