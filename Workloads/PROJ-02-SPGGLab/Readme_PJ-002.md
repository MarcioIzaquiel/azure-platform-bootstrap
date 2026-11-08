
---
---
---
---
---
---
---
---
---
---
# Projeto-002: Laboratório SPGG

## Estratégia de implementação: Roadmap de execução: 

### 0. Governança e planejamento 
1. [x] Definir objetivos, escopo e critérios de aceite 
2. [x] Definir arquitetura lógica e física 
3. [x] Definir naming e tags 
4. [x] Inventariar hardware e licenciamento
5. [ ] Estimar custos locais e Azure 
6. [ ] Registrar Cost Gate GO / NO-GO 

### 1. Fundação local, infraestrutura local 
1. [x] Validar hardware, BIOS, e virtualização 
2. [x] Preparar SSD do XPS, Vostro e E6510
3. [x] Instalar e configurar Proxmox 01, Proxmox 02, Proxmox 03
4. [x] Definir redes e isolamento do laboratório 
5. [ ] Configurar backups e snapshots 
6. [ ] Validar acesso remoto seguro 

### 2. Acesso remoto seguro (Tailscale ou WireGuard, administração dos hipervisores e teste de acesso externo. VPN privada, autenticação, controle de acesso). 
1. [ ] Testar acesso fora da LAN 
2. [ ] Testar ligar/desligar VMs remotamente 
3. [ ] Testar Wake-on-LAN dos hosts 
Entrega: acesso seguro de uma rede externa, sem publicar interfaces administrativas na Internet. 

### 3. Active Directory + Linux (Identidade, Segurança)    
1. [x] Criar domínio raiz  
2. [ ] Criar domínio filho 
3. [ ] Configurar DNS e sincronização de horário 
4. [ ] Testar GPOs
5. [ ] Instalar Linux cliente de teste 
6. [ ] Integrar SSSD e PAM ao domínio filho 
7. [ ] Configurar SSH e privilégios sudo 
8. [ ] Testar ADsys e políticas aplicáveis (GPOs) 
9. [ ] Configurar gestão de patches 
10. [ ] Documentar evidências e rollback 
Entrega: Linux autenticando usuários do domínio filho e aplicando privilégios administrativos controlados. 

### 4. OCS Inventory    
1. [ ] Instalar servidor OCS 
2. [ ] Instalar agentes em estações e servidores 
3. [ ] Criar campos administrativos 
4. [ ] Configurar filtros e relatórios 
5. [ ] Validar inventário automatizado 
Entrega: inventário consultável de servidores e estações simuladas. 
  
### 5. Zabbix e Grafana    
1. [ ] Instalar Zabbix Server 
2. [ ] Instalar agentes e templates 
3. [ ] Configurar Grafana e fonte de dados 
4. [ ] Criar dashboards de servidores (Disponibilidade, CPU, RAM, disco) 
5. [ ] Criar dashboard de alertas ativos 
6. [ ] Configurar notificações 
7. [ ] Monitorar vencimento de certificados 
8. [ ] Simular falhas e validar alertas 
Entrega: dashboards operacionais e notificações validadas por incidentes simulados. 

### 6. Syslog/Graylog (opcional) Centralização de logs, correlação básica e retenção. 
- rsyslog/syslog-ng, retenção, consultas e encaminhamento de eventos. Ferramenta usada pelo SPGG é Graylog. 
1. [ ] Avaliar servidor Syslog 
2. [ ] Validar centralização e retenção de logs 
3. Entrega: logs Linux centralizados e pesquisáveis. 

### 7. Integração Azure (Hybrid Cloud)   
1. [ ] Verificar Azure Policy e RBAC 
2. [ ] Criar RG somente quando necessário 
3. [ ] Verificar custos antes de cada serviço 
4. [ ] Testar integração híbrida de identidade (Entra ID, sincronização híbrida, Microsoft Entra Connect Sync ou Cloud Sync) 
5. [ ] Avaliar Azure Arc, Windows Admin Center on Azure Portal 
6. [ ] Azure Monitor, Log Analytics, Azure Update Manager 
7. [ ] Testar Key Vault e certificados 
8. [ ] Avaliar Intune, políticas, atualizações e inscrição do iPad (MDM) 
9. [ ] Comparar alternativas de VPN, acesso híbrido, acesso remoto
9. [ ] Segurança, opções Defender
10. [ ] Verificar Cost Management e métricas 
- Entrega: dispositivo de testes gerenciado, conforme licenciamento disponível 
- Entrega: prova de conceito de gestão híbrida com custos controlados. 

### 8. Outros  (opcional)
1. [ ] Docker (simulando legado HSP para HSM)
2. [ ] Docker consolidando OCS, Zabbix/Grafana, Graylog na mesma VM ou na Azure
3. [ ] WSUS atendendo 2 dominios (simulando SPGG e TF)
4. [ ] Azure Hybrid Cloud + GitHub
5. [ ] Script para recriar dc-01 e dc-02
6. [ ] Certificados (OCS Inventory, Grafana)


### 9. Validação operacional    
- Segurança, custos, desligamento, religamento, recuperação e documentação final. 
1. [ ] Testar suspensão dos componentes locais 
2. [ ] Testar reativação e dependências 
3. [ ] Testar desligamento dos recursos Azure 
4. [ ] Validar custos residuais e recuperação 
5. [ ] Documentar procedimentos e resultados no GitHub 
6. [ ] Preparar apresentação técnica para a SPGG 

---
---
---
---
---
---
---
---
---
---

## 0. Governança e planejamento 

### 0.1. Definir objetivos, escopo e critérios de aceite 

#### Construção do AS IS, para simular a SPGG hoje: 
- A SPGG hoje faz parte de um AD de dominio principal (intra.rs.gov.br) e um subsdominio (seplag.intra.rs.gov.br), simulando o serviço de AD (ADS) prestado pela PROCERGS a SPGG. Sugestão de dominio: ad.marciolab.test e sub.ad.marciolab.test 
- Os servidores linux despadronizados, quanto ao acesso e segurança e as ferramentas, como OCS Inventory, Zabbix/Grafana (e se der tempo e espaço, o Syslog(Graylog)).  
- Essas VMs serão distribuídas nos XPS502l 16GB, Vostro v131 8GB e E6510 8GB com Promox. Também podemos usar ocasionalmente, na memoria que sobra do uso normal o Thinkpad E14 Windows 11 Pro + VirtualBox 16GB (notebook pessoal) 
- Azure/Microsoft 365/Entra ID atual usado pela SPGG: @spgg.rs.gov.br. Sugestão, usar o meu Azure subscription que estamos usando na trilha. 
- Esse ambiente deve ser acessado externamente, com possibilidade de ligar e desligar os notes VMs remotamente. Para eu poder estudar e usar fora de casa. 
- OCS Inventory: inventário padrão 
- Zabbix/Grafana: Dashboard básico de Disponibilidade, CPU, Memo, Disco. 1 Dashboard agrupado por servidor e 1 Dashboard por servidor individual. 
- AD e Entra ID não integrado. 

