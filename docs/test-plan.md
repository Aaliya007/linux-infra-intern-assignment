# Test Plan

## Objective

Verify that the provisioning workflow produces a deployment-ready local VM baseline and that the service survives reboot.

## Test cases

### 1. Fresh VM provisioning
- Start from a clean local VM.
- Clone the repository.
- Run `sudo ./scripts/provision.sh`.
- Expected result: packages install, user is created, service is enabled and active, maintenance timer is enabled, and health endpoint responds.

### 2. Health endpoint
- Run `curl -i http://127.0.0.1:8080/health`.
- Expected result: HTTP 200 and JSON body containing `"status": "ok"`.

### 3. Service validation
- Run `sudo ./scripts/validate.sh`.
- Expected result: all checks pass with `Failed: 0`.

### 4. Idempotency
- Run `sudo ./scripts/provision.sh` a second time.
- Expected result: the script completes successfully without duplicate users or broken configuration.

### 5. Firewall verification
- Run `sudo ufw status verbose` on Debian/Ubuntu or `sudo firewall-cmd --list-all` on Rocky-family systems.
- Expected result: only expected ports are open, including SSH and the demo service port.

### 6. Reboot survival
- Reboot the VM.
- Run `sudo ./scripts/validate.sh` again.
- Expected result: the service is automatically running after boot and all checks still pass.

### 7. Maintenance timer
- Run `systemctl list-timers --all | grep infra-maintenance`.
- Expected result: timer is enabled and next run is scheduled.

## Evidence to capture

- OS version and hostname.
- First successful provisioning run.
- `systemctl status infra-demo`.
- `curl -i http://127.0.0.1:8080/health`.
- Firewall status.
- `systemctl status infra-maintenance.timer`.
- Second provisioning run.
- Validation output before reboot.
- Validation output after reboot.
