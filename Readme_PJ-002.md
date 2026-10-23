
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
1. [ ] Definir objetivos, escopo e critérios de aceite 
2. [ ] Definir arquitetura lógica e física 
3. [ ] Definir naming e tags 
4. [ ] Inventariar hardware e licenciamento 
5. [ ] Estimar custos locais e Azure 
6. [ ] Registrar Cost Gate GO / NO-GO 

### 1. Fundação local, infraestrutura local 
1. [ ] Validar hardware, BIOS, e virtualização 
2. [ ] Preparar SSD do Vostro 
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

### 3. Active Directory + Linux (Identidade, Arc, Monitoramento, Segurança)    
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

### 2. Definir arquitetura lógica e física 
#### Laboratorio SOHO local: 
- E6510: 8GB, 240GB SSD, Lubuntu Administração + (KVM + QEMU + Virt-Manager)
- XPS l502x: 16GB, 447GB SSD, Proxmox 01
- Vostro V131: 8GB, 240GB SSD, Proxmox 02
- Thinkpad E14: 16GB, 473GB SSD, Windows 11 Pro (note pessoal) + administração e VirtualBox
- iPAD 10 pessoal 
- Azure subscription usada na trilha de aprendizagem 

#### Setup:
##### XPS L502x: Proxmox 01
- Hostname, IP:
- Hosts de VMs:
  - VM ?
  - VM ?
##### Vostro v131: Proxmox 02
- Hostname, IP:
- Hosts de VMs:
  - VM ?
  - VM ?
  - https://www.youtube.com/watch?v=iYBMLHyTGPg
##### E6510: Lubuntu + (KVM + QEMU + Virt-Manager)
- Hostname, IP: E6510, DHCP
- Administração
- Host de VMs:
  - VM ?