#### Evolução do AS IS pré Azure (Importante para minha evolução profissional de curto prazo): 
- Servidores Linux Pré-SSSD: Padronização de acesso aos servidores Linux. 
- Servidores Linux Pré-SSSD: Gestão de patches usando ferramenta local. 
- SSSD: SSSD+ADsys+PAM+GPOs 
- SSSD: criação de GPOs e gestão de patches no cenário com SSSD 
- OCS Inventory: Criar campos administrativos no OCS Inventory para adicionar informações ao inventário de servidores, para filtros e relatórios. 
- OCS Inventory: Criar inventário de workstation, Server 
- OCS Inventory: Criação de dashboards no grafana, fonte OCS Inventory 
- OCS Inventory: Acesso ao banco de dados, HeidiSQL, PowerBi, Grafana 
- Zabbix/Grafana: criação de trigger e alertas, dashboard para alerta e com status/histórico de alertas 

#### Evolução integração Azure: 
- Criação de uma nuvem híbrida 
- Entra ID (Integraçao com ADs) 
- Intune, políticas, gestão de patches servidores Windows, Linux, Workstations  
- Key Vault: certificados, credenciais 
- Gestão de Certificados 
- VPNs 
- Monitoramento Azure 
- Defender/IA 
- MDM para o iPAD

#### Resultados esperados:
Ao concluir, teremos um ambiente capaz de demonstrar:
- Autenticação centralizada de servidores Linux utilizando AD, SSSD e PAM.
- Padronização de privilégios administrativos e aplicação de políticas.
- Atualização e gestão de patches Linux.
- Inventário centralizado de equipamentos com OCS Inventory.
- Monitoramento e alertas com Zabbix e Grafana.
- Acesso remoto seguro ao laboratório.
- Integração de identidade e recursos com Azure.
- Procedimentos de operação, recuperação e desligamento documentados.

#### Pontos de atenção:
- A assinatura Azure existente não concede automaticamente todas as licenças Microsoft 365, Entra ID Premium ou Intune. A elegibilidade e os custos deverão ser verificados antes de cada laboratório.
- O Intune será estudado para gerenciamento de dispositivos compatíveis. Para patch management de servidores, a prioridade será Azure Update Manager e/ou ferramentas locais apropriadas.
- O Key Vault poderá ser utilizado para segredos e certificados, mas a integração de certificados com serviços internos exigirá avaliar distribuição, confiança e renovação.
- A sincronização com Entra ID exigirá um domínio UPN verificável. O sufixo .test permanecerá restrito ao AD interno.

### 0.2. Definir arquitetura lógica e física 

#### Laboratorio SOHO local: 
- XPS l502x: 16GB, 447GB SSD, Proxmox 01
- Vostro V131: 8GB, 240GB SSD, Proxmox 02
- E6510: 8GB, 120GB SSD, Proxmox 03
- Thinkpad E14: 16GB, 473GB SSD, Windows 11 Pro (note pessoal) + administração e VirtualBox
- iPAD 10 pessoal 
- Azure subscription usada na trilha de aprendizagem 

#### Setup:
##### XPS L502x: Proxmox 01
- Hostname/IP: XPS, 192.168.1.201
- Hosts de VMs:
  - VM-DC-01 AD root ad.marciolab.test, IP: 192.168.1.210
  - VM-DC-02 AD subdomain sub.ad.marciolab.test, IP: 192.168.1.211
  - VM-UBU-01 Ubuntu Server para lab SSSD/PAM/ADsys, IP: 192.168.1.212
##### Vostro v131: Proxmox 02
- Hostname/IP: Vostro, 192.168.1.202
- Hosts de VMs:
  - VM-OCS-01 OCS Inventory, IP: 192.168.1.213
  - VM ?
  - https://www.youtube.com/watch?v=iYBMLHyTGPg
##### E6510: Proxmox 03
- Hostname/IP: E6510, 192.168.1.203
- Host de VMs:
  - VM ?
##### iPad geração 10
- Administração e operação do ambiente e testes de MDM
##### VMs
- VM OCS Inventory, IP: 192.168.1.213
- VM Zabbix/Grafana, IP: 192.168.1.214
- VM Graylog/Syslog, IP: 192.168.1.215
- VM Windows cliente, IP: DHCP
- VM Lubuntu cliente, IP: DHCP
##### Azure subscription 

### 0.3. Definir naming e tags 

#### Naming convention e tags para VMs:
##### TIPO-PROJETO-AMBIENTE-REGIAO-INSTANCIA
- Proxmox 1: pve-spgg-lab-01 = XPS
- Proxmox 2: pve-spgg-lab-02 = Vostro
- Proxmox 3: pve-spgg-lab-03 = E6510
- DC principal: vm-dc-01
- DC sub: vm-dc-02
- VM Linux: vm-ubu-01
- VM Windows: vm-win-01
- VM OCS: vm-ocs-01
- VM Zabbix/Grafana: vm-zbx-01
- VM Syslog: vm-log-01
- Management Group: MG-MarcioLab
- Subscription: Sub-MarcioLab
- Resource Group: rg-spgg-lab
- Key Vault: kv-spgg-lab-eus-01
- Log Analytics, se necessário: log-spgg-lab-eus-01
- VM Azure: vm-spgg-lab-eus-01
#### Tags convention:
- Owner: Marcio
- Environment: Lab
- Project: SPGG-Lab
- CostCenter: Learning
- ManagedBy: Manual
- Lifecycle: Temporary

### 0.4. Inventariar hardware e licenciamento

---
---
---
---
---
---
---
---
---
---

## 1. Fundação local, infraestrutura local 

### 1.1, 1.2 vide 0.2. Definir arquitetura lógica e física 

### 1.3 Instalar Debian 12 -> Proxmox 8 -> Proxmox 9 -> Debian 13 (XPS)

- [x] Instalação mínima do Debian 12
  - `systemctl poweroff`
  - `su -`
- [x] Configuração dos repositórios Debian
  - `cat /etc/apt/sources.list`
  - `ls -l /etc/apt/sources.list.d/`
  - `nano /etc/apt/sources.list`
    - #cdrom
    - deb http://deb.debian.org/debian bookworm main contrib non-free-firmware
    - deb http://deb.debian.org/debian bookworm-updates main contrib non-free-firmware
    - deb http://security.debian.org/debian-security bookworm-security main contrib non-free-firmware
  - `apt update`
  - `apt list --upgradable`
  - `apt upgrade`
- [x] Instalação e habilitação do SSH
  - `apt install openssh-server -y`
  - `systemctl enable --now ssh`
  - `systemctl status ssh`
  - `ss -tlnp | grep ':22'`
