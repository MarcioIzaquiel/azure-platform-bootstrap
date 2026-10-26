#!/usr/bin/env bash
# SPGG - Inventario de chaves SSH autorizadas para root - v1.0
# READ ONLY: nao altera configuracoes, contas, chaves ou servicos.
set -u
export LC_ALL=C
if (( EUID != 0 )); then echo 'ERRO: executar via sudo bash'; exit 3; fi
section(){ printf '\n===== %s =====\n' "$1"; }
kv(){ printf '%s=%s\n' "$1" "$2"; }
section 'IDENTIFICACAO'
kv HOSTNAME "$(hostname -s 2>/dev/null || hostname)"
kv COLLECTED "$(date -Is)"
kv OS "$(. /etc/os-release 2>/dev/null; echo "${PRETTY_NAME:-unknown}")"
kv MODE READ_ONLY
section 'CONFIGURACAO SSH EFETIVA (PADRAO)'
if command -v sshd >/dev/null 2>&1; then
  sshd -T 2>&1 | grep -Ei '^(permitrootlogin|pubkeyauthentication|authorizedkeysfile|authorizedkeyscommand|passwordauthentication|authenticationmethods) ' || true
else
  kv SSHD_AVAILABLE NO
fi
section 'DIRETORIO ROOT SSH'
if [[ -d /root/.ssh ]]; then
  ls -ld /root/.ssh
  kv ROOT_SSH_DIR EXISTS
else
  kv ROOT_SSH_DIR ABSENT
  echo 'sudo ls -ld /root/.ssh: diretorio inexistente'
fi
section 'ARQUIVO AUTHORIZED_KEYS'
file=/root/.ssh/authorized_keys
if [[ -f "$file" ]]; then
  ls -l "$file"
  kv AUTHORIZED_KEYS_FILE EXISTS
  if [[ -r "$file" ]]; then
    # Reproduz a contagem solicitada; nao reconhece opcoes anteriores ao tipo da chave.
    count=$(grep -cE '^[[:space:]]*(ssh-ed25519|ssh-rsa|ecdsa-sha2-|sk-)' "$file" || true)
    kv KEYS_SIMPLE_GREP_COUNT "$count"
    # Contagem indicativa adicional: aceita opcoes de authorized_keys antes do tipo.
    # Nao imprime conteudo, comentarios ou fingerprints das chaves.
    awk '
      /^[[:space:]]*(#|$)/ {next}
      {for(i=1;i<=NF;i++) if($i ~ /^(ssh-ed25519|ssh-rsa|ecdsa-sha2-[[:alnum:]_-]+|sk-ssh-ed25519@openssh.com|sk-ecdsa-sha2-nistp256@openssh.com)$/) {n++;break}}
      END {print "KEYS_INDICATIVE_COUNT=" n+0}
    ' "$file"
    kv AUTHORIZED_KEYS_READ OK
  else
    kv AUTHORIZED_KEYS_READ FAILED
  fi
elif [[ -e "$file" ]]; then
  ls -ld "$file"
  kv AUTHORIZED_KEYS_FILE NOT_REGULAR
  kv AUTHORIZED_KEYS_READ NOT_CHECKED
else
  kv AUTHORIZED_KEYS_FILE ABSENT
  kv KEYS_SIMPLE_GREP_COUNT 0
  kv KEYS_INDICATIVE_COUNT 0
fi
section 'LIMITACOES'
echo 'Uma chave cadastrada NAO comprova login SSH efetivamente realizado.'
echo 'A configuracao sshd pode variar por Match, usuario, IP do cliente e outras restricoes.'
echo 'AuthorizedKeysFile pode apontar para outros arquivos; AuthorizedKeysCommand pode fornecer chaves externamente.'
echo 'As contagens sao indicativas; opcoes, revogacoes e restricoes podem impedir o login.'
echo 'Nao sao exibidos conteudos de chaves, hashes, senhas ou logs de autenticacao.'
echo 'READ ONLY: nenhuma alteracao de configuracao remota.'
