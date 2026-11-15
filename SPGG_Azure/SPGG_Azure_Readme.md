---
---
---
---
---

01. Tenant e governança
- [x] Hierarquia, 
- [x] subscriptions, 
- [-] permissões e responsabilidades
02. Subscriptions e Resource Groups
- [ ] Organização dos recursos, 
- [ ] finalidades e separação de ambientes
03. Infraestrutura e conectividade
- [ ] VNets, 
- [ ] sub-redes, 
- [ ] gateways, 
- [ ] segurança, 
- [ ] VMs
- [ ] AKS
04. Plataforma e aplicações
- [ ] Sistemas, 
- [ ] serviços compartilhados, 
- [ ] bancos de dados
- [ ] integrações
05. Operação e otimização
- [ ] Monitoramento, 
- [ ] disponibilidade, 
- [ ] custos
- [ ] melhorias
06. Anexos técnicos
- [ ] .

---
---
---
---
---

# 01. Tenant e governança
- Tenant: Microsoft Entra ID - Governo do Estado do Rio Grande do Sul
- Tenant Root Group: Management Groups
- Subscriptions
  - SQUADS RS
  - IntegraRS
- Resource Groups
- Recursos Azure

# 02. Subscriptions e Resource Groups
- Subscription SQUADS RS
  - Resource Groups: 18
  - Ambientes identificados por nomenclatura: 
    - dev-squads
    - sit-squads
    - uat-squads
    - prod-squads
  - Infra gerenciada pelo AKS
    - MC_dev-squads_dev-squads-cluster_brazilsouth
    - MC_sit-squads_sit-squads-k8s_brazilsouth
    - MC_uat-squads_uat-squads-k8s_brazilsouth
    - MC_prod-squads_prod-squads-k8s_brazilsouth
    - OBS: MC_ for Managed Cluster
  - Serviços compartilhados e observabilidade
    - sharedservices-squads
    - LogAnalyticsDefaultResources
    - MA_defaultazuremonitorworkspace-cq_brazilsouth_managed
    - MA_sharedservices-squads-prometheus_brazilsouth_managed
    - NetworkWatcherRG
  - Outros Resource Groups
    - db-squads
    - DefaultResourceGroup-CQ
    - rg-Ai-FinOps
    - SPGG
    - VisualStudioOnline-9B12AFC22344403BA2AECD28E49EA9E0
- Subscription IntegraRS
  - Resource Groups: 12
  - Resource Group: prod-integra
    - Serviços:
      - API Management (Publicar, proteger e gerenciar APIs)
      - Virtual Network (Organizar a conectividade privada entre recursos)
      - Application Gateway /WAF (Distribuir e encaminhar tráfego HTTP/HTTPS / Proteger aplicações web contra determinadas ameaças)
      - Key Vault (Armazenar e controlar o acesso a segredos, chaves e certificados)
    - Recursos:
      



           Tabelas:
           | Camada | Recursos Encontrados | Função |
           |-----------|-----------|-----------|
           |  Valor 1 | Valor 2 |     |



- Subscription SQUADS RS
  - Serviços identificados
    - AKS, VMs, VMSS, PostgreSQL, ACR, redes e monitoramento
  - 4 clusters AKS
  - 9 VMs
  - 6 recursos Scale Sets
- Subscription IntegraRS
  - Resource Groups
  - Serviços identificados
    - API Management, Application Gateway/WAF, Bastion, Key Vault, Logic Apps e DNS privado

- Subscription SQUAD RS
 - AKS
   - dev-squads-cluster
     - Aplicações 
       - Backends e frontends
         - code: backend e frontend.
         - acl: backend e server-backend.
         - psrs: backend e frontend.
         - familiagaucha: backend, frontend e worker.
         - professor-amanha: backend e frontend.
         - irga e irrigamais: diferentes componentes.
         - ciptometro, sispim, ped e outros.
         - ?cx-spgg e cert-manager (Gerenciamento de certificados TLS).?
     - Dados e Serviços
       - Redis (Cache e armazenamento temporário de dados) 
       - RabbitMQ (Mensageria entre aplicações)
       - Redpanda (Plataforma de streaming de eventos)
     - Plataforma 
       - Ingress, Istio, DNS
     - Operação
       - Argo CD (Entrega e sincronização de aplicações via GitOps)
       - Monitoramento (Azure Monitor, Container Insights e métricas Prometheus)

Exemplo do code-backend:
- AKS: dev-squads-cluster
- Namespace: code
- Deployment: code-backend
- ReplicaSet
- Pod
- Contêiner: code-backend


# 03. Infraestrutura e conectividade

# 04. Plataforma e aplicações

# 05. Operação e otimização

# 06.Anexos técnicos










