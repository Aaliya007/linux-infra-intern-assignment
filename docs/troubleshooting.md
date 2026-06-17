# Troubleshooting

## Service does not start

Check the unit status and logs:

```bash
sudo systemctl status infra-demo
sudo journalctl -u infra-demo --no-pager -n 50
```

Common causes:
- `app.py` was not copied into `/opt/infra-demo`.
- `/etc/infra-demo.env` is missing or malformed.
- Port `8080` is already in use.

## Health endpoint fails

Run:

```bash
curl -i http://127.0.0.1:8080/health
sudo ss -tulpn | grep 8080
```

If the port is not listening, restart the service:

```bash
sudo systemctl restart infra-demo
```

## Firewall blocks access

Debian/Ubuntu:

```bash
sudo ufw status verbose
sudo ufw allow 8080/tcp
```

Rocky-family:

```bash
sudo firewall-cmd --list-all
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
```

## SSH restart warning during provisioning

The provisioning script validates the SSH configuration before restart, but if your local VM uses unusual SSH packaging, verify manually:

```bash
sudo sshd -t
sudo systemctl status ssh || sudo systemctl status sshd
```

## Timer did not run yet

Check timer state:

```bash
systemctl status infra-maintenance.timer
systemctl list-timers --all | grep infra-maintenance
```

Run the maintenance service manually:

```bash
sudo systemctl start infra-maintenance.service
sudo ls -l /var/log/infra-demo/health-snapshots
```
