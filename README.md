<div align="center">
  <img src="assets/banner.svg" alt="Microsoft Secure Enterprise Platform" width="100%"/>
</div>

<br/>

<div align="center">

![Azure](https://img.shields.io/badge/Azure-0d1012?style=flat-square&logoColor=4dd4e8&labelColor=0d1012)
![Bicep](https://img.shields.io/badge/Bicep-0d1012?style=flat-square&logoColor=4dd4e8&labelColor=0d1012)
![Sentinel](https://img.shields.io/badge/Microsoft%20Sentinel-0d1012?style=flat-square&logoColor=4dd4e8&labelColor=0d1012)
![Defender](https://img.shields.io/badge/Microsoft%20Defender-0d1012?style=flat-square&logoColor=4dd4e8&labelColor=0d1012)
![License](https://img.shields.io/badge/License-MIT-0d1012?style=flat-square&labelColor=0d1012&color=4dd4e8)

</div>

<br/>

## What this is

A complete, integrated Microsoft security architecture — 8 layers, from identity through AI-assisted operations — built as Infrastructure-as-Code, real detection content, and professional documentation. Read [`docs/PRD.md`](docs/PRD.md) first: it states plainly what this proves and what it doesn't, before anything else in this repo.

Every Bicep file here is compiled with the real Bicep CLI before being committed — run `scripts/validate_bicep.sh` yourself to check.

<br/>

## Phase status

| Phase | Layer | Status |
|---|---|---|
| 1 | Foundation (VNet, NSG, Key Vault) | ✅ Complete |
| 2 | Identity + Endpoint (Entra ID, Conditional Access, Intune, Defender for Identity/Servers) | ✅ Complete |
| 3 | SIEM / SOAR (Sentinel, Logic Apps, KQL, ATT&CK mapping) | ⏳ Planned |
| 4 | Cloud & Network Security (Defender for Cloud, Firewall, WAF, Front Door, DDoS) | ⏳ Planned |
| 5 | Email, CASB, Data Protection (Defender for O365, Defender for Cloud Apps, Purview) | ⏳ Planned |
| 6 | Threat Intelligence & AI (Defender TI, Security Copilot) | ⏳ Planned |
| 7 | Attack Simulations & Runbooks (7 documented scenarios) | ⏳ Planned |
| 8 | Documentation + polish | ⏳ Planned |

<br/>

## Phase 1 — Foundation (this phase)

**What's here:**
- [`bicep/foundation/vnet.bicep`](bicep/foundation/vnet.bicep) — VNet (10.10.0.0/16) with 7 subnets, including the exact-name-required `AzureFirewallSubnet` and `AzureBastionSubnet` that later phases depend on
- [`bicep/foundation/nsg.bicep`](bicep/foundation/nsg.bicep) — workload NSG, HTTPS allowed, RDP/SSH restricted to Bastion-only, direct-from-internet RDP/SSH explicitly denied
- [`bicep/foundation/keyvault.bicep`](bicep/foundation/keyvault.bicep) — Key Vault with RBAC authorization (not legacy access policies), soft-delete + purge protection enabled, network access denied by default
- [`bicep/foundation/main.bicep`](bicep/foundation/main.bicep) — orchestrates all three, verified to link correctly
- [`architecture/diagrams/hld.svg`](architecture/diagrams/hld.svg) — full 8-layer high-level design
- [`architecture/diagrams/lld-foundation.svg`](architecture/diagrams/lld-foundation.svg) — low-level design for this phase specifically, matching the Bicep output exactly (subnet CIDRs, NSG rule priorities, Key Vault settings — nothing in the diagram that isn't in the code)
- [`docs/PRD.md`](docs/PRD.md) — objective, scope, honest positioning, success criteria

**Verified, not just written:**
```bash
bash scripts/validate_bicep.sh
```
```
✅ PASS — bicep/foundation/keyvault.bicep
✅ PASS — bicep/foundation/main.bicep
✅ PASS — bicep/foundation/nsg.bicep
✅ PASS — bicep/foundation/vnet.bicep

4/4 Bicep files compiled clean.
```
Zero linter warnings across all 4 files as well.

<br/>

## Phase 2 — Identity + Endpoint

**What's here:**
- [`bicep/identity/defender-for-identity.bicep`](bicep/identity/defender-for-identity.bicep) — enables Defender for Identity at subscription scope
- [`bicep/endpoint/defender-for-servers.bicep`](bicep/endpoint/defender-for-servers.bicep) — enables Defender for Servers Plan 2 (the plan that actually includes EDR — P1 doesn't)
- [`conditional-access/`](conditional-access) — 3 real Microsoft Graph-schema Conditional Access policies (require MFA, block legacy auth, require compliant device for privileged roles) plus a PowerShell deployment script. Documented distinctly from the Bicep resources above: Conditional Access lives in Microsoft Graph/Entra ID, a different control plane from Azure Resource Manager — that distinction is stated, not blurred for a cleaner story
- [`intune/windows-compliance-baseline.json`](intune/windows-compliance-baseline.json) — the compliance policy CA003 actually depends on (BitLocker, Secure Boot, Defender status, password policy)
- [`detections/kql/`](detections/kql) — 2 KQL detections for this phase: privileged sign-in from a non-compliant device, and Defender tamper/AV-disable attempts (T1562.001)
- [`architecture/diagrams/lld-identity-endpoint.svg`](architecture/diagrams/lld-identity-endpoint.svg) — low-level design for this phase

**A real correction made during this phase, not glossed over:** Defender plan resources (`Microsoft.Security/pricings`) initially failed to compile at resource-group scope — the Bicep CLI rejected it with error BCP135, which is how the subscription-scope requirement was caught and fixed, not assumed correct from the start.

**Verified, not just written:**
```bash
bash scripts/validate_bicep.sh
```
```
✅ PASS — bicep/endpoint/defender-for-servers.bicep
✅ PASS — bicep/endpoint/main.bicep
✅ PASS — bicep/foundation/keyvault.bicep
✅ PASS — bicep/foundation/main.bicep
✅ PASS — bicep/foundation/nsg.bicep
✅ PASS — bicep/foundation/vnet.bicep
✅ PASS — bicep/identity/defender-for-identity.bicep
✅ PASS — bicep/identity/main.bicep

8/8 Bicep files compiled clean.
```
All 4 JSON policy files (3 Conditional Access + 1 Intune) parse and validate against their documented Microsoft Graph schema fields.

<br/>

## Deploying (once you have a subscription)

```bash
# Phase 1 — resource-group scoped
az group create --name rg-mse-platform --location eastus
az deployment group create \
  --resource-group rg-mse-platform \
  --template-file bicep/foundation/main.bicep

# Phase 2 — subscription scoped (Defender plans apply subscription-wide)
az deployment sub create --location eastus --template-file bicep/identity/main.bicep
az deployment sub create --location eastus --template-file bicep/endpoint/main.bicep

# Conditional Access + Intune (Microsoft Graph, not Bicep)
pwsh conditional-access/deploy-conditional-access.ps1
```

No subscription was available at build time — see `docs/PRD.md` Section 4 for the exact, honest boundary on what that means for what this repo does and doesn't prove.

<br/>

## License

MIT — see [LICENSE](LICENSE).
