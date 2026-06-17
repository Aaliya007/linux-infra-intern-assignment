# Hardening Checklist

## Applied controls

- Package metadata refresh and package installation are handled by the provisioning script before service deployment.
- A dedicated non-root operational user named `infraadmin` is created for routine administration.
- The demo application runs as `infraadmin`, not as `root`.
- The systemd service uses `NoNewPrivileges=true`, `PrivateTmp=true`, `ProtectSystem=full`, and `ProtectHome=true`.
- Runtime configuration is kept in `/etc/infra-demo.env` with restricted permissions.
- The application writes logs into `/var/log/infra-demo`, a controlled log directory.
- Firewall rules allow only SSH and the application port.
- Root SSH login is disabled through an `sshd_config.d` drop-in.
- `MaxAuthTries` is reduced and `X11Forwarding` is disabled.
- Unused Apache/httpd services are disabled when present.

## Ownership and permissions

- `/opt/infra-demo`, `/var/log/infra-demo`, and `/var/lib/infra-demo` are owned by `infraadmin:infraadmin`.
- `/etc/infra-demo.env` is owned by `root:infraadmin` with mode `0640`.
- Repository systemd unit files are readable and intended for installation into `/etc/systemd/system/`.

## Intentionally not applied

- SSH password authentication is not disabled by default in this project to avoid accidental lockout in local VM test environments.
- SELinux policy customization is not included because the assignment targets multiple distros and must remain reproducible for beginners.
- Fail2ban is not installed to keep the baseline small and focused on the assignment core.
- Automatic unattended upgrades are not enforced because the assignment emphasizes explicit provisioning and validation steps.
- The application is not exposed behind nginx or a reverse proxy because a simple Python HTTP health service is explicitly allowed.

## Manual reviewer verification

Run the following after provisioning:

```bash
sudo systemctl cat infra-demo
sudo stat -c "%U %G %a %n" /etc/infra-demo.env
sudo ss -tulpn | grep 8080
sudo ufw status verbose
sudo journalctl -u infra-demo --no-pager -n 20
```

## Safety notes

- All hardening choices were scoped to a local VM assignment environment.
- SSH changes were applied conservatively and validated with `sshd -t` before restart.
- No destructive disk, partition, or host-level commands are used.
