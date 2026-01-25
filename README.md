# Ikigai (生き甲斐) — Cross-distro Linux Hardening

Ikigai (生き甲斐) is a Japanese concept meaning “a reason for being” or “that which gives life purpose.”
In Japanese culture, ikigai represents the balance between usefulness, sustainability, and personal meaning.

This project adopts that philosophy and applies it to Linux system security.

A hardened system should not be paranoid, fragile, or over-engineered.
It should have clear purpose, measured protection, and long-term maintainability.

That is the idea behind Ikigai.

---

## Why the name Ikigai?

The kanji 生き甲斐 can be read both philosophically and symbolically:

 *  生 (**iki**): Means "life" or "to live," derived from the verb ikiru (生きる).

 *  甲 (**kai**): Translates to "armor," "shell," "first class," or "grade," symbolizing strength or protection.

 *  斐 (**hai**): Means "ornate," "beautiful," or "patterned," often associated with elegance or value.

Together, Ikigai expresses the idea that security is not about locking everything down blindly, but about protecting what matters, in a way that supports the system’s purpose.

This script is not a “maximum lockdown” tool.
It is a baseline of intentional security.

---

## What this repository contains

This repository provides Ikigai.sh, a cross-distribution Linux hardening script that establishes a conservative and safe security baseline.

The script is designed to be:

 * Simple — one script, readable, auditable

 * Predictable — no hidden behavior, no magic

 * Reversible — changes are standard and documented

 * Cross-distro — works across major Linux families

It is intended as a starting point, not a final state.

This repository contains:

* `Ikigai.sh` — a cross-distro Linux hardening script that installs and configures a conservative baseline of protections (UFW firewall, Fail2Ban, kernel hardening). The script is intended as a starting point for system hardening and **should be reviewed before use**.

* `Ikigai_uninstall.sh` — reverses changes made by Ikigai.sh, removing installed packages, configuration files, and restoring firewall defaults.



> ⚠️ **Important safety note:** This scripts modifies firewall rules, system configuration files under `/etc`, and enables or disable system services. Test them locally or on a non-production host first and ensure you have an alternate access method (local console / VM console) in case networking changes lock you out.

---

## What the scripts does:

### Installer — `Ikigai.sh`

The script performs the following actions (idempotent where possible):

* Detects the Linux distribution via `/etc/os-release` and uses the appropriate package manager.
  
### Installs a minimal set of security packages:

  * **ufw** — firewall management

  * **fail2ban** — brute-force protection

  * **net-tools** — inspection and diagnostics
    
### Configures UFW with a conservative policy:

  * Default deny incoming traffic

  * Default allow outgoing traffic

  * Rate-limited SSH (port 22)

  * Allows HTTP (80) and HTTPS (443)

  * Enables UFW rules immediately

> ℹ️ **Note:** On some distros (Ubuntu/Debian), `systemctl status ufw` may show `inactive (dead)`. This is normal: the firewall rules are active and persist across reboots. Use `sudo ufw status verbose` to verify the firewall status.

### Kernel hardening
    
* Writes a persistent kernel hardening file under `/etc/sysctl.d/99-hardening.conf` and applies the settings via `sysctl --system`.
* Installs and enables Fail2Ban; writes `/etc/fail2ban/jail.local` with a sane default SSH jail.
* Prints firewall status, Fail2Ban status, and listening ports at completion


### Fail2Ban

* Writes `/etc/fail2ban/jail.local` with a sane default SSH jail
* Enables and starts the service
* Protects against brute-force login attempts


### Summary

At the end, the script prints:

* UFW status
* Fail2Ban status
* Open/listening ports

---

### Uninstaller — `Ikigai_uninstall.sh`

The uninstall script is the documented, supported way to undo the changes `Ikigai` applies. It performs the following:

### Stop and disable services:

* systemctl stop/disable for UFW and Fail2Ban (idempotent).

* Reset the firewall to defaults:

* Run ufw --force reset which backs up previous rules and clears UFW rules.

### Remove Ikigai-installed packages:

* Removes ufw, fail2ban, and net-tools (and uses apt autoremove or distro equivalent to cleanup dependencies).

* Remove Ikigai configuration files:

