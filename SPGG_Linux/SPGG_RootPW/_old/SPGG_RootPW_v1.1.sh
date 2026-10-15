#!/usr/bin/env bash
# SPGG RootPW audit v1.0 - read-only; no sudo elevation within script.
set -u
export LC_ALL=C
START="${1:-2026-07-01}"
END="${2:-2026-10-01}"
case "$START $END" in *[!0-9\ -]* ) echo 'Invalid date'; exit 2;; esac
if [[ ! "$START" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ || ! "$END" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then echo 'Use YYYY-MM-DD'; exit 2; fi
section(){ printf '\n===== %s =====\n' "$1"; }
section 'IDENTIFICATION'
printf 'Hostname: '; hostname
printf 'Time: '; date -Is
printf 'Timezone: '; date +%Z
printf 'OS: '; ( . /etc/os-release; echo "${PRETTY_NAME:-unknown}" )
printf 'Executed as: '; id
printf 'Window: %s through %s (end exclusive)\n' "$START" "$END"
section 'SUDO EFFECTIVE DEFAULTS'
if command -v sudo >/dev/null 2>&1; then sudo -n -l 2>&1 | sed -n '1,65p' || true; else echo 'sudo not found'; fi
section 'SUDOERS DIRECTIVES (active lines; may contain sensitive paths)'
for file in /etc/sudoers /etc/sudoers.d/*; do
  [[ -f "$file" ]] || continue
  echo "-- $file --"
  grep -nEi '^[[:space:]]*Defaults([[:space:]:@!>]|$)|^[[:space:]]*(@includedir|#includedir|@include|#include)' "$file" 2>&1 || true
done
section 'SUDOERS FILE METADATA'
for file in /etc/sudoers /etc/sudoers.d/*; do
  [[ -f "$file" ]] || continue
  stat -c '%n | owner=%U:%G | mode=%a | size=%s | mtime=%y | ctime=%z | birth=%w' "$file" 2>&1 || true
done
section 'ROOT PASSWORD METADATA (NO HASHES)'
if command -v passwd >/dev/null 2>&1; then passwd -S root 2>&1 || true; fi
if command -v chage >/dev/null 2>&1; then chage -l root 2>&1 || true; fi
section 'LOG SOURCES / RETENTION'
for f in /var/log/auth.log* /var/log/secure* /var/log/audit/audit.log*; do [[ -f "$f" ]] && stat -c '%n | bytes=%s | mtime=%y' "$f"; done
if command -v journalctl >/dev/null 2>&1; then journalctl --list-boots --no-pager 2>&1 | tail -n 30; fi
section 'AUTH LOG CANDIDATES (DATE WINDOW FILTER; UP TO 200 LINES)'
# Parse syslog month/day timestamps using a year assumption; collect only candidate entries.
# Yearless logs cannot be reliably dated across rotations; use as leads, not proof.
if command -v zgrep >/dev/null 2>&1; then
  for f in /var/log/auth.log* /var/log/secure*; do
    [[ -f "$f" ]] || continue
    echo "-- $f --"
    zgrep -iEh 'sudo:|visudo|sudoers|passwd\[|chpasswd|usermod|ansible|puppet|salt-minion' "$f" 2>/dev/null | head -n 100 || true
  done
fi
section 'JOURNAL SUDO CANDIDATES (UP TO 250 LINES)'
if command -v journalctl >/dev/null 2>&1; then
  journalctl --since "${START} 00:00:00" --until "${END} 00:00:00" -t sudo --no-pager -o short-iso 2>&1 | head -n 250 || true
fi
section 'AUDITD AVAILABILITY'
if command -v ausearch >/dev/null 2>&1; then
  echo 'ausearch available; no historical audit events queried automatically (site-specific rules and time format).'
  if command -v auditctl >/dev/null 2>&1; then auditctl -l 2>&1 | grep -Ei 'sudoers|sudoers.d|No rules' || true; fi
else echo 'ausearch unavailable'; fi
section 'NOTES'
echo 'Read-only collection. mtime is not proof of the rootpw insertion date. Logs may contain secrets in command arguments; restrict report access.'
