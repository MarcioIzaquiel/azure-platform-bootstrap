# Azure Platform Bootstrap

Personal Azure platform engineering lab used to design, implement, document, and automate a governed Azure environment.

## Purpose

This repository documents the bootstrap of my personal Azure platform and serves as the foundation for my Azure Infrastructure & Platform Engineering learning path.

## Current environment

- Microsoft Entra ID
- Management Group: MG-MarcioLab
- Subscription: SUB-MarcioLab
- Cost Management and Budget
- RBAC
- Azure Policy
- Resource Providers
- Resource Groups
- Naming Convention
- Tagging Strategy

## Projects

The platform will support the following projects:

- Azure Learning Lab
- Cloud Resume Challenge
- Finance Project
- SPGG Lab

## Evolution

The environment is being developed incrementally:

Portal -> Azure CLI / PowerShell -> Bicep -> Terraform

---
---
---
**Markdown Notes**
---
---
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
Subscription name: Azure subscription 1

Subscription ID: 648516db-b4cc-4b09-8ee0-bde2c80ccd36

My role: Owner

Status: Active

Current cost: -

Offer / Plan, se aparecer: Azure Plan

Parent management group: 1f2a2423-d5f2-4a59-908f-c9189962f533

---

Billing account: Marcio Izaquiel de Oliveira

Billing profile: Marcio Izaquiel de Oliveira (ID: AAD2-5QHJ-BG7-PGB)

Billing scope: Marcio Izaquiel de Oliveira

Offer:

Credit remaining:

Credit expiration:

Spending limit/protection:

Billing currency:

---

Name Convention: TIPO-PROJETO-DEV-BRS-001

Tipo: RG, VM, VNET, NSG, KV...

Projeto: CRC, FIN, SPGG, AZLAB

Ambiente: LAB, DEV, PROD

Região: BRS, EUS, WEU...

Instância: 001, 002, 003...

Management Group:
MG-MarcioLab

Subscription:
SUB-MarcioLab

Resource Group:
RG-CRC-DEV
RG-FIN-DEV
RG-SPGG-DEV
RG-AZURELAB

Virtual Network:
VNET-CRC-DEV-BRS-001

Subnet:
SNET-WEB-001

Network Security Group:
NSG-WEB-DEV-001

Virtual Machine:
VM-AZLAB-DEV-BRS-001

Key Vault:
KV-CRC-DEV-001

Log Analytics Workspace:
LAW-MarcioLab-BRS

Storage Account:
stcrcdev001 
<br><br>
Tipo: RG, VM, VNET, NSG, KV...
Projeto: CRC, FIN, SPGG, AZLAB
Ambiente: LAB, DEV, PROD
Região: BRS, EUS, WEU...
Instância: 001, 002, 003...

---
---
---
---
---
# Git+GitHub Notes
Exemplo: arquivo Readme.md

Alterações, partindo do notebook, depois: 

Editar ; `git status` ; `git diff`; q ; `git add Readme.md` ; `git status` ; `git commit -m "docs: update README"` ; `git push` ; 

Alterações feitas no GitHub, para passar para o notebook:
Editar ; `git pull`

Verificar histórico de alterações e rollback de versão:
`git diff` ; `git diff Readme.md` ; `git log --oneline` ; `git log --oneline --Readme.md` ; `git show iddaalteração` ; `git restore --source=iddaalteração Readme.md` ; `git status` ; `git diff` ; `git add Readme.md` ; `git commit -m "docs: restore previous README version"` ; `git push` 

Excluir arquivos
Excluir via Windows ; `git status` ; `git add .` ; `git commit -m "chore: remove obsolete test file"` ; `git push` ; `

Criar arquivos e subpastas:
Criar arquivos/subpastas via Windows (\docs\architecture.md) ; `git status` ; `git add docs` ; `git commit -m "add architecture documentation"` ; `git push`

O Git não rastreia diretórios vazios, então:
Criar subpasta ; criar arquivo .gitkeep