- [x] Verificação de hardware e virtualização
  - `lscpu | grep -E 'Model name|Virtualization|Architecture'`
  - `lspci -nnk | grep -A 4 -i ethernet`
  - `apt install ethtool -y`
  - `ethtool -i enp5s0`  
- [x] Configuração do hostname e resolução local
  - `cp /etc/hosts /etc/hosts.bak`
  - `nano /etc/hosts`
    - 127.0.0.1       localhost
    - 192.168.1.201   XPS.home.arpa XPS
- [x] Configuração da bridge vmbr0 e IP fixo
  - `apt update`
  - `apt install ifupdown2 bridge-utils -y`
  - `command -v ifreload`
  - `cp -a /etc/network/interfaces /etc/network/interfaces.bak` 
  - `nano /etc/network/interfaces`
    - auto lo
    - iface lo inet loopback
    - auto enp5s0
    - iface enp5s0 inet manual
    - 
    - auto vmbr0
    - iface vmbr0 inet static
      - address 192.168.1.201/24
      - gateway 192.168.1.1
      - bridge-ports enp5s0
      - bridge-stp off
      - bridge-fd 0
      - #enp5s0 inet manual	Deixa a interface física sem IP próprio
      - #auto vmbr0	Ativa a bridge automaticamente
      - #inet static	Define IP fixo
      - #address	IP de gerenciamento do XPS
      - #gateway	Roteador da rede SOHO
      - #bridge-ports enp5s0	Conecta a bridge à Ethernet física
      - #bridge-stp off	Desabilita STP nessa bridge
      - #bridge-fd 0	Define atraso de encaminhamento como zero
  - `ifreload -a`
  - `ip -br addr`
  - `ip route`
  - `bridge link`
- [x] Adição do repositório Proxmox
  - `apt install wget ca-certificates gnupg -y`
  - `wget https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg \
  -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg`
  - `echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" \
  > /etc/apt/sources.list.d/pve-install-repo.list`
  - `apt update`
  - `apt-cache policy proxmox-default-kernel
apt-cache policy proxmox-ve`
- [x] Instalação do kernel Proxmox 6.8
  - `df -h /boot`
  - `apt install proxmox-default-kernel`
  - `dpkg -l 'proxmox-kernel*' 'proxmox-default-kernel'`
  - `df -h /boot`
  - `reboot`
  - `uname -r`  
- [x] Instalação do Proxmox VE 8.4
  - `apt-get -s install proxmox-ve postfix open-iscsi`
  - `apt-get -s install proxmox-ve postfix open-iscsi \
  | grep -E '^(Inst|Remv) (proxmox-ve|pve-manager|qemu-server|pve-cluster|postfix|open-iscsi|ifupdown2|openssh-server) '`
  - `apt-cache policy proxmox-ve pve-manager`
  - `apt install proxmox-ve postfix open-iscsi`  
- [x] Acesso à interface web
  - https://192.168.1.201:8006
  - user: root senha do root do s.o.
- [x] Validação dos serviços e pacotes
  - `pveversion -v`  
  - `systemctl status pveproxy --no-pager`
  - `systemctl status pvedaemon --no-pager`
  - `systemctl status pve-cluster --no-pager`
  - `dpkg -l pve-edk2-firmware`
  - `apt-cache policy pve-edk2-firmware`
  - `dpkg --audit`
  - `apt-get -s install pve-edk2-firmware`
  - `apt install pve-edk2-firmware`
  - `dpkg -l pve-edk2-firmware`  
- [x] Configuração do armazenamento local
  - `pvesm status`
  - `pvs`
  - `vgs`
  - `lvs`
  - `cat /etc/pve/storage.cfg`
  - `pvesm add dir local --path /var/lib/vz --content images,rootdir,iso,vztmpl,backup,snippets`
  - `pvesm list local --content images`
  - `pvesm list local --content iso`
  - `pvesm set local --content images,rootdir,iso,vztmpl,backup,snippets`
  - `cat /etc/pve/storage.cfg`
- [x] Verificação de compatibilidade pve8to9
  - `pve8to9 --full`
  - `apt update`
  - `apt full-upgrade`
  - `apt install chrony`
  - `systemctl status chrony --no-pager
chronyc tracking`  
  - `pveversion
df -h /boot
uname -r`
  - `pve8to9 --full`

