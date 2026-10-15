#!/usr/bin/env bash
# SPGG - Auditoria historica rootpw v1.3 | leitura das configuracoes e logs
# Uso: sudo bash SPGG_RootPW.sh [YYYY-MM-DD] [YYYY-MM-DD (exclusive)]
set -u
export LC_ALL=C
START="${1:-2026-07-01}"
END="${2:-2026-10-01}"
if [[ ! "$START" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ || ! "$END" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then echo 'ERROR: dates must be YYYY-MM-DD'; exit 2; fi
start_epoch=$(date -d "$START 00:00:00" +%s 2>/dev/null) || { echo 'ERROR: invalid start date'; exit 2; }
end_epoch=$(date -d "$END 00:00:00" +%s 2>/dev/null) || { echo 'ERROR: invalid end date'; exit 2; }
if (( start_epoch >= end_epoch )); then echo 'ERROR: start must precede end'; exit 2; fi
if (( EUID != 0 )); then echo 'ERROR: run as root using sudo'; exit 3; fi
section(){ printf '\n===== %s =====\n' "$1"; }
HOST_SHORT=$(hostname -s 2>/dev/null || hostname)
SUDOERS_MTIME=$(stat -c %y /etc/sudoers 2>/dev/null || echo unavailable)
SUDOERS_DAY=$(stat -c %y /etc/sudoers 2>/dev/null | cut -d' ' -f1)
ROOT_STATUS=$(passwd -S root 2>/dev/null || echo unavailable)
section 'EXECUTIVE SUMMARY'
printf 'Host: %s\nHostname short: %s\nCollected: %s\nWindow: %s to %s (end exclusive)\n' "$(hostname)" "$HOST_SHORT" "$(date -Is)" "$START" "$END"
if grep -RqsE '^[[:space:]]*Defaults[[:space:]]+rootpw([[:space:],]|$)' /etc/sudoers /etc/sudoers.d 2>/dev/null; then echo 'Global rootpw directive: FOUND (text scan; verify effective scope)'; else echo 'Global rootpw directive: not found by simple text scan'; fi
printf 'sudoers mtime: %s\nroot password status: %s\n' "$SUDOERS_MTIME" "$ROOT_STATUS"
if [[ -n "$SUDOERS_DAY" && "$SUDOERS_DAY" != unavailable ]]; then
  if [[ "$SUDOERS_DAY" < "$START" || "$SUDOERS_DAY" > "$END" || "$SUDOERS_DAY" == "$END" ]]; then
    echo 'sudoers mtime day: OUTSIDE REQUESTED WINDOW'
  else
    echo 'sudoers mtime day: INSIDE REQUESTED WINDOW'
  fi
fi
section 'IDENTIFICATION'
printf 'OS: '; ( . /etc/os-release; echo "${PRETTY_NAME:-unknown}" )
printf 'Timezone: '; date +%Z
printf 'Executed as: '; id
section 'SUDO EFFECTIVE DEFAULTS (FOR ROOT; NOT PER-USER PROOF)'
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
printf '%s\n' "$ROOT_STATUS"
chage -l root 2>&1 || true
section 'LOG SOURCES / RETENTION'
shopt -s nullglob
logs=(/var/log/auth.log /var/log/auth.log.[0-9]* /var/log/secure /var/log/secure.[0-9]*)
for f in "${logs[@]}"; do [[ -f "$f" ]] && stat -c '%n | bytes=%s | mtime=%y' "$f"; done
for f in /var/log/audit/audit.log*; do [[ -f "$f" ]] && stat -c '%n | bytes=%s | mtime=%y' "$f"; done
if command -v journalctl >/dev/null 2>&1; then journalctl --list-boots --no-pager 2>&1 | tail -n 15; fi
section 'AUTH LOG - PRIORITIZED EVENTS (MAX 100 HIGH + 60 MEDIUM PER FILE)'
echo 'NOTE: syslog timestamps usually omit year; year inferred from file mtime (heuristic, not forensic proof).'
echo 'NOTE: routine PAM sessions and CRON are counted, not printed. Matches are investigative leads.'
echo 'NOTE: HIGH identifies command keywords; it does not prove a configuration change.'
for f in "${logs[@]}"; do
  [[ -f "$f" ]] || continue
  printf '\n-- %s --\n' "$f"
  fileyear=$(date -d "@$(stat -c %Y "$f")" +%Y)
  filemonth=$(date -d "@$(stat -c %Y "$f")" +%m)
  if [[ "$f" == *.gz ]]; then reader=(gzip -cd -- "$f"); else reader=(cat -- "$f"); fi
  "${reader[@]}" 2>/dev/null | awk -v sy="$START" -v ey="$END" -v fy="$fileyear" -v fm="$filemonth" -v target="$SUDOERS_DAY" '
    BEGIN {
      split("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec",m," "); for(i=1;i<=12;i++) month[m[i]]=i
      min="";max=""; high=med=routine=other=metadata=0; target_lines=0
    }
    ($1 in month) && ($2 ~ /^[0-9][0-9]?$/) {
      mo=month[$1]; day=$2+0; if(!mo || day<1 || day>31) next
      year=fy+0; if(mo>(fm+0)+1) year--
      dt=sprintf("%04d-%02d-%02d",year,mo,day)
      if(min=="" || dt<min) min=dt; if(max=="" || dt>max) max=dt
      if(dt<sy || dt>=ey) next
      line=tolower($0)
      if(line ~ /pam_unix\([^)]*:session\): session (opened|closed)/ || line ~ /cron\[[0-9]+\]:/) {routine++;next}
      if(line ~ /snap_daemon/ && line ~ /unified-monitoring-agent/) {routine++;next}
      if(line ~ /visudo|sudoers|chpasswd|passwd|usermod|useradd|userdel|ansible|puppet|salt-minion|chef-client|semanage/ ||
         (line ~ /sudo:/ && line ~ /command=/ && line ~ /\/(vi|vim|nano|sed|tee|cp|mv|install|chmod|chown|passwd|visudo|usermod)([ ;]|$)/)) {
        if(high<100) print "[HIGH inferred " dt "] " $0
        high++;if(dt==target) target_lines++;next
      }
      if(line ~ /sudo:/ && (line ~ /command=/ || line ~ /authentication failure|incorrect password|not in the sudoers/)) {
        if(med<60) print "[MEDIUM inferred " dt "] " $0
        med++;if(dt==target) target_lines++;next
      }
      other++
    }
    END {
      printf "LOG_OBSERVED_DATE_RANGE=%s..%s (inferred, not proof of continuous coverage)\n",min==""?"unknown":min,max==""?"unknown":max
      printf "HIGH_MATCHES=%d; HIGH_DISPLAYED=%d; MEDIUM_MATCHES=%d; MEDIUM_DISPLAYED=%d; ROUTINE_SKIPPED=%d; METADATA_SKIPPED=%d; OTHER_SKIPPED=%d\n",high,high<100?high:100,med,med<60?med:60,routine,metadata,other
      printf "PRIORITIZED_EVENTS_ON_SUDOERS_MTIME_DAY=%d (absence does not rule out activity)\n",target_lines
    }
  ' || echo 'WARNING: log read or processing failed'
done
section 'JOURNAL - PRIORITIZED EVENTS (DATE-PRIORITIZED; MAX 100 HIGH + 60 MEDIUM)'
if command -v journalctl >/dev/null 2>&1; then
  # Two bounded journal queries: priority dates first, then the complete requested window.
  # The date-specific output is intentionally separate, so August events are not hidden
  # behind thousands of earlier records. All queries are read-only.
  declare -A seen_focus=()
  for focus in 2026-08-03 2026-08-05 "$SUDOERS_DAY"; do
    [[ "$focus" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || continue
    [[ "$focus" < "$START" || "$focus" == "$END" || "$focus" > "$END" ]] && continue
    [[ -n "${seen_focus[$focus]:-}" ]] && continue
    seen_focus[$focus]=1
    nextday=$(date -d "$focus +1 day" +%F)
    printf '\n-- PRIORITY DATE %s (UTC/local journal time) --\n' "$focus"
    journalctl --since "$focus 00:00:00" --until "$nextday 00:00:00" --no-pager -o short-iso 2>&1 | awk -v cap=120 '
      { line=tolower($0)
        if(line ~ /fetched metadata from endpoint|169[.]254[.]169[.]254\/opc\/v2|"user_data"|"userdata"/) {meta++;next}
        if(line ~ /pam_unix\([^)]*:session\): session (opened|closed)|cron\[[0-9]+\]:/) {routine++;next}
        if(line ~ /visudo|sudoers|chpasswd|passwd|usermod|useradd|userdel|ansible|puppet|salt-minion|chef-client|semanage/ ||
          (line ~ /sudo:/ && line ~ /command=/ && line ~ /\/(vi|vim|nano|sed|tee|cp|mv|install|chmod|chown)([ ;]|$)/)) {
            if(high<cap) print "[HIGH] " $0;high++;next
        }
        if(line ~ /sudo:/ && line ~ /command=|authentication failure|incorrect password/) {
            if(med<60) print "[MEDIUM] " $0;med++;next
        }
      }
      END {printf "PRIORITY_HIGH=%d; HIGH_DISPLAYED=%d; PRIORITY_MEDIUM=%d; MEDIUM_DISPLAYED=%d; METADATA_SKIPPED=%d; ROUTINE_SKIPPED=%d\n",high,high<cap?high:cap,med,med<60?med:60,meta,routine}
    '
  done
  printf '\n-- FULL WINDOW SUMMARY --\n'
  journalctl --since "$START 00:00:00" --until "$END 00:00:00" --no-pager -o short-iso 2>&1 | awk '
    BEGIN {high=med=routine=metadata=0}
    {
      line=tolower($0)
      if(line ~ /fetched metadata from endpoint|169[.]254[.]169[.]254\/opc\/v2|"user_data"|"userdata"/) {metadata++;next}
      if(line ~ /pam_unix\([^)]*:session\): session (opened|closed)|cron\[[0-9]+\]:/ || (line ~ /snap_daemon/ && line ~ /unified-monitoring-agent/)) {routine++;next}
      if(line ~ /visudo|sudoers|chpasswd|passwd|usermod|useradd|userdel|ansible|puppet|salt-minion|chef-client|semanage/ ||
        (line ~ /sudo:/ && line ~ /command=/ && line ~ /\/(vi|vim|nano|sed|tee|cp|mv|install|chmod|chown)([ ;]|$)/)) {
        if(high<100) print "[HIGH] " $0;high++;next
      }
      if(line ~ /sudo:/ && (line ~ /command=|authentication failure|incorrect password/)) {
        if(med<60) print "[MEDIUM] " $0;med++;next
      }
    }
    END {printf "JOURNAL_HIGH=%d; DISPLAYED=%d; JOURNAL_MEDIUM=%d; DISPLAYED=%d; ROUTINE_SKIPPED=%d; METADATA_SKIPPED=%d\n",high,high<100?high:100,med,med<60?med:60,routine,metadata}
  '
else echo 'journalctl unavailable'; fi
section 'SUDOERS MODIFICATION DATE - LOG COVERAGE ASSESSMENT'
printf 'sudoers mtime day: %s\n' "${SUDOERS_DAY:-unavailable}"
echo 'The log ranges above are inferred observations, not guarantees of complete retention.'
echo 'If no source covers the sudoers mtime day, attribution from local retained logs is not possible.'
echo 'Even if a source covers that day, only explicit records can support attribution.'
section 'AUDITD AVAILABILITY'
if command -v ausearch >/dev/null 2>&1; then
  echo 'ausearch available; historical events not queried automatically (audit rules/site-specific formats).'
  if command -v auditctl >/dev/null 2>&1; then auditctl -l 2>&1 | grep -Ei 'sudoers|sudoers.d|No rules' || true; fi
else echo 'ausearch unavailable'; fi
section 'LIMITATIONS / SECURITY'
echo 'READ ONLY: no changes to accounts, sudoers, services or passwords.'
echo 'No matching log records does not imply no change; logs may have rotated or never been collected.'
echo 'sudoers mtime is not proof of when rootpw was introduced or who changed it.'
echo 'Reports may contain usernames and command arguments; keep private and out of Git.'