* Remove /etc/sysctl.d/99-hardening.conf, /etc/fail2ban/jail.local, and other Ikigai-created files.

* Reload system configuration:

* Run sysctl --system to reapply remaining system sysctl files.

### Summary output:

* Print a concise summary confirming packages removed, firewall reset, and kernel settings reverted.

> ⚠️ **Important** The uninstall script does not remove unrelated system configuration, user data, or non-Ikigai sysctl files. The scripts are intended to be safe for testing — but you should always back up critical configuration and retain console access before running them on production hosts.



---

## Design philosophy

* Security should be intentional, not accidental

* Automation should be readable, not opaque

* Defaults should be safe, not surprising

* One firewall at a time — mixing firewall frameworks causes instability

UFW is intentionally chosen here because it provides a clean abstraction over iptables/nftables while remaining understandable to most users.

**Do not run multiple firewall managers concurrently**  
(e.g., UFW alongside raw iptables or nftables rules). Conflicts may occur.

---

## Installing Ikigai

Make the script executable and run it as root:

```bash
sudo chmod +x Ikigai.sh && sudo ./Ikigai.sh
```

During execution the script will print progress and notes. At the end it will output firewall and Fail2Ban status and a list of open ports.

---

## Uninstalling Ikigai

Ikigai provides a dedicated uninstall script that cleanly reverts all changes
made by the installer.

The uninstall process:

* Stops and disables Fail2Ban
* Resets UFW firewall rules to defaults
* Removes Ikigai-installed packages:
  * ufw
  * fail2ban
  * net-tools
* Removes Ikigai-specific configuration files
* Reloads sysctl configuration

To uninstall:

```bash

sudo chmod +x Ikigai_uninstall.sh && sudo ./Ikigai_uninstall.sh

```
The uninstall script does not:

* Remove unrelated system configuration

* Modify user data

* Alter non-Ikigai sysctl settings

This ensures Ikigai remains safe to test, evaluate, and remove.


---

## Safety checklist (read before running)

**Backup current configs and rules** before running on production:

```bash
sudo cp /etc/ufw/user.rules ~/user.rules.backup || true
sudo cp /etc/fail2ban/jail.local ~/jail.local.backup || true
```
---

## Known benign warnings

### Fail2Ban install warnings on Ubuntu 24.04+

On Ubuntu 24.04 and newer, you may see warnings similar to the following during Fail2Ban installation:

SyntaxWarning: invalid escape sequence '\S'
SyntaxWarning: invalid escape sequence '\s'


These warnings originate from Fail2Ban’s **internal test files**, not from
Ikigai configuration or active runtime code.

Important notes:

* These warnings are **upstream Fail2Ban issues**
* They appear due to **stricter Python 3.12+ syntax checks**
* They **do not affect Fail2Ban functionality**
* They **do not weaken security**
* They can be safely ignored

Fail2Ban will still start correctly, enforce SSH protection, and integrate
with UFW/nftables as expected.

Ikigai does not suppress these warnings to avoid hiding legitimate errors.


---

## What Ikigai is not

* It is not a compliance framework

* It is not a replacement for proper threat modeling

* It is not a full MAC (SELinux/AppArmor) policy system

* It is not meant to hide complexity from the user

Ikigai provides a purposeful, auditable baseline for Linux hardening. It is designed to be safe to apply and fully reversible, but it does not replace comprehensive security planning or guarantee total protection.

---

# Disclaimer / No Warranty / Limitation of Liability

**Important — read before using this software.**

This project, *Ikigai*, and all accompanying code, documentation, and data are provided **"AS IS"** and **WITHOUT WARRANTIES** of any kind, either express or implied. To the fullest extent permitted by applicable law, the author(s) DISCLAIM all warranties, including, without limitation, implied warranties of merchantability, fitness for a particular purpose, accuracy, and non-infringement.

**Limitation of liability:** In no event shall the author(s), contributors, or copyright holders be liable for any direct, indirect, incidental, special, consequential, punitive, or other damages, loss of profits, loss of data, or other losses arising out of or in any way connected with the use of or inability to use this project, whether in contract, tort (including negligence), strict liability, or otherwise, even if advised of the possibility of such damages.


---

## License

Use freely; no warranty. Always test in your environment before deploying widely.
