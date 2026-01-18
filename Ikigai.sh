#!/bin/bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root"
  exit 1
fi

echo "[+] Starting cross-distro Linux hardening"

#-----------------------
# Detect distro
#-----------------------
if [[ -r /etc/os-release ]]; then
  . /etc/os-release
else
  echo "Cannot detect OS"
  exit 1
fi

DISTRO_ID="${ID,,}"
echo "[+] Detected distro: $DISTRO_ID"

#-----------------------
# Package manager abstraction
#-----------------------
install_pkgs() {
  case "$DISTRO_ID" in
    ubuntu|debian)
      apt update
      apt install -y "$@"
      ;;
    arch)
      pacman -Sy --noconfirm "$@"
      ;;
    fedora|rocky|almalinux|rhel)
      dnf install -y "$@"
      ;;
    opensuse*|sles)
      zypper install -y "$@"
      ;;
    *)
      echo "Unsupported distro: $DISTRO_ID"
      exit 1
      ;;
  esac
}

#-----------------------
# Base security packages
#-----------------------
install_pkgs ufw fail2ban net-tools

#-----------------------
# Firewall ufw
#-----------------------
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw limit 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
systemctl enable --now ufw

#-----------------------
# Kernel hardening
#-----------------------
cat <<EOF >/etc/sysctl.d/99-hardening.conf
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv6.conf.all.accept_redirects=0
net.ipv6.conf.default.accept_redirects=0
EOF

sysctl --system

#-----------------------
# Fail2Ban
#-----------------------
cat <<EOF >/etc/fail2ban/jail.local
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1
bantime  = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
EOF

systemctl enable --now fail2ban

#-----------------------
# Status
#-----------------------
echo "[+] Firewall:"
ufw status verbose

echo "[+] Fail2Ban:"
fail2ban-client status

echo "[+] Open ports:"
netstat -tunlp

echo "[+] Hardening completed"
