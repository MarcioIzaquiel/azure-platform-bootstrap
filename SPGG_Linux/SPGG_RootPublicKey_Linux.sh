#!/usr/bin/env bash
# SPGG - Inventario de chaves SSH autorizadas para root - v1.1
# READ ONLY: nao altera configuracoes, contas, chaves ou servicos.

set -u
export LC_ALL=C

if (( EUID != 0 )); then
  echo 'ERRO: executar via sudo bash'
  exit 3
fi

section(){
  printf '\n===== %s =====\n' "$1"
}

kv(){
  printf '%s=%s\n' "$1" "$2"
}

section 'IDENTIFICACAO'
kv HOSTNAME "$(hostname -s 2>/dev/null || hostname)"
kv COLLECTED "$(date -Is)"
kv OS "$(. /etc/os-release 2>/dev/null; echo "${PRETTY_NAME:-unknown}")"
kv MODE READ_ONLY

section 'CONFIGURACAO SSH EFETIVA (PADRAO)'

if command -v sshd >/dev/null 2>&1; then
  sshd -T 2>&1 | grep -Ei \
    '^(permitrootlogin|pubkeyauthentication|authorizedkeysfile|authorizedkeyscommand|passwordauthentication|authenticationmethods) ' || true
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

# Inspeciona os dois arquivos locais padrao, sem exibir chaves.
# NO_KEYS_LOCAL_FILES nao descarta outras fontes configuradas no sshd.

inspect_keys_file(){
  local file="$1" prefix="$2" count indicative

  section "ARQUIVO $(basename "$file")"

  if [[ -f "$file" ]]; then
    ls -l -- "$file"
    kv "${prefix}_FILE" EXISTS

    if [[ -r "$file" ]]; then

      # Contagem literal solicitada no inventario original.
      count=$(grep -cE \
        '^[[:space:]]*(ssh-ed25519|ssh-rsa|ecdsa-sha2-|sk-)' \
        -- "$file" || true)

      kv "${prefix}_KEYS_SIMPLE_GREP_COUNT" "$count"

      # Contagem indicativa de linhas com chave,
      # inclusive com opcoes antes do tipo da chave.
      # Nao imprime conteudo nem fingerprints.

      indicative=$(awk '
        /^[[:space:]]*(#|$)/ {next}
        {
          for(i=1;i<=NF;i++)
            if($i ~ /^(ssh-ed25519|ssh-rsa|ecdsa-sha2-[[:alnum:]_-]+|sk-ssh-ed25519@openssh.com|sk-ecdsa-sha2-nistp256@openssh.com)$/) {
              n++
              break
            }
        }
        END {print n+0}
      ' "$file")

      kv "${prefix}_KEYS_INDICATIVE_COUNT" "$indicative"
      kv "${prefix}_READ" OK

    else
      kv "${prefix}_KEYS_SIMPLE_GREP_COUNT" UNKNOWN
      kv "${prefix}_KEYS_INDICATIVE_COUNT" UNKNOWN
      kv "${prefix}_READ" FAILED
    fi

  elif [[ -e "$file" || -L "$file" ]]; then
    ls -ld -- "$file"
    kv "${prefix}_FILE" NOT_REGULAR
    kv "${prefix}_KEYS_SIMPLE_GREP_COUNT" UNKNOWN
    kv "${prefix}_KEYS_INDICATIVE_COUNT" UNKNOWN
    kv "${prefix}_READ" NOT_CHECKED

  else
    kv "${prefix}_FILE" ABSENT
    kv "${prefix}_KEYS_SIMPLE_GREP_COUNT" 0
    kv "${prefix}_KEYS_INDICATIVE_COUNT" 0
    kv "${prefix}_READ" NOT_APPLICABLE
  fi
}

inspect_keys_file /root/.ssh/authorized_keys AUTHORIZED_KEYS
inspect_keys_file /root/.ssh/authorized_keys2 AUTHORIZED_KEYS2

section 'RESUMO CHAVES LOCAIS ROOT'

# Consolida as contagens dos dois arquivos.
# Se algum arquivo nao puder ser avaliado, resultado indeterminado.

if [[ -f /root/.ssh/authorized_keys && ! -r /root/.ssh/authorized_keys ]] ||
   [[ -f /root/.ssh/authorized_keys2 && ! -r /root/.ssh/authorized_keys2 ]] ||
   [[ -e /root/.ssh/authorized_keys && ! -f /root/.ssh/authorized_keys ]] ||
   [[ -e /root/.ssh/authorized_keys2 && ! -f /root/.ssh/authorized_keys2 ]]; then

  kv ROOT_LOCAL_KEYS_TOTAL UNKNOWN
  kv ROOT_PUBLIC_KEY_STATUS INDETERMINATE

else
  total=0

  for f in /root/.ssh/authorized_keys /root/.ssh/authorized_keys2; do
    if [[ -f "$f" ]]; then

      n=$(awk '
        /^[[:space:]]*(#|$)/ {next}
        {
          for(i=1;i<=NF;i++)
            if($i ~ /^(ssh-ed25519|ssh-rsa|ecdsa-sha2-[[:alnum:]_-]+|sk-ssh-ed25519@openssh.com|sk-ecdsa-sha2-nistp256@openssh.com)$/) {
              n++
              break
            }
        }
        END {print n+0}
      ' "$f")

      total=$((total + n))
    fi
  done

  kv ROOT_LOCAL_KEYS_TOTAL "$total"

  if (( total > 0 )); then
    kv ROOT_PUBLIC_KEY_STATUS KEYS_PRESENT_LOCAL_FILES
  else
    kv ROOT_PUBLIC_KEY_STATUS NO_KEYS_LOCAL_FILES
  fi
fi

section 'LIMITACOES'

echo 'Uma chave cadastrada NAO comprova login SSH efetivamente realizado.'
echo 'A configuracao sshd pode variar por Match, usuario, IP do cliente e outras restricoes.'
echo 'AuthorizedKeysFile pode apontar para outros arquivos; AuthorizedKeysCommand pode fornecer chaves externamente.'
echo 'As contagens sao indicativas; opcoes, revogacoes e restricoes podem impedir o login.'
echo 'Nao sao exibidos conteudos de chaves, hashes, senhas ou logs de autenticacao.'
echo 'READ ONLY: nenhuma alteracao de configuracao remota.'