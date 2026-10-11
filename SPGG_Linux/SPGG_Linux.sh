
#!/usr/bin/env bash
# SPGG - Inventario de Usuarios e Acessos Linux
# Versao: 1.3
# Modo: Somente leitura

set -o pipefail

SCRIPT_NAME="$(basename "$0" .sh)"
HOST_NAME="$(hostname -s)"
DATA_ARQUIVO="$(date +%Y%m%d)"
DATA_AUDITORIA="$(date '+%d/%m/%Y %H:%M:%S %Z')"

RELATORIO="${PWD}/${DATA_ARQUIVO}_${HOST_NAME}_${SCRIPT_NAME}.txt"

secao() {
    printf '\n===== %02d - %s =====\n' "$1" "$2"
}

# Validar acesso sudo antes da auditoria
if ! sudo -v; then
    echo "ERRO: nao foi possivel validar o acesso sudo."
    exit 1
fi

# Exibir na tela e salvar em arquivo
exec > >(tee "$RELATORIO") 2>&1

echo "SPGG - INVENTARIO DE USUARIOS E ACESSOS LINUX"
echo "Versao do script : 1.3"
echo "Data da auditoria: $DATA_AUDITORIA"
echo "Servidor         : $HOST_NAME"
echo "Relatorio        : $RELATORIO"
echo "Modo             : Somente leitura"

secao 1 "SISTEMA OPERACIONAL"
grep -E '^(PRETTY_NAME|VERSION_ID)=' /etc/os-release

secao 2 "HOSTNAME"
printf "Static hostname: %s\n" "$(hostnamectl --static)"
printf "Operating System: %s\n" \
    "$(hostnamectl | sed -n 's/^[[:space:]]*Operating System: //p')"
printf "Kernel: %s\n" "$(uname -r)"
printf "Architecture: %s\n" "$(uname -m)"
echo "Enderecos IP:"
ip -br -4 addr show scope global
echo "IPv6 globais:"
ip -br -6 addr show scope global

secao 3 "USUARIO ATUAL"
whoami
id

secao 4 "USUARIOS HUMANOS (UID >= 1000)"
echo "Criterio: contas locais com UID de 1000 a 65533."
awk -F: '$3 >= 1000 && $3 < 65534 {
    printf "Usuario: %-20s UID: %-8s GID: %-8s Shell: %s\n",
           $1, $3, $4, $7
}' /etc/passwd

secao 5 "GRUPO SUDO"
getent group sudo

secao 6 "USUARIOS COM GRUPO SUDO"
while IFS=: read -r usuario _ uid _; do
    if (( uid >= 1000 && uid < 65534 )); then
        if id -nG "$usuario" | tr ' ' '\n' | grep -qx sudo; then
            echo "$usuario : SIM"
        else
            echo "$usuario : NAO"
        fi
    fi
done < /etc/passwd

secao 7 "USUARIOS SPGG"
for usuario in spggadmin procergs; do
    if id "$usuario" >/dev/null 2>&1; then
        id "$usuario"
    else
        echo "$usuario : NAO EXISTE"
    fi
done

secao 8 "STATUS DA SENHA ROOT"
sudo passwd -S root
echo "Interpretacao: P=senha definida; L=senha bloqueada; NP=sem senha."
echo "Senha bloqueada nao significa conta root inexistente."

secao 9 "STATUS DA CONTA ROOT"
getent passwd root
sudo chage -l root
echo "UID 0 identifica privilegios de superusuario."
echo "O bloqueio da senha nao impede o uso autorizado de sudo."

secao 10 "PRIVILEGIOS SUDO DO USUARIO ATUAL"
sudo -l
echo "Esta consulta mostra as permissoes sudo do usuario atual."
echo "Nao e uma consulta automatica dos privilegios do root."

secao 11 "PRIVILEGIOS SUDO DOS USUARIOS SPGG"
for usuario in spggadmin procergs; do
    if id "$usuario" >/dev/null 2>&1; then
        echo "--- $usuario ---"
        sudo -l -U "$usuario"
    else
        echo "$usuario : NAO EXISTE"
    fi
done

secao 12 "STATUS DO SERVICO SSH"
printf "Habilitacao: "
systemctl is-enabled ssh
printf "Execucao: "
systemctl is-active ssh

secao 13 "CONFIGURACAO EFETIVA SSH"
sudo sshd -T | grep -E \
'^(port|permitrootlogin|passwordauthentication|pubkeyauthentication|kbdinteractiveauthentication|permitemptypasswords) '

echo
echo "--- INTERPRETACAO SSH ---"
echo "permitrootlogin no: bloqueia login SSH direto do root."
echo "permitrootlogin prohibit-password: bloqueia senha do root,"
echo "mas pode permitir autenticacao por chave publica."
echo "passwordauthentication yes: permite autenticacao por senha."
echo "pubkeyauthentication yes: permite autenticacao por chave."
echo "kbdinteractiveauthentication no: desabilita esse metodo."
echo "permitemptypasswords no: nao aceita senhas vazias via SSH."

echo
echo "--- AUTENTICACAO SUDO ---"
echo "O sudo normalmente solicita a senha do proprio usuario."
echo "Defaults rootpw: solicita a senha da conta root."
echo "Defaults targetpw: solicita a senha do usuario de destino."
echo "Defaults runaspw: solicita a senha do usuario runas_default."
echo "NOPASSWD: pode dispensar autenticacao para comandos autorizados."

echo
echo "--- OPCOES SUDO CONFIGURADAS ---"
sudo grep -hE \
'^[[:space:]]*Defaults([[:space:]]|:|@|>).*' \
    /etc/sudoers /etc/sudoers.d/* 2>/dev/null || true

echo
echo "IMPORTANTE: ausencia de rootpw, targetpw e runaspw"
echo "normalmente significa que sudo pede a senha do proprio usuario."
echo "Regras por usuario, grupo ou comando podem alterar esse comportamento."

secao 14 "PORTA SSH EM ESCUTA"
sudo ss -tlnp | grep -E 'sshd|:22[[:space:]]' || \
    echo "Nenhuma entrada SSH identificada."
echo "A porta configurada pode ser diferente de 22."

secao 15 "FIREWALL"
sudo ufw status verbose
echo "Observacao: UFW inativo nao exclui outras regras de firewall."

secao 16 "DISCOS E PARTICOES"
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINTS

secao 17 "STATUS DAS SENHAS DOS USUARIOS SPGG"
for usuario in spggadmin procergs; do
    if id "$usuario" >/dev/null 2>&1; then
        echo "--- $usuario ---"
        sudo passwd -S "$usuario"
        sudo chage -l "$usuario"
    else
        echo "$usuario : NAO EXISTE"
    fi
done