- [x] Migração para Proxmox VE 9
  - Verificação dos repositórios existentes
    - `cat /etc/apt/sources.list`
    - `ls -l /etc/apt/sources.list.d/`
    - `grep -R -nE 'bookworm|trixie|proxmox|enterprise' /etc/apt/sources.list /etc/apt/sources.list.d/`
  - Backup das configurações antes da migração
    - `mkdir -p /root/backup-pre-pve9`
    - `cp -a /etc/apt/sources.list /root/backup-pre-pve9/`
    - `cp -a /etc/apt/sources.list.d /root/backup-pre-pve9/`
    - `cp -a /etc/network/interfaces /root/backup-pre-pve9/`
    - `cp -a /etc/hosts /root/backup-pre-pve9/`
  - Atualização dos repositórios Debian 12 → Debian 13
    - `nano /etc/apt/sources.list`
    - Substituir `bookworm` por `trixie`:
      ```text
      deb http://deb.debian.org/debian trixie main contrib non-free non-free-firmware
      deb http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware
      deb http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
      ```
  - Atualização do repositório Proxmox VE 8 → VE 9
    - `nano /etc/apt/sources.list.d/pve-install-repo.list`
    - Configurar:
      ```text
      deb [signed-by=/etc/apt/trusted.gpg.d/proxmox-release-trixie.gpg] http://download.proxmox.com/debian/pve trixie pve-no-subscription
      ```
    - `cat /etc/apt/sources.list`
    - `cat /etc/apt/sources.list.d/pve-install-repo.list`
    - `apt update`
    - `apt-cache policy proxmox-ve pve-manager`
    - Verificar se as versões candidatas pertencem ao Proxmox VE 9.
  - Simulação e análise de dependências
    - `apt-get -s dist-upgrade`
    - `apt-get -s dist-upgrade | grep -E '^(Remv|Inst proxmox-ve|Inst pve-manager|Inst proxmox-default-kernel|Inst pve-cluster|Inst qemu-server|Inst ifupdown2|Inst openssh-server)'`
    - `apt-get -s dist-upgrade | grep '^Remv ' | grep -E '^Remv (proxmox-ve|pve-manager|pve-cluster|qemu-server|pve-qemu-kvm|openssh-server|ifupdown2|proxmox-default-kernel)( |:)'`
    - `apt-get -s dist-upgrade 2>&1 | grep -E 'upgraded,|newly installed,|to remove|not upgraded|^E:|^W:'`
    - Confirmar que os pacotes essenciais do Proxmox não serão removidos.
    - Remoções de bibliotecas antigas podem ocorrer durante a atualização do Debian 12 para o Debian 13.
  - Preparação de sessão persistente via SSH
    - `apt install tmux`
    - `tmux -V`
    - `tmux new -s upgrade-pve9`
    - `echo "$TMUX"`
    - A sessão `tmux` permite manter a atualização em execução caso a conexão SSH seja interrompida.
    - Para reconectar, a partir de uma sessão externa ao `tmux`: `tmux attach -t upgrade-pve9`
  - Verificações antes da execução
    - `hostname`
    - `cat /etc/os-release`
    - `pveversion`
    - `dpkg --audit`
    - `apt-mark showhold`
    - `apt-get check`
  - Simulação final e registro
    - `apt-get -s dist-upgrade 2>&1 | tee /root/simulacao-upgrade-pve9.txt | grep -E '^(Remv|Inst) (proxmox-ve|pve-manager|proxmox-default-kernel|pve-cluster|qemu-server|ifupdown2|openssh-server) |[0-9]+ upgraded,'`
    - `grep '^Remv ' /root/simulacao-upgrade-pve9.txt | awk '{print $2}'`
    - `grep '^Inst proxmox-kernel-' /root/simulacao-upgrade-pve9.txt`
    - `apt-get -s dist-upgrade 2>&1 | grep -E '^(E:|W:|[0-9]+ upgraded,)'`
    - Resultado da simulação: 733 pacotes atualizados, 192 novos, 63 removidos e nenhum pendente.
    - Kernel Proxmox 7.0 identificado para instalação.
  - Execução da migração
    - `apt-get dist-upgrade`
    - Aguardar download, instalação, substituição e configuração dos pacotes.
    - Resolver eventuais perguntas sobre arquivos de configuração conforme as alterações existentes.
    - Não interromper a atualização.
  - Validação após a migração
    - `dpkg --audit`
    - `pveversion -v`
    - `uname -r`
    - `systemctl is-active pveproxy pvedaemon pve-cluster pvestatd`
    - `pvesm status`
    - Confirmado: Proxmox VE **9.2.0**, `pve-manager` 9.2.24 e kernel 7.0.14-26-pve.
    - Serviços principais ativos e armazenamento `local` ativo.
  
 - [x] Correção da tela preta no XPS após reinicialização
    - Problema identificado: tela preta após GRUB, apesar de o sistema continuar acessível via SSH.
    - Hardware gráfico: Intel HD Graphics (driver `i915`) e NVIDIA GeForce GT 525M (driver `nouveau`).
    - Diagnóstico:
      - `lspci -nnk | grep -A 4 -Ei 'VGA|3D|Display'`
      - `journalctl -b --no-pager | grep -Ei 'drm|i915|nouveau|nvidia|fbcon|framebuffer|simpledrm' | tail -n 70`
      - `cat /proc/cmdline`
    - Correção: desabilitar o carregamento do driver `nouveau` por parâmetro do kernel.
    - Parâmetro aplicado: `modprobe.blacklist=nouveau`
    - Manter o driver Intel `i915` ativo.
    - Após reinicialização:
      - `cat /proc/cmdline`
      - `lsmod | grep -E 'nouveau|i915'`
      - `uname -r`
    - Resultado: console local restaurado, acesso SSH mantido e kernel Proxmox 7.0 operacional.
  - Validação final
    - `pveversion -v`
    - `systemctl is-active pveproxy pvedaemon pve-cluster pvestatd`
    - `dpkg --audit`
    - `pvesm status`
    - Interface web: https://192.168.1.201:8006
    - Resultado: migração para Proxmox VE 9 concluída com sucesso.

- [x] Configuração ethernet e video E6510:
  - Eth: no E6510, a interface é eno1, não enp5s0
  - Vide0: no arquivo `/etc/default/grub`:
    - GRUB_CMDLINE_LINUX_DEFAULT="quiet i915.modeset=0"
    - GRUB_GFXMODE=1280x800
    - GRUB_GFXPAYLOAD_LINUX=keep
  - `update-grub`
  - `reboot`

- [x] Para iniciar o grafico no Windows e o boot
  - `qm set 102 --cpu host` (host Proxmox)
  - `bootsect /nt60 C: /mbr` (dentro da VM do Windows)

- [x] Cliente Proxmox para VMs, baixar a ISO:
  - https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso
  - VM -> Hardware -> CD/DVD Drive -> virtuo-win.iso
  - VM -> Hardware -> Add -> VirtIO RNG
  - VM -> Options -> habilite QEMU Guest Agent
  - VM -> Console -> Execute no DVD -> guest-agent\qemu-ga-x86_64.msi


---
---
---
---
---
---
---
---
---
---


## 2. Acesso remoto seguro (Tailscale ou WireGuard, administração dos hipervisores e teste de acesso externo. VPN privada, autenticação, controle de acesso). 
- Tomada Inteligente Wi-Fi TP-Link Tapo P110
  - https://www.amazon.com.br/gp/product/B0CPFT8QQK/ref=ox_sc_act_title_1?smid=A3LMEN05VBTH19&psc=1

---
---
---
---
---
---
---
---
---
---

## 3. Active Directory + Linux (Identidade, Segurança)    

### 3.01. Instalar Windows 2025 DC ad.marciolab.test
- [x] VM-DC-01 — Windows Server 2025 Standard	atualizado
- [x] Hostname	VM-DC-01; IP	192.168.1.210
- [x] Domínio AD DS	Instalado e promovido: ad.marciolab.test
  - Windows Server 2016
  - `Install-WindowsFeature RSAT-DFS-Mgmt-Con`
- [x] DNS	Registros LDAP/SRV validados
- [x] Global Catalog	Habilitado
- [x] FSMO	Cinco funções na VM-DC-01
- [x] SYSVOL / NETLOGON	Disponíveis
- [x] DFS Replication
- [x] NTP	Configurado e validado
  - `Set-TimeZone -Id "E. South America Standard Time"`
  - `w32tm /config /manualpeerlist:"a.ntp.br,0x8 b.ntp.br,0x8 c.ntp.br,0x8" /syncfromflags:manual /reliable:yes /update`
* *Importante sobre o DNS: antes da criação da floresta, ainda não existe um servidor DNS do Active Directory. Durante a promoção, instalaremos a função DNS na VM-DC-01 e depois configuraremos seu endereço 192.168.1.210 como resolvedor do próprio domínio, com encaminhadores para consultas externas.*

### 3.02. Instalar Windows 2025 DC sub.ad.marciolab.test

### 3.03. Configurar DNS e sincronização de horário

### 3.04. Testar GPOs 
- Impressoras, WSUS, papel de parede com informações de ip, hostname, Agentes OCS e Zabbix/Grafana

