
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
4. [ ] Inventariar hardware e licenciamento
5. [ ] Estimar custos locais e Azure 
6. [ ] Registrar Cost Gate GO / NO-GO 

### 1. Fundação local, infraestrutura local 
1. [ ] Validar hardware, BIOS, e virtualização 
2. [ ] Preparar SSD do Vostro e E6510
3. [ ] Instalar e configurar Proxmox 01 
4. [ ] Instalar e configurar Proxmox 02 
5. [ ] Definir redes e isolamento do laboratório 
6. [ ] Configurar backups e snapshots 
7. [ ] Validar acesso remoto seguro 

### 2. Acesso remoto seguro (Tailscale ou WireGuard, administração dos hipervisores e teste de acesso externo. VPN privada, autenticação, controle de acesso). 
1. [ ] Testar acesso fora da LAN 
2. [ ] Testar ligar/desligar VMs remotamente 
3. [ ] Testar Wake-on-LAN dos hosts 
Entrega: acesso seguro de uma rede externa, sem publicar interfaces administrativas na Internet. 

### 3. Active Directory + Linux (Identidade, Segurança)    
1. [ ] Criar domínio raiz  
2. [ ] Criar domínio filho 
3. [ ] Configurar DNS e sincronização de horário 
4. [ ] Instalar Linux cliente de teste 
5. [ ] Integrar SSSD e PAM ao domínio filho 
6. [ ] Configurar SSH e privilégios sudo 
7. [ ] Testar ADsys e políticas aplicáveis (GPOs) 
8. [ ] Configurar gestão de patches 
9. [ ] Documentar evidências e rollback 
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

### 6. Syslog (opcional) Centralização de logs, correlação básica e retenção. 
- rsyslog/syslog-ng, retenção, consultas e encaminhamento de eventos. Ferramenta usada pelo SPGG é Graylog. 
1. [ ] Avaliar servidor Syslog 
2. [ ] Validar centralização e retenção de logs 
3. Entrega: logs Linux centralizados e pesquisáveis. 

### 7. Integração Azure    
1. [ ] Verificar Azure Policy e RBAC 
2. [ ] Criar RG somente quando necessário 
3. [ ] Verificar custos antes de cada serviço 
4. [ ] Testar integração híbrida de identidade (Entra ID, sincronização híbrida, Microsoft Entra Connect Sync ou Cloud Sync) 
5. [ ] Avaliar Azure Arc 
6. [ ] Azure Monitor, Log Analytics, Azure Update Manager 
7. [ ] Testar Key Vault e certificados 
8. [ ] Avaliar Intune e inscrição do iPad (MDM) 
9. [ ] Comparar alternativas de VPN e acesso híbrido 
10. [ ] Verificar Cost Management e métricas 
- Entrega: dispositivo de testes gerenciado, conforme licenciamento disponível 
- Entrega: prova de conceito de gestão híbrida com custos controlados. 

### 8. Validação operacional    
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

### 1. Definir objetivos, escopo e critérios de aceite 

#### Construção do AS IS, para simular a SPGG hoje: 
- AD de dominio principal (intra.rs.gov.br) e um subsdominio (spgg.intra.rs.gov.br), simulando o serviço de AD (ADS) prestado pela PROCERGS a SPGG. Sugestão de dominio: ad.marciolab.test e sub.ad.marciolab.test 
- Os servidores linux despadronizados, quanto ao acesso e segurança e as ferramentas, como OCS Inventory, Zabbix/Grafana (e se der tempo e espaço, o Syslog(Graylog)).  
- Essas VMs serão distribuídas nos XPS502l 16GB e Vostro v131 8GB com Promox. Também podemos usar ocasionalmente, na memoria que sobra do uso normal, o E6510 Lubuntu (KVM + QEMU + Virt-Manager) 8GB e o Thinkpad E14 Windows 11 Pro + VirtualBox 16GB (notebook pessoal) 
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

### 2. Definir arquitetura lógica e física 

#### Laboratorio SOHO local: 
- E6510: 8GB, 120GB SSD, Lubuntu Administração + (KVM + QEMU + Virt-Manager)
- XPS l502x: 16GB, 447GB SSD, Proxmox 01
- Vostro V131: 8GB, 240GB SSD, Proxmox 02
- Thinkpad E14: 16GB, 473GB SSD, Windows 11 Pro (note pessoal) + administração e VirtualBox
- iPAD 10 pessoal 
- Azure subscription usada na trilha de aprendizagem 

#### Setup:
##### XPS L502x: Proxmox 01
- Hostname/IP: XPS, 192.168.1.201 (192.168.1.123)
- Hosts de VMs:
  - VM ?
  - VM ?
  - VM ?
##### Vostro v131: Proxmox 02
- Hostname/IP: Vostro, 192.168.1.202 (192.168.1.114)
- Hosts de VMs:
  - VM ?
  - VM ?
  - https://www.youtube.com/watch?v=iYBMLHyTGPg
##### E6510: Lubuntu + (KVM + QEMU + Virt-Manager)
- Hostname/IP: E6510, DHCP
- Administração
- Host de VMs:
  - VM ?
##### iPad geração 10
- Administração e operação do ambiente e testes de MDM
##### VMs
- VM AD root ad.marciolab.test, IP: 192.168.1.205
- VM AD subdomain sub.ad.marciolab.test, IP: 192.168.1.206
- VM OCS Inventory, IP: 192.168.1.207
- VM Zabbix/Grafana, IP: 192.168.1.208
- VM Graylog/Syslog, IP: 192.168.1.209
- VM Linux para SSSD/PAM/ADsys, IP: 192.168.1.210
##### Azure subscription 

### 3. Definir naming e tags 

#### Naming convention e tags para VMs:
##### TIPO-PROJETO-AMBIENTE-REGIAO-INSTANCIA
- Promox 1: pve-spgg-lab-01 = XPS
- Promox 2: pve-spgg-lab-02 = Vostro
- DC principal: vm-dc-01
- DC sub: vm-dc-02
- VM Linux: vm-lin-01
- VM Windows: vm-win-01
- VM OCS: vm-ocs-01
- VM Zabbix/Grafana: vm-zbx-01
- VM Syslog: vm-syslog-01
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

### 4. Inventariar hardware e licenciamento

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

# Instalar Debian 12 -> Proxmox 8 -> Proxmox 9

## XPS -> Debian 12 -> Proxmox 8 -> Proxmox 9

- [x] Instalação mínima do Debian 12
  - `systemctl poweroff`
  - `su -`
- [x] Configuração dos repositórios Debian
  - `cat /etc/apt/sources.list`
  - `ls -l /etc/apt/sources.list.d/`
  - `nano /etc/apt/sources.list`
    - # cdrom
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
- [ ] Verificação de compatibilidade pve8to9
- [ ] Migração para Proxmox VE 9


# Instalar Windows 2025 DC ad.marciolab.test server core

# Instalar Windows 2025 DC sub.ad.marciolab.test server core

# Instalar Ubuntu Server 24.04.5 LTS 
https://ubuntu.com/download/server/thank-you?version=24.04.5&architecture=amd64&lts=true

