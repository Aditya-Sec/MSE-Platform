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
| 3 | SIEM / SOAR (Sentinel, Logic Apps, KQL, ATT&CK mapping) | ✅ Complete |
| 4 | Cloud & Network Security (Defender for Cloud, Firewall, WAF, Front Door, DDoS) | ✅ Complete |
| 5 | Email, CASB, Data Protection (Defender for O365, Defender for Cloud Apps, Purview) | ✅ Complete |
| 6 | Threat Intelligence & AI (Defender TI, Security Copilot) | ✅ Complete |
| 7 | Attack Simulations & Runbooks (7 documented scenarios) | ⏳ Planned |
| 8 | Documentation + polish | ⏳ Planned |

<br/>

## Phase 1 — Foundation

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

## Phase 3 — SIEM / SOAR core

**What's here:**
- [`bicep/siem-soar/sentinel-workspace.bicep`](bicep/siem-soar/sentinel-workspace.bicep) — Log Analytics workspace + Sentinel onboarding deployed together (Sentinel is a solution enabled *on* a workspace, not a standalone resource — the module reflects that instead of treating them as separate layers)
- [`detections/kql/`](detections/kql) — 17 more KQL detections added this phase (19 total across the project), spanning identity, endpoint, cloud/container, email, and data-protection sources — because Sentinel is the central SIEM regardless of which layer a signal originates from
- [`detections/generate_attack_coverage.py`](detections/generate_attack_coverage.py) — parses every rule's ATT&CK header and generates a real Navigator layer, run and verified: **15 techniques covered**, 2 rules intentionally excluded and named (one uses a NIST CSF tag instead since it detects posture drift, not an attack technique; one is a Conditional-Access control-effectiveness check)
- [`soar/playbooks/`](soar/playbooks) — 2 real Logic App templates:
  - `playbook-enrich-and-respond.json` — the documented enrichment chain (VirusTotal → AbuseIPDB → Whois → Teams → ServiceNow), with device isolation gated behind *confirmed-malicious* enrichment results, not the raw incident alone
  - `playbook-disable-compromised-user.json` — gated on the *specific source detection rule* (password spray / lateral movement / guest privilege escalation), not any generic incident, matching the "Impossible Travel → Disable User" scenario from the original brief

**Verified, not just written:**
```bash
bash scripts/validate_bicep.sh          # 10/10 Bicep files compiled clean
python3 detections/generate_attack_coverage.py   # 15 techniques extracted, real Navigator layer written
```
Both SOAR playbook JSON files parse and validate; both are deliberately gated on high-confidence conditions rather than auto-acting on a raw incident, matching the "human-in-the-loop for destructive actions" discipline used throughout the rest of this profile's SOAR work.

<br/>

## Phase 4 — Cloud & Network Security

