---
---
---
---
---
# Markdown
---

# Title goes here

_A short description of what this document is about._

---

## Overview

Briefly explain the purpose of this document. What problem does it address? Who is it for?

## Key Points

- Point one
- Point two
- Point three

_Last updated: YYYY-MM-DD_

# Título Principal
## Subtítulo
### Seção
#### Subseção
##### Subseção 2
###### Subseção 3

Texto normal.

**Negrito**
*Itálico*
***Ambos***
~~Riscado~~

- Lista Item
- Lista Item
  - Lista Subitem

1. Lista ordenada Primeiro
2. Lista ordenada Segundo

2 linhas em branco
<br><br>

[Site](https://site.com)

[Google](https://www.google.com)

Imagem.png

docs/arquitetura.png

https://site.com/foto.jpg

Use o comando `código em linha`.

Bloco de código
```python
print("Olá")
```

Citações
> Citação

Tabelas:
| Coluna A | Coluna B |
|-----------|-----------|
| Valor 1 | Valor 2 |

Checklists
- [x] Feito
- [ ] A fazer

Título e Linha horizontal
---

Linha horizontal

---
---
---
---
---
# VS Code
VS Code Extensions:
- PowerShell
- Draw.io (AS-IS.drawio.svg )
- Mermaid (Markdown Preview Ctrl+Shift+V ou Ctrl+K V) 
- 
Atalhos:
- Ctrl+F = Find 
- Ctrl+Shift+F = Find global 
- Ctrl+P = arquivo para abrir 
- Ctrl+Shift+P = abre a palheta de comandos 
- Ctrl+K+C = Comentar 
- Ctrl+K+U = Descomentar 
- Ctrl+. = Comentar/Descomentar 
- Ctrl+Shift+V 
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

# Git+GitHub Notes

**Instalação**
- git --version
- gh --version
- winget install --id GitHub.cli
- gh --version
- git config --global user.name
- git config --global user.email
- git config --global init.defaultBranch
- git config --global user.name "Marcio Izaquiel de Oliveira"
- git config --global user.email "309544935+MarcioIzaquiel@users.noreply. github.com"
- git config --global init.defaultBranch main
- git config --global --list
- gh auth login
- cd "$HOME\OneDrive\MarcioOliveira\Studies\AZURE"
- mkdir azure-platform-bootstrap
- cd azure-platform-bootstrap
- git init
- code .
- gh repo create azure-platform-bootstrap --public --source=. --remote=origin --push
- git remote -v
- gh auth status
- gh repo clone MarcioIzaquiel/azure-platform-bootstrap

**Sequência rápida:**

Antes:
`git status` -> `git fetch` -> `git status` -> `git pull`

Editar/Salvar -> `git status` -> `git diff` -> `q` 

Commit: `git add nomedoarquivo.ext` -> `git status` -> `git commit -m "docs: descrição alteração"`

Enviar: `git push` -> `git status`


---


Alterações, partindo do notebook, depois: 

Editar ; `git status` ; `git diff`; q ; `git add Readme.md` ; `git status` ; `git commit -m "docs: update README"` ; `git push` ; 

Alterações feitas no GitHub, para passar para o notebook:
Editar ; `git pull`

Verificar histórico de alterações e rollback de versão:
`git diff` ; `git diff Readme.md` ; `git log --oneline` ; `git log --oneline -- Readme.md` ; `git show iddaalteração` ; `git restore --source=iddaalteração Readme.md` ; `git status` ; `git diff` ; `git add Readme.md` ; `git commit -m "docs: restore previous README version"` ; `git push` 

Excluir arquivos
Excluir via Windows ; `git status` ; `git add .` ; `git commit -m "chore: remove obsolete test file"` ; `git push` ; `

Criar arquivos e subpastas:
Criar arquivos/subpastas via Windows (\docs\architecture.md) ; `git status` ; `git add docs` ; `git commit -m "docs: add architecture documentation"` ; `git push`

O Git não rastreia diretórios vazios, então:
Criar subpasta ; criar arquivo .gitkeep


---


Nomenclatura para Commit:

| Prefixo | Significado | Exemplo |
|---------|-------------|---------|
| docs: | Documentação | docs: update README |
| feat: | Nova funcionalidade/recurso | feat: add resource group deployment |
| fix: | Correção | fix: correct resource group naming |
| refactor: | Reorganização sem mudar a finalidade | refactor: reorganize terraform modules | 
| chore: | Manutenção/organização do projeto | chore: create repository structure |
| test: | Testes | test: validate policy assignment |
| ci: | Pipeline/automação de integração | ci: add GitHub Actions validation |
| build: | Build/dependências | menos importante por enquanto |


---
---
---
---
---
---

# Azure Platform Bootstrap

Personal Azure platform engineering lab used to design, implement, document, and automate a governed Azure environment.

## Purpose

This repository documents the bootstrap of my personal Azure platform and serves as the foundation for my Azure Infrastructure & Platform Engineering learning path.

## Projects

The platform will support the following projects:

- Azure Learning Lab
- Cloud Resume Challenge
- Finance Project
- SPGG Lab

## Evolution

The environment is being developed incrementally:

Portal -> Azure CLI / PowerShell -> Bicep -> Terraform

# Current environment

- Microsoft Account (MSA): e-mail pessoal
- Microsoft Entra ID
- Apenas 1 Directory: 
- Tenant name: Default Directory 
- Tenant ID: 
- Primary domain: marcioizaquieloutlook.onmicrosoft.com 
- Tenant type: License:  Microsoft Entra ID Free 
- User name: Marcio Izaquiel de Oliveira 
- User UPN: marcioizaquiel_outlook.com#EXT#@marcioizaquieloutlook.onmicrosoft.com  
- Management Group: MG-MarcioLab
- Subscription: SUB-MarcioLab
- Subscription ID: 
- Subscription Plan: Azure Plan
- Subscription Parent management group: MG-MarcioLab
- Cost Management and Budget
- Billing account: Marcio Izaquiel de Oliveira
- Billing profile: Marcio Izaquiel de Oliveira
- Billing scope: Marcio Izaquiel de Oliveira
- Credit remaining:
- Credit expiration:
- Spending limit/protection:
- Billing currency:
- RBAC: 
- Azure Policy:
- Resource Providers:
- Resource Groups:
- Naming Convention:
- Tagging Strategy:

Microsoft Entra Tenant: Marcioizaquiel 
- IDENTITY / MICROSOFT CLOUD 
  - Entra ID 
  - Users 
  - Groups 
    - GRP-AZ-MarcioLab-Readers
  - Dispositivos  
  - Enterprise Applications 
  - Intune [quando aplicável] 
  - Funções
  - Autenticação
AZURE 
- Tenant Root Group 
  - MG-MarcioLab 
    - SUB-MarcioLab 
      - RG-CRC-DEV 
      - RG-CRC-PROD 
      - RG-FIN-DEV 
      - RG-FIN-PROD 
      - RG-SPGG-DEV 
      - RG-SPGG-PROD 
      - RG-AZLAB-LAB 
      - Cost Management > Budget > BUD-MarcioLab-Monthly
  - RBAC (Azure role-based access control) : 
    - Marcio → Owner 
    - GRP-AZ-MarcioLab-Readers → Reader 
  - Azure Policy: 
    - MarcioLab - Tag Governance v1.0
      - Definition ; Initiative ; Assignment ; Compliance ; 
      - Effect: **Audit**, Deny, Modify, Append, DeployIfNotExists 

---
---
---
---
---

# GOV: Name Convention: 

TIPO-PROJETO-AMBIENTE-REGIAO-INSTANCIA

| Nome | Opção |  
|-----------|--------------------------|
| **Tipo:** | RG, VM, VNET, NSG, KV... |
| **Projeto:** | CRC, FIN, SPGG, AZLAB |
| **Ambiente:** | LAB, DEV, PROD |
| **Região:** | BRS, EUS, WEU... |
| **Instância:** | 001, 002, 003... |
| **Management Group:** | MG-MarcioLab |
| **Subscription:** | SUB-MarcioLab |
| **Resource Group:** | RG-CRC-DEV ; RG-FIN-DEV ; RG-SPGG-DEV ; RG-AZURELAB |
| **Virtual Network:** | VNET-CRC-DEV-BRS-001 |
| **Subnet:** | SNET-WEB-001 |
| **Network Security Group:** | NSG-WEB-DEV-001 |
| **Virtual Machine:** | VM-AZLAB-DEV-BRS-001 |
| **Key Vault:** | KV-CRC-DEV-001 |
| **Log Analytics Workspace:** | LAW-MarcioLab-BRS |
| **Storage Account:** | stcrcdev001 |
 

---
---
---
---
---

# GOV: Tagging Strategy

| TAG | Opção |
|-----|----------------------------|
| Environment | Lab , Dev , Prod |
| Owner | Marcio |
| Project |  Azlab , CRC , FIN , SPGG-Lab |
| CostCenter | Learning | 
| ManagedBy | Manual , Terraform , Bicep |
| Lifecycle | Temporary , Persistent | 


---
---
---
---
---
---

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
10. [ ] Validar Policy / RBAC / Cost
11. [ ] Documentar no GitHub
12. [ ] Observar custo real
13. [ ] Teardown
14. [ ] Encerramento da Fase 0


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

*stazlablabbrs001 = st(Storage Account), azlab(projeto), lab(ambiente), brs(BrazilSouth), 001(instancia)

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


## Diferença entre Worload sugerido primeiro (sem storage):

- Workload inicial sugerido 1:
  - Azure Static Web Apps

- Workload Realizado:
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
10. Verificar Policy / RBAC / Metrics (tags, budget, audit)        
11. Verificar Cost Management        
12. Documentar no GitHub

