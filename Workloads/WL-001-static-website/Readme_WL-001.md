
# Worload 001: Storage Static Website

WORKLOAD 001 — Storage Static Website

1. [x] Definição do workload. 
2. [x] Arquitetura
3. [x] Naming + Tags
4. [x] Estimativa de custo (antes de criar recursos)
5. [x] Cost Gate: GO / NO-GO
6. [x] Deployment pelo Portal
7. [x] Configurar Static Website
8. [x] Publicar index.html / 404.html
9. [x] Testes
10. [x] Validar Policy / RBAC / Cost
11. [x] Documentar no GitHub
12. [x] Observar custo real
13. [x] Teardown
    - [x] Inventariar recurso antes da exclusão
    - [x] Executar teardown
    - [ ] Confirmar remoção
    - [ ] Confirmar ausência de custo residual
14. [x] Decisão: manter WL-001 ativo para laboratório
15. [x] Encerramento da Fase 0


### 1. Definição do Workload 001

- Workload ID:      WL-001
- Name:             Storage Static Website
- Project:          AZLAB
- Environment:      LAB
- Region:           East US
- Purpose:          Validate the Azure Platform Bootstrap
- Lifecycle:        Temporary
- Deployment:       Manual / Azure Portal

### 2. Arquitetura Workload 001

Internet -> HTTPS -> Azure Storage Static Website Endpoint -> Storage Account

Tenant Root Group
- MG-MarcioLab
  - SUB-MarcioLab
    - RG-AZLAB-LAB
      - Storage Account (stazlablabeus001)
        - Blob Service
          - $Web
            - index.html
            - 404.html
            - outros arquivos do site (CSS, JS, Imagens)
        - Static Website

*stazlablabeus001 = st(Storage Account), azlab(projeto), lab(ambiente), brs(BrazilSouth), 001(instancia)

### 3. e 4. Gov e Cost Gate

Tag:
- Env: Lab
- Owner: Marcio
- Project: Azlab
- CostCenter: Learning
- ManagedBy: Manual
- Lifecycle: Temporary

Azure Policy: MarcioLab - Tag Governance v1.0 (Effect: Audit; Scope: MG-MarcioLab)

RBAC: Permissões

Storage Account:
- Region: ~~Brazil South~~ East US
- Performance: Standard
- Redundancy: LRS
- Account type: StorageV2 / GPv2
- Access tier: Hot
- Capacity: ~0.01 GB ou menos
- Traffic: mínimo
- Transactions: mínimo
- Static Website: Enabled
- CDN: Não
- Custom domain: Não

Azure Cost Management (Estimado e Realizado):
- Resource
- Resource Group
- Project = Azlab
- CostCenter = Learning

Azure Pricing Calculator (https://azure.microsoft.com/en-gb/pricing/calculator/):


## Diferença entre Workload sugerido primeiro (sem storage):

- Workload inicial sugerido 1:
  - Azure Static Web Apps

- Workload Realizado WL-001:
  - Web Endpoint
  - Storage Account
    - Static Website
    - Block Blob Storage
  - Azure Monitor / Metrics
  - Cost Management

## Deploy do WL-001

1. [x] Definir arquitetura
2. [x] Definir naming
3. [x] Definir tags
4. [x] Criar Resource Group        
5. [x] Criar Storage Account        
    - stazlablabeus001
      - Static Website        
        - https://stazlablabeus001.z13.web.core.windows.net/
        - $web
          - index.html
          - 404.html
6. [x] Habilitar Static Website        
7. [x] Criar index.html / 404.html        
8. [x] Publicar        
9. [x] Testar endpoint        
10. Verificar Policy (tags) / RBAC / Metrics (budget, audit)
    - [x] stazlablabeus001 -> Tags
    - [x] RBAC
    - [x] Metrics
      - stazlablabeus001 → Monitoring → Metrics (transaction)  
11. [x] Verificar Cost Management
    - SUB-MarcioLab -> Resources -> Cost Management -> Cost Analysis 
12. [x] Testar suspensão do workload
    - Desabilitar Static Website
      - Storage Account stazlablabeus001 -> Data management -> Static website -> Disabled    
13. [x] Testar reativação do workload
    - Habilitar Static Website
    - Storage Account stazlablabeus001 -> Data management -> Static website -> Enabled               
14. [x] Documentar no GitHub

### Sugestão de WL-002 (Futuro)

WL-002 — Azure Static Web Apps (+GitHub Actions e sem storage)
1. [ ] Definir arquitetura
2. [ ] Definir naming/tags
3. [ ] Estimar custo
4. [ ] Cost Gate
5. [ ] Criar aplicação HTML
6. [ ] Criar/usar repositório GitHub
7. [ ] Criar Azure Static Web App
8. [ ] Conectar GitHub
9. [ ] Selecionar branch main
10. [ ] Configurar diretório da aplicação
11. [ ] Azure criar workflow GitHub Actions
12. [ ] Primeiro deployment
13. [ ] Testar endpoint
14. [ ] Alterar index.html
15. [ ] git add / commit / push
16. [ ] Observar deployment automático
17. [ ] Validar Policy / RBAC
18. [ ] Monitoramento
19. [ ] Cost Management
20. [ ] Documentar