**What's here:**
- [`bicep/cloud-network-security/firewall-rules.bicep`](bicep/cloud-network-security/firewall-rules.bicep) — Azure Firewall Premium, deployed into the exact `AzureFirewallSubnet` reserved back in Phase 1 (this is what that reservation was for). Policy-based rule management with real network + application rule collections, threat intel in Alert-only mode as the starting posture — same "don't hard-block on day one" discipline used for Conditional Access in Phase 2
- [`front-door-waf.bicep`](bicep/cloud-network-security/front-door-waf.bicep) — Front Door Premium with a WAF policy running Microsoft's Default Ruleset (OWASP coverage) in **Prevention** mode — a deliberately different posture than the Firewall's Alert-only threat intel, reasoned about explicitly in the file's comments, not just copy-pasted
- [`ddos-protection.bicep`](bicep/cloud-network-security/ddos-protection.bicep) — DDoS Protection Plan, with the VNet-association step correctly identified as living on the Phase 1 VNet resource rather than modeled as a separate (nonexistent) attachment resource
- [`bastion.bicep`](bicep/cloud-network-security/bastion.bicep) — Azure Bastion into the reserved `AzureBastionSubnet` — the actual service that makes Phase 1's "RDP/SSH from Bastion subnet only" NSG rules meaningful, rather than a rule pointing at nothing
- [`defender-for-cloud.bicep`](bicep/cloud-network-security/defender-for-cloud.bicep) — Defender for Storage (with on-upload malware scanning, wired to Phase 3's `storage-malware-upload.kql`), SQL, Containers, and the CSPM plan tier

**Two orchestrators, not one — and that's deliberate:** `main.bicep` (resource-group scope: Firewall, Front Door, DDoS, Bastion) and `main-defender.bicep` (subscription scope: Defender plans), matching the exact scope split Azure itself enforces — the same reasoning already established in Phase 2 for identity/endpoint.

**Bugs the real Bicep CLI actually caught during this build** (kept here rather than quietly fixed and forgotten):
- Two hardcoded-URL linter warnings on the Firewall's allow-listed management FQDNs — properly suppressed with a documented reason rather than reworded to dodge the linter
- An unused `location` parameter on the Front Door module — removed outright once traced to Front Door resources all being `Global` scope, not resource-group-scoped
- An unused `vnetId` parameter on the DDoS module — fixed by actually threading it through to an output instead of leaving dead code

**Verified, not just written:**
```bash
bash scripts/validate_bicep.sh   # 17/17 Bicep files compiled clean, project-wide
```

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

# Phase 3 — resource-group scoped (Sentinel workspace)
az deployment group create \
  --resource-group rg-mse-platform \
  --template-file bicep/siem-soar/main.bicep

# Logic Apps playbooks require an existing Sentinel workspace + API connections —
# see soar/playbooks/*.json "metadata.note" for the exact permissions each needs

# Phase 4 — resource-group scoped (Firewall, Front Door, DDoS, Bastion) —
# requires Phase 1's subnet/VNet output IDs as parameters
az deployment group create \
  --resource-group rg-mse-platform \
  --template-file bicep/cloud-network-security/main.bicep \
  --parameters firewallSubnetId=<phase1-output> bastionSubnetId=<phase1-output> vnetId=<phase1-output>

# Phase 4 — subscription scoped (Defender for Storage/SQL/Containers/CSPM)
az deployment sub create --location eastus --template-file bicep/cloud-network-security/main-defender.bicep

# Phase 5 — no Bicep; three separate deployment surfaces
pwsh email-security/deploy-email-security.ps1
python3 casb/deploy_casb_policies.py          # set CLOUDAPPS_TENANT_URL + CLOUDAPPS_API_TOKEN to deploy for real
pwsh data-protection/deploy-purview-policies.ps1

# Phase 6 — threat intel sync (no Bicep; Graph API)
python3 threat-intelligence/graph_ti_indicators_sync.py   # set GRAPH_ACCESS_TOKEN to submit for real
```

No subscription was available at build time — see `docs/PRD.md` Section 4 for the exact, honest boundary on what that means for what this repo does and doesn't prove.

<br/>

## Phase 5 — Email, CASB, Data Protection

**A deliberately different deployment shape than Phases 1-4** — worth explaining directly, since it's a real architectural fact, not a gap: none of Defender for Office 365, Defender for Cloud Apps, or Purview are ARM resources. They're licensed M365/Security-portal-configured products with their own control planes, so this phase has **zero Bicep files** and that's correct, not incomplete.

**What's here, across three genuinely distinct deployment surfaces:**

| Layer | Deployment surface | Files |
|---|---|---|
| **Email security** (Defender for O365) | Exchange Online PowerShell | [`email-security/`](email-security) — Safe Links (click-through disabled, not just warned), Safe Attachments (dynamic delivery, fail-closed on scan error) |
| **CASB** (Defender for Cloud Apps) | Cloud Apps REST API | [`casb/`](casb) — anomaly detection (impossible travel/mass download for SaaS apps) + OAuth app governance (flagged for review, never auto-revoked) |
| **Data protection** (Purview) | Security & Compliance PowerShell | [`data-protection/`](data-protection) — 4-tier sensitivity label taxonomy + a DLP policy that actually references those labels, deployed in the correct dependency order |

**Each policy ties back to a specific detection**, not built in isolation:
- Safe Links → `safelinks-clickthrough-despite-warning.kql` (the policy blocks outright; the detection catches the edge case where it didn't)
- CASB anomaly policy → `identity-lateral-movement-enriched.kql` (same lateral-movement concept, SaaS-app side instead of Azure AD sign-in side)
- Purview DLP → `purview-confidential-file-external-share.kql` (policy blocks the share; detection catches labeling gaps)

**Verified, not just written:**
```bash
python3 casb/deploy_casb_policies.py   # dry-run, prints the exact request each policy would send
```
Both CASB policies print a real, correctly-shaped API request in dry-run mode. All 7 new JSON files across email-security/casb/data-protection parse and validate.

<br/>

## Phase 6 — Threat Intelligence & AI

**Threat intelligence:**
- [`threat-intelligence/sentinel-ti-watchlist.json`](threat-intelligence/sentinel-ti-watchlist.json) — schema for the `ThreatIntelIOCs` Sentinel watchlist (IPs, domains, hashes, URLs), including an `Expiration` field — stale IOCs are noise, not signal, and this is designed around that
- [`threat-intelligence/graph_ti_indicators_sync.py`](threat-intelligence/graph_ti_indicators_sync.py) — submits indicators via the real Microsoft Graph Security `tiIndicators` API, mapping this project's watchlist schema to Microsoft's actual field names (`networkIPv4`, `domainName`, `tlpLevel`, etc.), not invented ones. Verified live in dry-run mode, producing correctly-shaped API requests.
- [`detections/kql/ti-watchlist-match.kql`](detections/kql/ti-watchlist-match.kql) — the one detection in this project that depends on external data rather than self-contained log analysis, using Sentinel's real `_GetWatchlist()` join pattern. Picked up automatically by Phase 3's `generate_attack_coverage.py` with zero code changes — **16 techniques now covered, up from 15** — proving the cross-phase tooling genuinely composes rather than needing to be re-wired each phase.

**Security Copilot — read this framing first:** no live Security Copilot license was available, so nothing in [`security-copilot/`](security-copilot) is a captured session. Every file states that boundary explicitly rather than implying otherwise.
- [`security-copilot/promptbook-password-spray-investigation.json`](security-copilot/promptbook-password-spray-investigation.json) — modeled on Microsoft's real, documented "Microsoft Sentinel incident investigation" promptbook, applied to this project's own password-spray detection, with SCU cost estimates cited from Microsoft's published pricing tiers
- [`security-copilot/kql-generation-example.json`](security-copilot/kql-generation-example.json) — a natural-language-to-KQL example, hand-validated against this project's own schema usage elsewhere, not just plausible-sounding
- [`security-copilot/use-cases.md`](security-copilot/use-cases.md) — all 6 major use cases mapped to something concrete in this repo, plus the real SCU cost model

<br/>

## Phase 7 — Attack Simulations & Runbooks (next)

Not yet built — full incident-response runbooks for the 7 documented attack scenarios (identity attack, ransomware, web attack, malware upload, phishing, Kubernetes attack, insider threat).

<br/>

## License

MIT — see [LICENSE](LICENSE).
