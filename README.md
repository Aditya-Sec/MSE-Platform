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

**Project at a glance:** 17 Bicep files (all compiling clean) · 18 KQL detections (16 ATT&CK techniques covered, generated live, not asserted) · 2 SOAR playbooks · 3 Conditional Access policies · 7 attack-scenario runbooks, each tied to specific detections and playbooks in this repo · 4 architecture diagrams · zero live Azure spend, by design — see [`docs/PRD.md`](docs/PRD.md) Section 4.

<br/>

## Documentation index

| Document | What it covers |
|---|---|
| [`docs/PRD.md`](docs/PRD.md) | Scope, success criteria, the honest boundary on what this project proves |
| [`docs/DEPLOYMENT_GUIDE.md`](docs/DEPLOYMENT_GUIDE.md) | Step-by-step deployment, all 8 phases, prerequisites, cost warnings |
| [`docs/SOC_OPERATIONS_GUIDE.md`](docs/SOC_OPERATIONS_GUIDE.md) | How this platform would actually be used day to day — triage priority, automated vs. manual response, portal map |
| [`runbooks/`](runbooks) | 7 incident-response runbooks, one per documented attack scenario |
| [`architecture/diagrams/`](architecture/diagrams) | HLD + 3 layer-specific LLDs |

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
| 7 | Attack Simulations & Runbooks (7 documented scenarios) | ✅ Complete |
| 8 | Documentation + polish | ✅ Complete |

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

## Deploying

Full step-by-step instructions (prerequisites, exact commands per phase, cost warnings before Phase 4 specifically) now live in [`docs/DEPLOYMENT_GUIDE.md`](docs/DEPLOYMENT_GUIDE.md) rather than duplicated here.

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

## Phase 7 — Attack Simulations & Runbooks

**7 runbooks** in [`runbooks/`](runbooks), one per documented scenario, each following the same structure: Detection (which KQL rule fires, with ATT&CK ID) → Automated Response (which SOAR playbook, if one exists) → Manual Investigation steps → Containment → Recovery → Lessons Learned. Every runbook links directly to the specific files in this repo it references — no generic "isolate the affected system" advice untethered from what's actually built here.

**Two honest gaps, named rather than hidden:** the Ransomware and Web Attack (SQLi) runbooks both note that no dedicated auto-response playbook exists yet for their scenario — only 2 SOAR playbooks are built so far ([Phase 3](#phase-3--siem--soar-core)), and pretending otherwise would undercut the whole point of this project's honesty discipline. Each gap is named as a concrete next addition, not glossed over.

**One deliberate non-automation, by design, not oversight:** the Insider Threat runbook stays a manager-notification workflow rather than an auto-disable playbook — matching the original brief's own scenario design. Insider threat needs human judgment about intent in a way password-spray detection doesn't; automating straight to punitive action would be the wrong call, not an unfinished feature.

**Attack simulations:** [`attack-simulations/generate_synthetic_events.py`](attack-simulations/generate_synthetic_events.py) — generates synthetic log events shaped exactly like what specific detections expect (a real password-spray pattern, a TI-watchlist match, and a benign control case that should trigger nothing). This is data generation for testing detection logic, not real attack tooling — verified live, produces correctly-shaped JSON for all three scenarios.

<br/>

## Phase 8 — Documentation + Polish

- **HLD reviewed against final state** — the master architecture diagram already reflected all 8 layers accurately (it was built comprehensively from the start rather than needing per-phase updates); verified rather than assumed before calling this phase done
- [`docs/DEPLOYMENT_GUIDE.md`](docs/DEPLOYMENT_GUIDE.md) — every deploy command from every phase, consolidated in the correct order, with prerequisites and the Phase 4 cost warning surfaced up front rather than buried
- [`docs/SOC_OPERATIONS_GUIDE.md`](docs/SOC_OPERATIONS_GUIDE.md) — the piece that turns 18 detections and 7 runbooks into an actual triage workflow: what fires first, which responses are automated vs. manual, and a portal map across 5 different Microsoft consoles this project touches
- **README polish** — added a verified project-stats snapshot (each number checked with `find`/`wc -l` against the actual repo, not estimated — one number was wrong on first draft and caught before publishing) and a documentation index tying everything together
- Removed obsolete `.gitkeep.md` placeholders from folders that now have real content

<br/>

## License

MIT — see [LICENSE](LICENSE).