### 3.05. Instalar Ubuntu Server 24.04.5 LTS 
- site: https://ubuntu.com/download/server/thank-you?version=24.04.5&architecture=amd64&lts=true
- Atualizar

### 3.06. Integrar SSSD e PAM ao domínio filho

### 3.07. Configurar SSH e privilégios sudo

### 3.08. Testar ADsys e políticas aplicáveis (GPOs)
- Sudo, RootPW, SSH + Chave Pública
- Grupos Admin Linux no AD
- PAM?

### 3.09. Configurar gestão de patches

### 3.10 Documentar evidências e rollback

---
---
---
---
---
---
---
---
---
---

## 4. OCS Inventory, 5. Zabbix/Grafana, 6. Graylog
- Agentes OCS, Zabbix/Grafana, Graylog
- OCS Campos administrativos
- OCS MySQL admin
- Zabbix/Grafana Dashboards
- Zabbix/Grafana Alertas
- Zabbix/Grafana Monitoramento de Certificados Digitais

### 4.01. Instalar OCS Inventory Server — VM-OCS-01
- [x] VM-OCS-01 — Ubuntu Server 24.04 LTS
  - Hypervisor: Proxmox 02
  - Hostname: `vm-ocs-01`
  - IP: `192.168.1.213`
  - Rede: `192.168.1.0/24`
  - nano /etc/netplan/50-cloud-init.yaml
    - Substituir por:
            network:
             version: 2
             ethernets:
              ens18:
               dhcp4: false
               addresses:
                - 192.168.1.213/24
               routes:
                - to: default
                 via: 192.168.1.1
               nameservers:
                addresses:
                - 186.250.15.1
                - 1.1.1.1
- [x] Sistema operacional instalado e atualizado
  - `apt update`
  - `apt upgrade -y`
- [x] Instalação dos componentes do OCS Inventory

  - PHP e módulos necessários
  - Perl e mod_perl
  - OCS Inventory Server
  - OCS Inventory Reports

  - `sudo apt install -y \
      curl \
      wget \
      git \
      unzip \
      ca-certificates \
      gnupg \
      software-properties-common \
      build-essential`

- [x] MariaDB Server 10.11
  - Database: `ocsweb`
  - Usuário: `ocs`
  - Host: `localhost`
  - Porta: `3306`
  - `sudo apt install -y mariadb-server mariadb-client` 
  - `sudo systemctl enable mariadb`
  - `systemctl status mariadb`
  - `sudo mariadb`
  - `CREATE DATABASE ocsweb
     CHARACTER SET utf8mb4
     COLLATE utf8mb4_unicode_ci;`
  - `CREATE USER 'ocsuser'@'localhost'
     IDENTIFIED BY 'SUA_SENHA_FORTE_AQUI';`
  - `GRANT ALL PRIVILEGES ON ocsweb.*
     TO 'ocsuser'@'localhost';`
  - `SHOW TABLES;`  
  - Resultado: 106 tabelas identificadas.
  - `mariadb -h localhost -u ocs -p ocsweb` 

- [x] Apache HTTP Server
  - `sudo apt install -y apache2`
  - `sudo systemctl enable --now apache2`
  - `apache2 -v`
  - `sudo systemctl status apache2 --no-pager`
  - `curl -I http://127.0.0.1`
  - `http://192.168.1.213/`
  
- [x] PHP 8.3
  - `sudo apt install -y \
   php8.3 \
   libapache2-mod-php8.3 \
   php8.3-cli \
   php8.3-common \
   php8.3-mysql \
   php8.3-gd \
   php8.3-curl \
   php8.3-mbstring \
   php8.3-xml \
   php8.3-zip \
   php8.3-intl \
   php8.3-soap`
  - `php -v`
  - `php -m`
  - `sudo systemctl restart apache2`
  - `sudo systemctl status apache2 --no-pager`
  - `http://192.168.1.213`

- [x] Preparar o Apache para o OCS Inventory 2.12.3 - Módulo Perl
  - `sudo apt update
  sudo apt install -y libapache2-mod-perl2`
  - `sudo a2enmod rewrite
  sudo systemctl restart apache2`
  - `echo "ServerName vm-ocs-01" | sudo tee /etc/apache2/conf-available/servername.conf`
  - `sudo a2enconf servername
  sudo apache2ctl configtest
  sudo systemctl reload apache2`
  - `sudo systemctl status apache2 --no-pager`

