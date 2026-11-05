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