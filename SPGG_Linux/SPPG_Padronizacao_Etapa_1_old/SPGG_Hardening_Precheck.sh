#!/usr/bin/env bash
# SPGG - Padronizacao Etapa 1 - Precheck v1.0
# READ ONLY: nenhuma alteracao em contas, senhas, SSH, sudoers ou servicos.
set -u
export LC_ALL=C
section(){ printf '\n===== %s =====\n' "$1"; }
kv(){ printf '%s=%s\n' "$1" "$2"; }
run(){ "$@" 2>&1 || true; }
if (( EUID != 0 )); then echo 'ERRO: executar via sudo bash'; exit 3; fi
section 'IDENTIFICACAO'
kv HOSTNAME "$(hostname -s 2>/dev/null || hostname)"
kv COLLECTED "$(date -Is)"
kv OS "$(. /etc/os-release 2>/dev/null; echo "${PRETTY_NAME:-unknown}")"
kv IP_IPV4 "$(ip -o -4 addr show scope global 2>/dev/null | awk '{print $2":"$4}' | paste -sd, -)"
kv MODE READ_ONLY
section 'ROOT'
root_line=$(passwd -S root 2>/dev/null || true)
kv ROOT_PASSWD_STATUS "$root_line"
kv ROOT_PASSWD_STATE "$(printf '%s\n' "$root_line" | awk '{print $2}')"
kv ROOT_LAST_CHANGE "$(printf '%s\n' "$root_line" | awk '{print $3}')"
kv ROOT_SHELL "$(getent passwd root | awk -F: '{print $7}')"
section 'ACESSO ADMINISTRATIVO'
for user in procergs spggadmin cdsadmin; do
  upper=$(printf '%s' "$user" | tr '[:lower:]' '[:upper:]')
  if getent passwd "$user" >/dev/null; then
    kv "USER_${upper}_EXISTS" YES
    kv "USER_${upper}_GROUPS" "$(id -nG "$user" 2>/dev/null | tr ' ' ',')"
    kv "USER_${upper}_PASSWD" "$(passwd -S "$user" 2>/dev/null | awk '{print $2}')"
    # -l -U informa autorizacao; nao testa senha nem executa comandos.
    printf '\n-- SUDO_RULES %s --\n' "$user"
    run sudo -n -l -U "$user"
  else
    kv "USER_${upper}_EXISTS" NO
  fi
done
kv GROUP_SUDO "$(getent group sudo || true)"
kv GROUP_WHEEL "$(getent group wheel || true)"
printf '\n-- UID 0 accounts --\n'
getent passwd | awk -F: '$3==0 {print $1":"$3":"$7}'
printf '\n-- Sudo/wheel memberships (local and NSS) --\n'
getent passwd | while IFS=: read -r name _ uid _; do
  case "$uid" in ''|*[!0-9]*) continue;; esac
  if (( uid >= 1000 && uid < 65534 )); then
    groups=$(id -nG "$name" 2>/dev/null || true)
    if printf ' %s ' "$groups" | grep -Eq ' (sudo|wheel) '; then printf '%s: %s\n' "$name" "$groups"; fi
  fi
done
section 'SUDOERS'
kv SUDOERS_SYNTAX "$(visudo -c 2>&1 | tail -n 1)"
for f in /etc/sudoers /etc/sudoers.d/*; do
  [[ -f "$f" ]] || continue
  stat -c 'SUDOERS_FILE=%n|owner=%U:%G|mode=%a|mtime=%y|sha256=' "$f" 2>/dev/null | tr '\n' ' '
  sha256sum "$f" 2>/dev/null | awk '{print $1}'
  grep -nEi '^[[:space:]]*Defaults([[:space:]:@!>]|$)|^[[:space:]]*(@includedir|#includedir|@include|#include)' "$f" 2>/dev/null | sed "s|^|DIRECTIVE $f:|" || true
done
# Defaults efetivos variam por usuario, host e comando; sudo -l -U acima e apenas evidencia parcial.
if grep -RqsE '^[[:space:]]*Defaults[[:space:]]+rootpw([[:space:],]|$)' /etc/sudoers /etc/sudoers.d 2>/dev/null; then
  kv GLOBAL_ROOTPW_TEXT FOUND
else
  kv GLOBAL_ROOTPW_TEXT NOT_FOUND
fi
if grep -RqsEi '^[[:space:]]*Defaults.*(rootpw|targetpw|runaspw)' /etc/sudoers /etc/sudoers.d 2>/dev/null; then
  kv SUDO_PASSWORD_DIRECTIVES_PRESENT YES
else
  kv SUDO_PASSWORD_DIRECTIVES_PRESENT NO
fi
section 'SSH'
kv SSH_SERVICE_ACTIVE "$(systemctl is-active ssh 2>/dev/null || systemctl is-active sshd 2>/dev/null || echo unknown)"
kv SSHD_CONFIG_TEST "$(sshd -t 2>&1 && echo OK || echo FAILED)"
# Checar contexto root para cada IP local, incluindo regras Match (aproximacao, nao substitui testes reais).
if command -v sshd >/dev/null 2>&1; then
  for ipaddr in $(ip -o -4 addr show scope global 2>/dev/null | awk '{split($4,a,"/");print a[1]}'); do
    printf '\n-- SSH_EFFECTIVE_ROOT addr=%s --\n' "$ipaddr"
    sshd -T -C "user=root,host=$(hostname -f 2>/dev/null || hostname),addr=$ipaddr,laddr=$ipaddr,lport=22" 2>&1 | grep -Ei '^(permitrootlogin|passwordauthentication|pubkeyauthentication|kbdinteractiveauthentication|authenticationmethods|allowusers|denyusers|allowgroups|denygroups|port) ' || true
  done
  printf '\n-- SSH_DEFAULT --\n'
  sshd -T 2>&1 | grep -Ei '^(permitrootlogin|passwordauthentication|pubkeyauthentication|kbdinteractiveauthentication|authenticationmethods|allowusers|denyusers|allowgroups|denygroups|port) ' || true
else
  kv SSHD_AVAILABLE NO
fi
section 'PAM_AND_SSSD'
for f in /etc/pam.d/sudo /etc/pam.d/sshd /etc/nsswitch.conf /etc/sssd/sssd.conf; do
  if [[ -e "$f" ]]; then
    stat -c 'CONFIG_FILE=%n|owner=%U:%G|mode=%a|mtime=%y' "$f" 2>/dev/null || true
    # Nao extrair conteudo de sssd.conf (pode conter segredos).
    if [[ "$f" == /etc/pam.d/sudo || "$f" == /etc/pam.d/sshd ]]; then grep -En '^[[:space:]]*[^#[:space:]]' "$f" 2>/dev/null || true; fi
  fi
done
kv SSSD_ACTIVE "$(systemctl is-active sssd 2>/dev/null || echo unavailable)"
section 'LIMITACOES'
echo 'READ ONLY: sem mudancas de configuracao ou senha.'
echo 'sshd -T -C depende do contexto Match; IP do cliente real deve ser validado.'
echo 'sudo -l -U nao demonstra que senha sera pedida em sessao interativa.'
echo 'Nunca armazenar senhas ou hashes em relatorios.'