- [x] OCS Inventory Server 2.12.3
  - `git ls-remote --tags --refs \
  https://github.com/OCSInventory-NG/OCSInventory-ocsreports.git \
  | awk -F/ '{print $NF}' \
  | sort -V \
  | tail -20`
  - `git ls-remote --tags --refs \
  https://github.com/OCSInventory-NG/OCSInventory-Server.git \
  | awk -F/ '{print $NF}' \
  | sort -V \
  | tail -20`
  - `curl -sS -L \
  https://api.github.com/repos/OCSInventory-NG/OCSInventory-Server-Packages/releases \
  | grep '"tag_name"' \
  | head -20`
  - `curl -sS -L \
  https://api.github.com/repos/OCSInventory-NG/OCSInventory-Server/contents \
  | grep '"name"'`
  - `curl -sS -L \
  https://api.github.com/repos/OCSInventory-NG/OCSInventory-ocsreports/contents?ref=2.12.3 \
  | grep '"name"'`
  - `curl -sSL \
  https://api.github.com/repos/OCSInventory-NG/OCSInventory-Server \
  | grep -E '"default_branch"|"pushed_at"|"archived"'`
  - `curl -sSL \
  https://raw.githubusercontent.com/OCSInventory-NG/OCSInventory-Server/master/INSTALL \
  | head -80`
  - `curl -sSL \
  https://raw.githubusercontent.com/OCSInventory-NG/OCSInventory-Server/master/README.md \
  | head -100`
  - `curl -sSL \
  'https://api.github.com/repos/OCSInventory-NG/OCSInventory-Server/tags?per_page=20' \
  | grep '"name"'`
  - `curl -sSL \
  'https://api.github.com/repos/OCSInventory-NG/OCSInventory-ocsreports/releases/tags/2.12.3' \
  | grep -E '"tag_name"|"name"|"browser_download_url"'`
  - `cd ~/ocs-install`
  - `curl -fL \
  -o OCSNG_UNIX_SERVER-2.12.3.tar.gz \
  https://github.com/OCSInventory-NG/OCSInventory-ocsreports/releases/download/2.12.3/OCSNG_UNIX_SERVER-2.12.3.tar.gz` 
  - `ls -lh OCSNG_UNIX_SERVER-2.12.3.tar.gz`
  - `file OCSNG_UNIX_SERVER-2.12.3.tar.gz`
  - `tar -tzf OCSNG_UNIX_SERVER-2.12.3.tar.gz | head -40`
  - `cd ~/ocs-install`
  - `tar -xzf OCSNG_UNIX_SERVER-2.12.3.tar.gz`
  - `cd OCSNG_UNIX_SERVER-2.12.3`
  - `ls -lah`
  - `cat INSTALL`
  - `find . -maxdepth 2 -type f \
  \( -name 'setup.sh' -o -name 'README*' -o -name 'INSTALL' \) \
  -print`
  - `dpkg -l | grep -E \
'libapache2-mod-perl2|libdbi-perl|libdbd-mariadb-perl|libdbd-mysql-perl|libxml-simple-perl|libnet-ip-perl|libarchive-zip-perl|make|gcc'`
  - `for module in \
  DBI \
  DBD::mysql \
  DBD::MariaDB \
  XML::Simple \
  Net::IP \
  Archive::Zip \
  Apache::DBI
do
  if perl -M"$module" -e 1 2>/dev/null; then
    echo "[OK] $module"
  else
    echo "[AUSENTE] $module"
  fi
done`
  - `sudo systemctl is-active mariadb`
  - `sudo mariadb -e "SELECT VERSION();"`
  - `sudo apt update`
  - `sudo apt install -y \
  libxml-simple-perl \
  libnet-ip-perl \
  libarchive-zip-perl \
  libapache-dbi-perl`
  - `for module in \
  DBI \
  DBD::mysql \
  XML::Simple \
  Net::IP \
  Archive::Zip \
  Apache::DBI
do
  if perl -M"$module" -e 1 2>/dev/null; then
    echo "[OK] $module"
  else
    echo "[AUSENTE] $module"
  fi
done`
 - `php -m | grep -Ei 'curl|gd|mbstring|mysqli|pdo_mysql|xml|zip'`
 - `sudo apache2ctl -M | grep -Ei 'perl|php|rewrite'`
 - `dpkg -l | grep -E '^ii  (php8.3-|libapache2-mod-perl2|libapache2-mod-php8.3)'`
 - `cd ~/ocs-install/OCSNG_UNIX_SERVER-2.12.3`
 - `sudo ./setup.sh`
 - `sudo apt update
sudo apt install -y libmojolicious-perl`
- `perl -MMojolicious::Lite -e 'print "Mojolicious OK\n"'`
- `sudo ./setup.sh`
- `sudo apt install -y libswitch-perl`
- `perl -MSwitch -e 'print "Switch OK\n"'`
- `cd ~/ocs-install/OCSNG_UNIX_SERVER-2.12.3`
- `sudo ./setup.sh`
- `sudo systemctl is-active apache2`
- `sudo systemctl is-active mariadb`
- `sudo apache2ctl -M | grep -Ei 'perl|php|rewrite'`
- `sudo ls -lah /etc/apache2/conf-available/ | grep -i ocs`
- `sudo ls -lah /etc/apache2/conf-enabled/ | grep -i ocs`
- `sudo apache2ctl configtest`
- `sudo a2enconf z-ocsinventory-server`
- `sudo a2enconf ocsinventory-reports`
- `sudo a2enconf zz-ocsinventory-restapi`
- `sudo apache2ctl configtest`
- `sudo systemctl restart apache2`
- `sudo systemctl is-active apache2`
- `ls -lah /etc/apache2/conf-enabled/ | grep -i ocs`
- `perl -MXML::Entities -e 'print "XML::Entities OK\n"'`
- `perl -MSOAP::Transport::HTTP -e 'print "SOAP::Transport::HTTP OK\n"'`
- `apt-cache policy libxml-entities-perl libsoap-lite-perl`
- `sudo apt install -y libsoap-lite-perl`
- `perl -MSOAP::Transport::HTTP -e 'print "SOAP OK\n"'`
- `apt-cache search xml | grep -i entities`
- `apt-cache search libxml | grep perl`
- `sudo apt install -y cpanminus`
- `sudo cpanm XML::Entities`
- `perl -MXML::Entities -e 'print "XML::Entities OK\n"'`
- `sudo apache2ctl configtest`
- `sudo systemctl restart apache2`
- `sudo systemctl is-active apache2`
- `sudo perl -MSOAP::Transport::HTTP -e 'print "SOAP ROOT OK\n"'`
- `sudo -u www-data perl -MSOAP::Transport::HTTP -e 'print "SOAP APACHE OK\n"'`
- `dpkg -l | grep -E 'libsoap-lite-perl|libxml-entities-perl'`
- `sudo tail -n 30 /var/log/apache2/error.log`
- `sudo perl -e '
eval {
    require SOAP::Transport::HTTP;
    SOAP::Transport::HTTP->import();
};
if ($@) {
    print "ERRO: $@\n";
} else {
    print "SOAP carregado corretamente\n";
}
'`
- `sudo grep -Rn -B 8 -A 12 \
"Can't load SOAP::Transport::HTTP" \
/usr/local/share/perl /usr/share/perl5 /etc/ocsinventory-server \
2>/dev/null`
- `sudo grep -Rn -B 8 -A 12 \
"Can't load SOAP::Transport::HTTP" \
/usr/local/share/perl /usr/share/perl5 /etc/ocsinventory-server \
2>/dev/null`
- `sudo perl -e '
eval {
    require SOAP::Transport::HTTP;
    SOAP::Transport::HTTP->import();
};
if ($@) {
    print "ERRO: $@\n";
} else {
    print "SOAP carregado corretamente\n";
}
'`
- `require SOAP::Transport::HTTP2;
our $server = SOAP::Transport::HTTP2::Apache->dispatch_to(...);`
- `SOAP::Transport::HTTP`
- `sudo perl -MSOAP::Transport::HTTP2 -e 'print "SOAP HTTP2 OK\n"'`
- `dpkg -L libsoap-lite-perl | grep -E 'SOAP/Transport/HTTP2?\.pm'`
- `sudo sed -n '15,52p' \
/usr/local/share/perl/5.38.2/Apache/Ocsinventory/SOAP.pm`
- `sudo grep -RnE \
'OCS_MODPERL_VERSION|OCS_OPT_WEB_SERVICE_ENABLED|SOAP' \
/etc/apache2/conf-available/*ocs* \
/etc/ocsinventory-server/ 2>/dev/null`
- `find ~/ocs-install/OCSNG_UNIX_SERVER-2.12.3 \
  -type f \
  \( -iname '*SOAP*' -o -iname '*HTTP2*' \)`
