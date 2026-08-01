# Microsoft Secure Enterprise (MSE) Platform — PRD

## 1. Objective

Design and build a complete Microsoft-native enterprise security architecture — as Infrastructure-as-Code, detection content, and documentation — covering identity, endpoint, cloud, network, email, data, SIEM, SOAR, and AI-assisted operations. The goal is to demonstrate how these products integrate into one coherent security platform, not to catalog them as a tool list.

## 2. Scope

### In scope
- Infrastructure-as-Code (Bicep) for every architectural layer below
- 20-30 KQL detection rules mapped to MITRE ATT&CK
- Sentinel analytics rules and Logic Apps SOAR playbooks
- Architecture diagrams (HLD and LLD)
- Incident response runbooks for 7 documented attack scenarios
- Full documentation set: PRD (this document), HLD, LLD, Deployment Guide, SOC Operations Guide

### Explicitly out of scope
- Live deployment to a production or trial Azure tenant (no subscription available at build time — see Section 4)
- Production change management, live incident ownership, or tenant administration
- Full implementation of every sub-feature of every Microsoft product (e.g., every Purview compliance policy type) — depth is prioritized over exhaustive coverage of each product's own feature surface

## 3. Architecture layers (build phases)

| # | Layer | Core products |
|---|---|---|
| 1 | Foundation | Virtual Network, NSGs, Key Vault |
| 2 | Identity Security | Entra ID, Conditional Access, Defender for Identity |
| 3 | Endpoint Security | Defender for Endpoint, Intune |
| 4 | SIEM / SOAR | Sentinel, Logic Apps |
| 5 | Cloud & Network Security | Defender for Cloud, Azure Firewall, WAF, Front Door, DDoS Protection |
| 6 | Email Security / CASB / Data Protection | Defender for Office 365, Defender for Cloud Apps, Purview |
| 7 | Threat Intelligence / AI | Defender TI, Security Copilot |
| 8 | Attack Simulations / Runbooks | 7 documented incident scenarios |

## 4. Honest positioning — read before anything else in this repo

This project is built entirely as code, diagrams, and documentation, verified for structural and syntactic correctness wherever that's checkable without a live tenant — every Bicep file in this repo is compiled with the real Bicep CLI before being committed, not just written and assumed correct.

**What this proves:** the ability to design an integrated, multi-layer Microsoft security architecture, write correct Infrastructure-as-Code for it, build real detection content mapped to MITRE ATT&CK, and document a SOC operating model end to end.

**What this does not prove:** production administration of a live Microsoft tenant, real enterprise change management, live incident ownership, or large-scale Azure operations experience. No Azure subscription was available at build time, so nothing here has been deployed and observed running in a live environment. That distinction is maintained throughout this repo, not just stated once here.

## 5. Success criteria

- Every Bicep file compiles cleanly with the real Bicep CLI (`bicep build`)
- Every KQL rule is syntactically valid and mapped to a specific MITRE ATT&CK technique
- Every architecture diagram accurately reflects what the Bicep code actually deploys — no diagram describes infrastructure the code doesn't contain
- Documentation is sufficient that a reader could deploy this into a real subscription by following the Deployment Guide alone
