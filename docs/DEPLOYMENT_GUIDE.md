# Deployment Guide — Microsoft Secure Enterprise Platform

This guide walks through deploying every phase, in the correct order, with the prerequisites and cost warnings that matter before you run anything. Nothing in this repo was deployed live during development — see `PRD.md` Section 4 for why, and read that boundary before assuming anything here has been tested against a real tenant.

## Before you start

**Roles needed:** Global Administrator or a combination of Application Administrator (Conditional Access), Security Administrator (Defender plans), Compliance Administrator (Purview), and Contributor on the target subscription (Bicep resources). A single Global Admin account covers everything but is broader access than a real production rollout should use — scope down role-by-role for anything beyond a personal lab.

**Tools:** Azure CLI (`az`), Bicep CLI (`bicep` — this repo was validated against v0.46.1), PowerShell 7+ with the `ExchangeOnlineManagement` module, Python 3.10+.

**⚠️ Cost warning, read before Phase 4 specifically:** Azure Firewall Premium, Front Door Premium, and DDoS Protection are the expensive items in this architecture — realistically **hundreds of dollars a month** if left running, not something a free trial comfortably absorbs long-term. Deploy Phase 4's network resources only if you intend to tear them down promptly (`az group delete`) after review, or skip live deployment and treat the Bicep as reviewed-and-validated code, which is exactly how this repo itself was built.

## Phase-by-phase

### Phase 1 — Foundation
```bash
az group create --name rg-mse-platform --location eastus
az deployment group create \
  --resource-group rg-mse-platform \
  --template-file bicep/foundation/main.bicep
```
Note the output values (`vnetId`, subnet IDs, `keyVaultUri`) — Phase 4 needs them as parameters.

### Phase 2 — Identity + Endpoint
```bash
# Subscription-scoped — Defender plans apply tenant-wide, not per resource group
az deployment sub create --location eastus --template-file bicep/identity/main.bicep
az deployment sub create --location eastus --template-file bicep/endpoint/main.bicep

# Conditional Access + Intune — Microsoft Graph, not Bicep
pwsh conditional-access/deploy-conditional-access.ps1   # defaults to -WhatIf, review before applying for real
```
**Recommended sequencing within this phase:** deploy CA policies in report-only mode first (the default in this repo), let them log for at least a week, review what would have been blocked, *then* switch to enforced. Going straight to enforced risks locking out an account you forgot about.

### Phase 3 — SIEM / SOAR core
```bash
az deployment group create \
  --resource-group rg-mse-platform \
  --template-file bicep/siem-soar/main.bicep

python3 detections/generate_attack_coverage.py   # regenerate ATT&CK coverage after any new KQL rule
```
Logic Apps playbooks (`soar/playbooks/*.json`) need the Sentinel workspace to exist first, plus API connections for Teams/ServiceNow/Sentinel and a Managed Identity granted the specific Graph/Defender permissions documented in each playbook's `metadata.note` field.

### Phase 4 — Cloud & Network Security
```bash
az deployment group create \
  --resource-group rg-mse-platform \
  --template-file bicep/cloud-network-security/main.bicep \
  --parameters firewallSubnetId=<phase1-output> bastionSubnetId=<phase1-output> vnetId=<phase1-output>

az deployment sub create --location eastus --template-file bicep/cloud-network-security/main-defender.bicep
```
See the cost warning above before running the first command for real.

### Phase 5 — Email, CASB, Data Protection
```bash
pwsh email-security/deploy-email-security.ps1              # defaults to -WhatIf
python3 casb/deploy_casb_policies.py                        # set CLOUDAPPS_TENANT_URL + CLOUDAPPS_API_TOKEN to go live
pwsh data-protection/deploy-purview-policies.ps1            # defaults to -WhatIf
```
No Bicep in this phase — see the phase's own README section for why that's correct, not a gap.

### Phase 6 — Threat Intelligence & AI
```bash
python3 threat-intelligence/graph_ti_indicators_sync.py    # set GRAPH_ACCESS_TOKEN to submit for real
```
Security Copilot itself isn't deployed by this repo — it's licensed separately (SCU-based or included in E5/E7), and `security-copilot/` is documentation, not a deployable component.

### Phase 7 — Attack Simulations & Runbooks
```bash
python3 attack-simulations/generate_synthetic_events.py password-spray
```
No deployment — this phase produces test data and reference documentation (`runbooks/`), not infrastructure.

## Validating everything, at any point

```bash
bash scripts/validate_bicep.sh                  # all Bicep files compile
python3 detections/generate_attack_coverage.py   # ATT&CK coverage regenerates correctly
python3 casb/deploy_casb_policies.py             # CASB policies produce valid requests
python3 threat-intelligence/graph_ti_indicators_sync.py   # TI sync produces valid requests
```
All four are safe to run repeatedly and don't require live credentials to validate structure.

## Tearing down

```bash
az group delete --name rg-mse-platform --yes
```
Removes everything resource-group-scoped (Phases 1, 3, 4's network resources). Subscription-scoped Defender plans (Phases 2, 4's Defender enablement) need to be disabled separately via `az deployment sub` with pricing tier set back to `Free`. Conditional Access, Intune, Safe Links/Attachments, CASB, and Purview policies all need manual removal via their respective portals/PowerShell — they aren't resource-group-scoped and won't be touched by `az group delete`.