- `sudo sed -n '330,375p' \
/etc/apache2/conf-available/z-ocsinventory-server.conf`
- `sudo cp -a \
/etc/apache2/conf-available/z-ocsinventory-server.conf \
/etc/apache2/conf-available/z-ocsinventory-server.conf.bak`
- `sudo nano /etc/apache2/conf-available/z-ocsinventory-server.conf`
- `sudo apache2ctl configtest`
- `sudo systemctl restart apache2`
- `sudo systemctl is-active apache2`
- `sudo apache2ctl configtest`
- `curl -I http://localhost/ocsreports/`
- `curl -I http://localhost/ocsinventory`
- `http://192.168.1.213/ocsreports/`
- `sudo cat /etc/apache2/conf-available/ocsinventory-reports.conf`
- `sudo ls -lah /usr/share/ocsinventory-reports/`
- `sudo tail -n 30 /var/log/apache2/error.log`
- `sudo find / -type f -name "index.php" 2>/dev/null | grep -Ei 'ocs|reports'`
- `sudo find / -type d -name "ocsreports" 2>/dev/null`
- `sudo ls -ld /etc/apache2/Y /etc/apache2/Y/ocsreports 2>&1`
- `sudo du -sh \
/home/marcio/ocs-install/OCSNG_UNIX_SERVER-2.12.3/ocsreports \
/home/marcio/ocs-install/OCSNG_UNIX_SERVER-2.12.3/Y/ocsreports`
- `sudo ls -lah \
/home/marcio/ocs-install/OCSNG_UNIX_SERVER-2.12.3/ocsreports/`
- `sudo ls -lah \
/home/marcio/ocs-install/OCSNG_UNIX_SERVER-2.12.3/Y/ocsreports/`
- `sudo cp -a \
/home/marcio/ocs-install/OCSNG_UNIX_SERVER-2.12.3/Y/ocsreports \
/var/www/`  
- `sudo ls -lah /var/www/ocsreports/index.php`
- `sudo chown -R www-data:www-data /var/www/ocsreports`
- `sudo find /var/www/ocsreports -type d -exec chmod 755 {} \;`
- `sudo find /var/www/ocsreports -type f -exec chmod 644 {} \;`
- `sudo cp -a \
/etc/apache2/conf-available/ocsinventory-reports.conf \
/etc/apache2/conf-available/ocsinventory-reports.conf.bak`
- `sudo nano /etc/apache2/conf-available/ocsinventory-reports.conf`
Localize: Alias /ocsreports Y/ocsreports
Substitua por: Alias /ocsreports /var/www/ocsreports
Localize: <Directory Y/ocsreports>
Substitua: <Directory /var/www/ocsreports>
- `sudo apache2ctl configtest`
- `sudo systemctl restart apache2`
- `sudo systemctl is-active apache2`
- `http://192.168.1.213/ocsreports/`
- `sudo ls -ld /var/lib/ocsinventory-reports`
- `sudo -u www-data test -w /var/lib/ocsinventory-reports && echo "ESCRITA OK" || echo "SEM PERMISSAO"`
- `sudo chown -R www-data:www-data /var/lib/ocsinventory-reports`
- `sudo mariadb`
- `CREATE DATABASE IF NOT EXISTS ocsweb
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;`
- `CREATE USER IF NOT EXISTS 'ocs'@'localhost'
IDENTIFIED BY 'SUA_SENHA_FORTE_AQUI';`
- `GRANT ALL PRIVILEGES ON ocsweb.* TO 'ocs'@'localhost';`
- Preencher o instalador Web:
  | Campo | Valor |
  |---|---|
  | MySQL login | `ocs` |
  | MySQL password | Senha definida anteriormente |
  | Name of Database | `ocsweb` |
  | MySQL HostName | `localhost` |
  | MySQL Port | `3306` |
  | Enable SSL | `No` |
  | SSL mode | Manter padrão |
  | SSL key path | Vazio |
  | SSL certificat path | Vazio |
  | CA certificat path | Vazio |
- `mariadb -u ocs -p -h localhost ocsweb -e "SELECT DATABASE(), CURRENT_USER();"`
- mysqli_client_ssl
- `sudo mariadb`
- `SELECT User, Host, plugin
FROM mysql.user
WHERE User = 'ocs';`
- `SHOW GRANTS FOR 'ocs'@'localhost';`
- `ALTER USER 'ocs'@'localhost'
IDENTIFIED BY 'SUA_NOVA_SENHA_FORTE';`
- `exit`
- `mariadb -u ocs -p -h localhost ocsweb -e "SELECT DATABASE(), CURRENT_USER();"`
- `sudo tail -n 80 /var/log/apache2/error.log`
- `sudo systemctl is-active mariadb`
- `sudo grep -nE 'OCS_DB_(HOST|NAME|USER|PORT)' \
/etc/apache2/conf-available/z-ocsinventory-server.conf`
- `mariadb -h localhost -u ocs -p ocsweb`
- `sudo grep -nE 'OCS_DB_|OCS_MODPERL_VERSION' \
/etc/apache2/conf-available/z-ocsinventory-server.conf`
- `sudo perl -MDBI -MDBD::mysql -e \
'print "DBI: $DBI::VERSION\nDBD::mysql: $DBD::mysql::VERSION\n"'`
- `sudo perl -MDBI -e '
print "Senha do MariaDB para o usuario ocs: ";
system("stty -echo");
chomp(my $password = <STDIN>);
system("stty echo");
print "\n";

my $dbh = DBI->connect(
    "DBI:mysql:database=ocsweb;host=localhost;port=3306",
    "ocs",
    $password,
    { RaiseError => 0, PrintError => 0 }
);

if ($dbh) {
    print "SUCESSO: Perl conectou ao MariaDB!\n";
    $dbh->disconnect;
} else {
    print "ERRO: " . DBI->errstr . "\n";
}
'`
- `sudo nl -ba \
/usr/local/share/perl/5.38.2/Apache/Ocsinventory/Server/System.pm \
| sed -n '280,345p'`
- `sudo grep -Rn \
'OCS_DB_PWD\|OCS_DB_HOST\|DBI->connect' \
/usr/local/share/perl/5.38.2/Apache/Ocsinventory/Server/`
- `sudo nl -ba \
/usr/local/share/perl/5.38.2/Apache/Ocsinventory/Server/System.pm \
| sed -n '130,245p'`
- `sudo grep -nE 'OCS_OPT_LOG|OCS_OPT_DBI|OCS_DB_' \
/etc/apache2/conf-available/z-ocsinventory-server.conf \
| sed -E 's/(OCS_DB_PWD[[:space:]]+).*/\1[REDACTED]/'`
- `sudo ls -lah /var/log/ocsinventory-server/`
- `sudo find /var/log/ocsinventory-server/ -maxdepth 1 -type f -printf '%f %s bytes\n'`
- `sudo cat /var/log/ocsinventory-server/activity.log`
- `sudo perl -MDBI -e '
use strict;
use warnings;

my $conf = "/etc/apache2/conf-available/z-ocsinventory-server.conf";

open(my $fh, "<", $conf) or die "Erro ao abrir configuracao: $!";

my $password;

while (my $line = <$fh>) {
    if ($line =~ /^\s*PerlSetVar\s+OCS_DB_PWD\s+(.+?)\s*$/) {
        $password = $1;
        $password =~ s/^["\x27]//;
        $password =~ s/["\x27]$//;
        last;
    }
}

close($fh);

die "OCS_DB_PWD nao encontrada\n" unless defined $password;

my $dbh = DBI->connect(
    "DBI:mysql:database=ocsweb;host=localhost;port=3306",
    "ocs",
    $password,
    { RaiseError => 0, PrintError => 0 }
);

if ($dbh) {
    print "SUCESSO: Senha configurada no Apache autentica no MariaDB!\n";
    $dbh->disconnect;
} else {
    print "ERRO: Senha configurada no Apache NAO autentica no MariaDB!\n";
    print "Detalhes: " . DBI->errstr . "\n";
}
'`
- `sudo cp -a \
/etc/apache2/conf-available/z-ocsinventory-server.conf \
/etc/apache2/conf-available/z-ocsinventory-server.conf.bak`
- `sudo nano /etc/apache2/conf-available/z-ocsinventory-server.conf`
- `sudo apache2ctl configtest`
- `sudo systemctl restart apache2`
- `sudo systemctl status apache2 --no-pager`
- `sudo ocsinventory-agent \
--server=http://192.168.1.213/ocsinventory \
--debug`

