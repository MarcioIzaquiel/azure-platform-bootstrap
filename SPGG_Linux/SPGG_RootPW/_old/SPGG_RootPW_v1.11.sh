#!/usr/bin/env bash
# SPGG - Auditoria historica rootpw v1.1 | somente leitura dos recursos auditados
# Executar via sudo bash; imprime relatorio em stdout.
set -u
export LC_ALL=C
START="${1:-2026-07-01}"
END="${2:-2026-10-01}"
if [[ ! "$START" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ || ! "$END" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then echo 'ERROR: dates must be YYYY-MM-DD'; exit 2; fi
start_epoch=$(date -d "$START 00:00:00" +%s 2>/dev/null) || { echo 'ERROR: invalid start date'; exit 2; }
end_epoch=$(date -d "$END 00:00:00" +%s 2>/dev/null) || { echo 'ERROR: invalid end date'; exit 2; }
if (( start_epoch >= end_epoch )); then echo 'ERROR: start must precede end'; exit 2; fi
section(){ printf '\n===== %s =====\n' "$1"; }
section 'EXECUTIVE SUMMARY'
printf 'Host: %s\n' "$(hostname)"
printf 'Collected: %s\n' "$(date -Is)"
printf 'Window: %s to %s (end exclusive)\n' "$START" "$END"
if [[ $EUID -ne 0 ]]; then echo 'ERROR: run as root using sudo; no collection performed'; exit 3; fi
if grep -RqsE '^[[:space:]]*Defaults[[:space:]]+rootpw([[:space:],]|$)' /etc/sudoers /etc/sudoers.d 2>/dev/null; then echo 'Global rootpw directive: FOUND (text scan; inspect effective scope below)'; else echo 'Global rootpw directive: not found by simple text scan'; fi
if [[ -f /etc/sudoers ]]; then printf 'sudoers mtime: '; stat -c '%y' /etc/sudoers; fi
printf 'root password status: '; passwd -S root 2>/dev/null || echo 'unavailable'
section 'IDENTIFICATION'
printf 'OS: '; ( . /etc/os-release; echo "${PRETTY_NAME:-unknown}" )
printf 'Timezone: '; date +%Z
printf 'Executed as: '; id
section 'SUDO EFFECTIVE DEFAULTS (FOR ROOT; NOT A SUBSTITUTE FOR PER-USER TESTS)'
if command -v sudo >/dev/null 2>&1; then sudo -n -l 2>&1 | sed -n '1,70p'; else echo 'sudo unavailable'; fi
section 'SUDOERS DIRECTIVES'
for f in /etc/sudoers /etc/sudoers.d/*; do
  [[ -f "$f" ]] || continue
  printf '\n-- %s --\n' "$f"
  grep -nEi '^[[:space:]]*Defaults([[:space:]:@!>]|$)|^[[:space:]]*(@includedir|#includedir|@include|#include)' "$f" || true
done
section 'SUDOERS FILE METADATA'
for f in /etc/sudoers /etc/sudoers.d/*; do
  [[ -f "$f" ]] || continue
  stat -c '%n | owner=%U:%G | mode=%a | size=%s | mtime=%y | ctime=%z | birth=%w' "$f" || true
done
section 'ROOT PASSWORD METADATA (NO HASHES)'
passwd -S root 2>&1 || true
chage -l root 2>&1 || true
section 'LOG SOURCES / RETENTION'
shopt -s nullglob
logs=(/var/log/auth.log /var/log/auth.log.[0-9]* /var/log/secure /var/log/secure.[0-9]*)
for f in "${logs[@]}"; do [[ -f "$f" ]] && stat -c '%n | bytes=%s | mtime=%y' "$f"; done
for f in /var/log/audit/audit.log*; do [[ -f "$f" ]] && stat -c '%n | bytes=%s | mtime=%y' "$f"; done
if command -v journalctl >/dev/null 2>&1; then journalctl --list-boots --no-pager 2>&1 | tail -n 15; fi
section 'AUTH LOG - PRIORITIZED ADMIN EVENTS (UP TO 150 PER FILE)'
echo 'NOTE: classic syslog lacks year. Year inferred from file mtime; near year boundaries may be ambiguous. All matches are leads, not proof.'
echo 'NOTE: exclude repetitive snap_daemon monitoring only from this prioritized section; other sources below remain available.'
# A linha so entra no resultado se a data interpretada estiver na janela solicitada.
# Usa mtime do arquivo como ano-base; para meses posteriores ao mtime, presume ano anterior.
# Isto e uma heuristica, nao evidencia cronologica conclusiva.
for f in "${logs[@]}"; do
  [[ -f "$f" ]] || continue
  printf '\n-- %s --\n' "$f"
  fileyear=$(date -d "@$(stat -c %Y "$f")" +%Y)
  filemonth=$(date -d "@$(stat -c %Y "$f")" +%m)
  if [[ "$f" == *.gz ]]; then reader=(gzip -cd -- "$f"); else reader=(cat -- "$f"); fi
  "${reader[@]}" 2>/dev/null | awk -v sy="$START" -v ey="$END" -v fy="$fileyear" -v fm="$filemonth" '
    BEGIN { split("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec", m, " "); for(i=1;i<=12;i++) month[m[i]]=i; count=0 }
    /^[A-Z][a-z][a-z] +[0-9][0-9]? / {
      mo=month[$1]; day=$2+0; if (!mo || day<1 || day>31) next
      year=fy+0; if (mo>(fm+0)+1) year--
      dt=sprintf("%04d-%02d-%02d",year,mo,day)
      if(dt<sy || dt>=ey) next
      if(tolower($0) ~ /snap_daemon/ && tolower($0) ~ /unified-monitoring-agent/) next
      if(tolower($0) ~ /sudo:|visudo|sudoers|passwd|chpasswd|usermod|ansible|puppet|salt-minion|session opened for user root|session closed for user root/) {
        if(count<150) print "[inferred " dt "] " $0
        count++
      }
    }
    END { printf "MATCHES_IN_WINDOW=%d; DISPLAYED=%d\n", count, count<150?count:150 }
  ' || echo 'Log could not be read'
done
section 'JOURNAL - RELEVANT ADMIN EVENTS (UP TO 250 LINES)'
if command -v journalctl >/dev/null 2>&1; then
  journalctl --since "$START 00:00:00" --until "$END 00:00:00" --no-pager -o short-iso 2>&1 | \
    grep -Ei 'sudo:|visudo|sudoers|passwd|chpasswd|usermod|ansible|puppet|salt-minion' | \
    grep -Eiv 'snap_daemon.*unified-monitoring-agent' | head -n 250 || true
else echo 'journalctl unavailable'; fi
section 'AUDITD AVAILABILITY'
if command -v ausearch >/dev/null 2>&1; then
  echo 'ausearch available; historical events not queried automatically (audit rules/site-specific formats).'
  if command -v auditctl >/dev/null 2>&1; then auditctl -l 2>&1 | grep -Ei 'sudoers|sudoers.d|No rules' || true; fi
else echo 'ausearch unavailable'; fi
section 'LIMITATIONS / SECURITY'
echo 'READ ONLY: no changes to accounts, sudoers, services or passwords.'
echo 'No log records does not imply no change: logs may have rotated or never been collected.'
echo 'sudoers mtime is not proof of when rootpw was introduced.'
echo 'Reports may include usernames and command arguments; keep private and out of Git.'
