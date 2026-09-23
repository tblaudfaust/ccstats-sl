#!/usr/bin/env bash
# Run as root on the Hostinger "Debian 12 with FreePBX" VPS after the web wizard is done.
# Usage: bash 01-harden.sh <OFFICE_PUBLIC_IP> [<second admin IP>]
set -euo pipefail
OFFICE_IP="${1:?usage: 01-harden.sh <office-public-ip> [second-ip]}"
SECOND_IP="${2:-}"
KEY_COMMENT="claude-freepbx-hostinger"

echo "== timezone / NTP"
timedatectl set-timezone Africa/Freetown
timedatectl set-ntp true || true

echo "== OS updates"
export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get -y -q upgrade
apt-get install -y -q unattended-upgrades fail2ban rsync git curl jq
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'CFG'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
CFG

echo "== fail2ban site overrides (jails come from FreePBX Sysadmin's jail.local)"
cat > /etc/fail2ban/jail.d/local.conf <<CFG
[DEFAULT]
ignoreip = 127.0.0.1/8 ${OFFICE_IP} ${SECOND_IP}
bantime  = 24h
findtime = 10m
CFG
systemctl enable --now fail2ban
systemctl restart fail2ban

echo "== SSH: key-only login (only if our key is present)"
if grep -q "$KEY_COMMENT" /root/.ssh/authorized_keys 2>/dev/null; then
  cat > /etc/ssh/sshd_config.d/90-hardening.conf <<'CFG'
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin prohibit-password
MaxAuthTries 3
X11Forwarding no
CFG
  sshd -t && systemctl reload ssh
  echo "   password SSH disabled"
else
  echo "   WARNING: key not found in /root/.ssh/authorized_keys, leaving password auth on"
fi

echo "== FreePBX firewall: trust office IP only. Do NOT start it from the CLI:"
echo "   starting it headless locked out the trusted IP on 2026-09-23. Enable it from the web UI wizard instead."
fwconsole firewall add trusted "$OFFICE_IP" || true
[ -n "$SECOND_IP" ] && fwconsole firewall add trusted "$SECOND_IP" || true
fwconsole firewall lerules enable || true

echo "== Docker watchdog: FreePBX firewall restarts flush Docker's iptables chains"
cat > /etc/cron.d/docker-iptables-watchdog <<'CFG'
*/2 * * * * root iptables -S DOCKER-FORWARD >/dev/null 2>&1 || systemctl restart docker
CFG

echo "== FreePBX modules up to date"
fwconsole ma updateall || true
fwconsole reload || true

echo "== done. Reboot recommended if a kernel was upgraded: needrestart / reboot"
