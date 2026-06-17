# Linux Infrastructure Intern Assignment

A local-VM Linux provisioning project that prepares a fresh server for internal deployment practice using Bash automation, systemd, a Python health service, basic hardening, periodic maintenance, and validation before and after reboot.

## Project overview

This project converts a clean local Linux VM into a reproducible deployment-ready baseline. It installs required packages, creates a non-root operational user, deploys a lightweight Python HTTP health service managed by systemd, applies safe hardening defaults, configures a maintenance timer, and provides a validation script that checks the environment after provisioning and reboot.

## Supported operating systems

- Ubuntu Server 22.04 LTS / 24.04 LTS
- Debian 12
- Rocky Linux family distributions with `dnf` or `yum`

## Repository structure

```text
linux-infra-intern-assignment/
├── README.md
├── app.py
├── scripts/
│   ├── provision.sh
│   ├── validate.sh
│   └── maintenance.sh
├── systemd/
│   ├── infra-demo.service
│   ├── infra-maintenance.service
│   └── infra-maintenance.timer
├── config/
│   └── infra-demo.env
├── docs/
│   ├── hardening-checklist.md
│   ├── local-vm-reprovisioning.md
│   ├── test-plan.md
│   └── troubleshooting.md
└── evidence/
    ├── milestone-1-setup.png
    ├── milestone-2-service.png
    ├── milestone-3-hardening.png
    └── final-reboot-validation.png
```

## Architecture

- **Provisioning:** `scripts/provision.sh`
- **Demo service:** `app.py` served by systemd as `infra-demo.service`
- **Runtime config:** `/etc/infra-demo.env` sourced from `config/infra-demo.env`
- **Logs:** `journalctl -u infra-demo` and `/var/log/infra-demo/app.log`
- **Maintenance automation:** `infra-maintenance.service` and `infra-maintenance.timer`
- **Validation:** `scripts/validate.sh`

## Setup instructions

### 1. Clone the repository inside a local VM

```bash
git clone https://github.com/Aaliya007/linux-infra-intern-assignment.git
cd linux-infra-intern-assignment
```

### 2. Make scripts executable

```bash
chmod +x scripts/*.sh
```

### 3. Run provisioning

```bash
sudo ./scripts/provision.sh
```

### 4. Validate the deployment

```bash
sudo ./scripts/validate.sh
```

### 5. Reboot and validate again

```bash
sudo reboot
```

After reboot:

```bash
cd linux-infra-intern-assignment
sudo ./scripts/validate.sh
```

## Commands for demonstration

```bash
systemctl status infra-demo --no-pager
systemctl status infra-maintenance.timer --no-pager
curl -i http://127.0.0.1:8080/health
journalctl -u infra-demo --no-pager -n 30
ss -tulpn | grep 8080
```

## Functional requirement mapping

- **FR1:** OS detection, package installation, operational user creation, and documented local setup.
- **FR2:** Python-based HTTP health service managed by systemd and enabled on boot.
- **FR3:** Environment-file-driven runtime config with journal and file-based logging.
- **FR4:** Idempotent provisioning flow that can be run twice safely.
- **FR5:** SSH hardening, firewall setup, restricted permissions, and disabling unused services where safe.
- **FR6:** Local VM reprovisioning workflow documented in `docs/local-vm-reprovisioning.md`.
- **FR7:** Validation script checks service state, health response, firewall, ports, permissions, users, and logs.
- **FR8:** Reboot validation is part of the test plan and demo steps.

## Assumptions

- The project runs only inside a local VM.
- The user has console or sudo access in the VM.
- Port `8080` is available.
- SSH is installed or installable from the distro package repositories.

## Evidence checklist

Populate the `evidence/` directory with the following:

- `milestone-1-setup.png`: OS version, repo structure, first provisioning success.
- `milestone-2-service.png`: `systemctl status infra-demo`, `curl /health`, and recent logs.
- `milestone-3-hardening.png`: firewall status, timer status, permissions, and second provisioning run.
- `final-reboot-validation.png`: output of `validate.sh` after reboot.

## AI Assistance Notes

AI assistance was used for:
- brainstorming repository structure and checklist coverage,
- refining Bash script organization,
- improving documentation wording,
- reviewing systemd hardening directives.

Manually verified by the candidate:
- every shell command used in provisioning and validation,
- systemd unit behavior,
- firewall commands for the target distro,
- service start and reboot survival behavior inside the local VM,
- validation output and evidence capture.

## Troubleshooting

See `docs/troubleshooting.md` for common failures and recovery steps.
