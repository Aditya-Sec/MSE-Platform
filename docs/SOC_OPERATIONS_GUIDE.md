# SOC Operations Guide — Microsoft Secure Enterprise Platform

Where the Deployment Guide covers "how do I stand this up," this covers "how would a SOC actually use it day to day." Written the way an onboarding document for a new analyst joining this (hypothetical) SOC would read.

## 1. Where alerts actually come from

All 19 detections in `detections/kql/` fire into Microsoft Sentinel, regardless of which layer generated the underlying signal (identity, endpoint, network, email, cloud, or the threat-intel watchlist join). That's the point of a SIEM — one triage queue, not seven.

| Source layer | Detections | Runbook |
|---|---|---|
| Identity | `password-spray-pattern`, `identity-lateral-movement-enriched`, `guest-user-privilege-escalation`, `app-registration-new-credential`, `pim-activation-missing-justification`, `privileged-signin-noncompliant-device` | [`01-identity-attack.md`](../runbooks/01-identity-attack.md) |
| Endpoint | `defender-tamper-attempt` | [`02-ransomware.md`](../runbooks/02-ransomware.md) |
| Network/Web | `waf-sql-injection-burst`, `dns-c2-beaconing-pattern` | [`03-web-attack-sql-injection.md`](../runbooks/03-web-attack-sql-injection.md) |
| Cloud/Storage | `storage-malware-upload`, `defender-cloud-posture-drift` | [`04-malware-upload.md`](../runbooks/04-malware-upload.md) |
| Email | `safelinks-clickthrough-despite-warning`, `mailbox-external-autoforward-rule` | [`05-phishing.md`](../runbooks/05-phishing.md) |
| Containers/AKS | `aks-privileged-container-creation`, `aks-suspicious-pod-exec`, `aks-untrusted-registry-image-pull` | [`06-kubernetes-attack.md`](../runbooks/06-kubernetes-attack.md) |
| Data protection | `purview-confidential-file-external-share` | [`07-insider-threat.md`](../runbooks/07-insider-threat.md) |
| Threat intel | `ti-watchlist-match` | Cross-cutting — see below |

`ti-watchlist-match` doesn't map to one runbook because it's an enrichment/correlation signal that can apply across any of the above scenarios, depending on what else the matched IP/domain/hash is associated with.

## 2. Triage priority (first 5 minutes)

1. **Ransomware indicators (`defender-tamper-attempt`) — always first.** This runbook exists partly to make the point explicit: tamper attempts are often a *precursor* to encryption, not a lagging indicator. Minutes matter here more than anywhere else in this list.
2. **Identity attacks with a successful sign-in** — check whether `playbook-disable-compromised-user.json` already fired (it auto-triggers on 3 specific rule names; confirm it actually matched rather than assuming).
3. **Everything else** — normal queue order, prioritized by the rule's own `AlertSeverity` field.

## 3. Automated vs. manual response — know which is which before you act

Two SOAR playbooks exist. Everything else in this table is manual, and that's stated in each runbook rather than left ambiguous:

| Playbook | Auto-fires on | What it does |
|---|---|---|
| `playbook-disable-compromised-user.json` | Specifically `password-spray-pattern`, `identity-lateral-movement-enriched`, `guest-user-privilege-escalation` — not any other identity alert | Disables account, revokes sessions |
| `playbook-enrich-and-respond.json` | Any incident with an IP entity | Enriches via VirusTotal/AbuseIPDB/Whois, isolates device **only if** enrichment confirms malicious |

If you're triaging an incident and expect an automated response that didn't happen, check the triggering rule name against the table above before assuming something broke — it may simply be a scenario this project hasn't automated yet (Ransomware and Web Attack runbooks name this gap explicitly).

## 4. Portal/tool map

| Task | Where |
|---|---|
| Incident triage, KQL hunting | Microsoft Sentinel (Azure Portal) |
| Endpoint isolation, device timeline | Microsoft Defender portal (security.microsoft.com) |
| Conditional Access review | Entra admin center |
| DLP/Purview incidents | Microsoft Purview compliance portal |
| CASB alerts, OAuth app review | Defender for Cloud Apps portal |
| Natural-language investigation | Security Copilot (securitycopilot.microsoft.com) — see `security-copilot/use-cases.md` for what it's actually good for here |

## 5. Weekly SOC hygiene (not incident-driven, but part of running this)

- Re-run `python3 detections/generate_attack_coverage.py` after any new KQL rule — confirms ATT&CK coverage stays accurate, not stale
- Review CA001/CA003 report-only logs if still in that mode — this is a decision that shouldn't sit unreviewed indefinitely
- Check `threat-intelligence/sentinel-ti-watchlist.json` entries against their `Expiration` field — a stale watchlist makes `ti-watchlist-match.kql` noisier, not safer

## 6. What this guide doesn't cover

Shift scheduling, escalation contact lists, and SLA targets are organization-specific and deliberately not fabricated here with placeholder names/numbers — a real SOC operations guide would have those, but inventing them would be exactly the kind of unearned specificity this project avoids elsewhere.
