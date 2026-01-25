#!/bin/bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root"
  exit 1
fi

echo "[+] Starting Ikigai uninstall..."

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
remove_pkgs() {
  case "$DISTRO_ID" in
    ubuntu|debian)
      apt remove --purge -y "$@"
      apt autoremove -y
      ;;
    arch)
      pacman -Rns --noconfirm "$@"
      ;;
    fedora|rocky|almalinux|rhel)
      dnf remove -y "$@"
      ;;
    opensuse*|sles)
      zypper remove -y "$@"
      ;;
    *)
      echo "Unsupported distro: $DISTRO_ID"
      exit 1
      ;;
  esac
}

#-----------------------
# Stop services
#-----------------------
echo "[+] Stopping services..."
systemctl stop ufw.service || true
systemctl disable ufw.service || true
systemctl stop fail2ban.service || true
systemctl disable fail2ban.service || true

#-----------------------
# Reset firewall
#-----------------------
echo "[+] Resetting UFW to defaults..."
ufw --force reset || true

#-----------------------
# Remove packages
#-----------------------
echo "[+] Removing installed packages..."
remove_pkgs ufw fail2ban net-tools

#-----------------------
# Remove config files
#-----------------------
echo "[+] Removing configuration files..."
rm -f /etc/sysctl.d/99-hardening.conf
rm -f /etc/fail2ban/jail.local


#-----------------------
# Reload sysctl
#-----------------------
echo "[+] Reloading sysctl configuration"
sysctl --system || true



#-----------------------
# Summary
#-----------------------
echo
echo "===== Uninstall Summary ====="

echo
echo "• Ikigai-installed packages removed"

echo
echo "• UFW rules reset to defaults"

echo
echo "• Ikigai kernel hardening reverted"

echo
echo "Uninstall completed."