**Importante:** o OCS Inventory utiliza dois caminhos distintos: `/ocsreports` para administração e `/ocsinventory` para comunicação dos agentes. O erro HTTP 500 identificado durante a implantação foi causado pela autenticação do backend com o MariaDB, e não por falha de conectividade de rede.

### 4.02. Instalar OCS Inventory Agent — Linux

- [x] Instalação do agente na VM-OCS-01
  - `apt update`
  - `apt install ocsinventory-agent`
  - Modo de comunicação selecionado: `http`
  - Servidor de Inventário:
    - http://192.168.1.213/ocsinventory
  - Endpoint utilizado pelos agentes:
    - http://192.168.1.213/ocsreports

- [x] Configuração do servidor OCS
  - Arquivo: `/etc/ocsinventory/ocsinventory-agent.cfg`
  - `server=http://192.168.1.213/ocsinventory`
  - `cat /etc/ocsinventory/ocsinventory-agent.cfg`

- [x] Execução manual do inventário
  - `ocsinventory-agent --server=http://192.168.1.213/ocsinventory --debug`
  - Comunicação com o servidor validada.
  - Inventário enviado com sucesso.

- [x] Automatização da execução do agente
  - Serviço: `ocsinventory-agent.service`
  - Timer: `ocsinventory-agent.timer`
  - `systemctl status ocsinventory-agent.timer --no-pager`
  - `systemctl cat ocsinventory-agent.timer`
  - `systemctl list-timers --all | grep ocsinventory`

- [x] Configuração do timer systemd
  - `OnCalendar=daily`
  - `AccuracySec=1h`
  - `RandomizedDelaySec=240`
  - `Persistent=true`
  - Status: `active (waiting)`
  - Periodicidade: diária, com tolerância de agendamento e atraso aleatório.

- [x] Validação do inventário
  - OCS Inventory → `All Computers`
  - Equipamento `vm-ocs-01` identificado.
  - Informações de hardware e software disponíveis.

- [x] Instalação e validação do agente em uma VM cliente Ubuntu
  - Servidor: `http://192.168.1.213/ocsinventory`
  - Comunicação validada.
  - Inventário recebido pelo OCS Server.

**Importante:** o pacote Linux utiliza um timer do systemd para executar o inventário automaticamente. Com `OnCalendar=daily`, não é necessário criar uma tarefa adicional no cron. A opção `Persistent=true` permite recuperar execuções perdidas enquanto a VM estava desligada.

---

### 4.03. Instalar OCS Inventory Agent — Windows

- [x] Download e instalação do OCS Inventory NG Agent
  - Versão: `2.11.0.1`
  - Arquitetura: `x64`
  - Instalador: `OCS-Windows-Agent-2.11.0.1_x64`

- [x] Configuração do servidor OCS
  - Server URL: `http://192.168.1.213/ocsinventory`
  - User: vazio
  - Password: vazio
  - Validate certificates: desabilitado para conexão HTTP
  - CA Certificate path: não utilizado

- [x] Configuração das opções gerais
  - Enable verbose log: desabilitado
  - Do not scan for installed Software: desabilitado
  - Instalação do agente como serviço do Windows.

- [x] Configuração das opções WMI
  - Behavior of WMI calls: `COMPLETE`
  - Default user domain: vazio

- [x] Execução e validação do agente
  - Instalação concluída.
  - Inventário executado com sucesso.
  - Comunicação com o OCS Server validada.
  - Equipamento Windows identificado em `All Computers`.

**Importante:** a opção `Do not scan for installed Software` deve permanecer desabilitada para permitir o inventário dos softwares instalados. O modo WMI `COMPLETE` permite coletar informações adicionais do sistema e do usuário de domínio, quando disponíveis.

---

### 4.04. Validar OCS Inventory — Servidor e agentes

- [x] Interface administrativa acessível
  - `http://192.168.1.213/ocsreports`

- [x] Endpoint dos agentes operacional
  - `http://192.168.1.213/ocsinventory`

- [x] Banco MariaDB operacional
  - Database: `ocsweb`
  - 106 tabelas identificadas.
  - Autenticação do backend validada.

- [x] Inventário Linux validado
  - VM-OCS-01.
  - Uma VM cliente Ubuntu.

- [x] Inventário Windows validado
  - Uma VM cliente Windows.

- [x] Consulta centralizada de equipamentos
  - OCS Inventory → `All Computers`
  - Três equipamentos inventariados com sucesso.
  - Informações de hardware e software disponíveis.

- [x] Execução automática do agente Linux
  - Timer systemd habilitado.
  - Periodicidade diária configurada.

- [x] Troubleshooting concluído
  - Erro HTTP 500 corrigido.
  - Autenticação Apache/Perl/MariaDB validada.
  - Comunicação dos agentes operacional.

- [ ] Expandir a instalação dos agentes para as demais VMs Linux e Windows.
- [ ] Padronizar TAGs dos equipamentos.
- [ ] Criar campos administrativos.
- [ ] Configurar filtros e relatórios.
- [ ] Configurar backup do MariaDB e da VM.
- [ ] Implementar HTTPS e validação de certificados.
- [ ] Revisar usuários e permissões administrativas.

**Resultado:** OCS Inventory Server instalado e operacional na VM-OCS-01 (`192.168.1.213`), com inventário centralizado de equipamentos Linux e Windows. Implantação básica concluída e validada.

**Próxima etapa:** expansão do inventário e configuração dos recursos administrativos do OCS Inventory.

---
---
---
---
---
---
---
---
---
---