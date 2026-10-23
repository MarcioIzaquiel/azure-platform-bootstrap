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

**Nomenclatura para Commit:**

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
---
---
---
---

# Linux

`ip a` = ifconfig

`sudo ss -tlnp | grep ':22'` verificar se o servidor está com a 22 aberta (no próprio servidor)

`Test-NetConnection 192.168.1.120 -Port 22` no PowerShell a partir do Windows 11

No VS Code, instalar o Remote - SSH, da Microsoft.
`ssh -V` no PowerShell do VS Code
1. Pressione Ctrl + Shift + P.
2. Digite Remote-SSH: Add New SSH Host.
3. Informe o comando abaixo, substituindo pelo usuário e IP com os quais você já acessa pelo PuTTY: `ssh usuario@192.168.1.120 -p 22`

`sed -i 's/\r$//' ~/meu_script.sh` limpar o script de \r (quando feito no Windows)

### Editor VI
- vi meu_script.sh
- (:set paste)
- i
- esc
- (:set nopaste)
- :wq

`chmod +x meu_script.sh` dar permissão no script
`bash -n SPGG_Linux.sh` verificar a sintaxe dos os comandos
`./meu_script.sh`

### Execução remota via VS Code
- `scp .\SPGG_Linux\SPGG_Linux.sh marcio@192.168.0.46:~/SPGG_Linux.sh`
- `ssh -tt marcio@192.168.0.46 "cd ~ && bash ./SPGG_Linux.sh"`
- `scp marcio@192.168.0.46:~/20261011_ubuntuserver_SPGG_Linux.txt .\SPGG_Linux`

- `Unblock-File .\Invoke-SPGG_RootPW_v1.3.ps1`
- `.\Invoke-SPGG_Linux.ps1 -Usuario marcio`

https://www.microsoft.com/en-us/evalcenter/download-windows-server-2025

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
  - RBAC (Azure role-based access control) : 
    - Marcio → Owner 
    - GRP-AZ-MarcioLab-Readers → Reader 
  - Azure Policy: 
    - MarcioLab - Tag Governance v1.0
      - Definition ; Initiative ; Assignment ; Compliance ; 
      - Effect: **Audit**, Deny, Modify, Append, DeployIfNotExists 
  - MG-MarcioLab 
    - SUB-MarcioLab 
      - RG-CRC-DEV 
      - RG-CRC-PROD 
      - RG-FIN-DEV 
      - RG-FIN-PROD 
      - RG-SPGG-DEV 
      - RG-SPGG-PROD 
      - RG-AZLAB-LAB 
        - Storage Account (stazlablabeus001)
          - Blob Service
            - $Web
              - index.html
              - 404.html
              - outros arquivos do site (CSS, JS, Imagens)
        - Static Website
      - Cost Management > Budget > BUD-MarcioLab-Monthly

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

---
---
---
---
---
---