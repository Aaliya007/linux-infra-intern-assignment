# Local VM Reprovisioning Guide

## Goal

This document shows how to reproduce the assignment from a clean local VM state without using any cloud provider.

## Recommended workflow

1. Create a fresh local VM using Ubuntu Server 22.04/24.04 LTS, Debian 12, Rocky Linux, or another mainstream Linux distribution.
2. Install Git and clone the repository inside the VM.
3. Take a VM snapshot named `pre-provisioning-clean-state` before running the provisioning script.
4. Run the provisioning flow.
5. Validate the system, reboot the VM, and validate again.
6. Restore the VM snapshot whenever you want to test the full workflow from a clean state.

## Example reprovisioning flow

```bash
git clone https://github.com/Aaliya007/linux-infra-intern-assignment.git
cd linux-infra-intern-assignment
chmod +x scripts/*.sh
sudo ./scripts/provision.sh
sudo ./scripts/validate.sh
sudo reboot
```

After reboot:

```bash
cd linux-infra-intern-assignment
sudo ./scripts/validate.sh
```

## Idempotency test

To demonstrate repeatability, run the provisioning script twice:

```bash
sudo ./scripts/provision.sh
sudo ./scripts/provision.sh
sudo ./scripts/validate.sh
```

Capture the second provisioning run in your evidence folder to show that no destructive duplication occurred.

## Snapshot notes

- VirtualBox: Machine -> Take Snapshot before provisioning.
- VMware Workstation/Player: Use Snapshot Manager or create a linked clone baseline.
- Hyper-V: Use Checkpoints.
- UTM: Create a snapshot from the VM management interface.

All screenshots, logs, and demo video should clearly show a local VM, not a cloud console.
