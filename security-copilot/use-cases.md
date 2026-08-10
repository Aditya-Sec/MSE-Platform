# Security Copilot — Use Cases for This Project

No live Security Copilot license was available to run any of this for real — every example in this folder is a written, hand-validated illustration of a real, documented capability, not a captured session. That boundary is stated once here and applies to every file in this folder.

## The 6 use cases, and how each maps to something real in this repo

| Use case | What Copilot actually does (per Microsoft's 2026 documentation) | Where it applies here |
|---|---|---|
| **Incident summarization** | Synthesizes alerts into a coherent narrative — "what happened, which accounts, what was the likely goal" | Any incident from the 19 KQL detections in `detections/kql/` |
| **MITRE ATT&CK mapping** | Cross-references incident indicators against ATT&CK techniques | Redundant with, and a good cross-check against, this project's own `generate_attack_coverage.py` — worth knowing both exist rather than treating Copilot as the only source of truth |
| **KQL generation** | Plain English → syntactically correct KQL for Sentinel/Defender Advanced Hunting | See [`kql-generation-example.json`](kql-generation-example.json) |
| **Threat hunting** | Natural-language hunting queries across Sentinel/XDR tables | Would hunt against the same tables this project's detections already use (SigninLogs, DeviceNetworkEvents, DeviceProcessEvents) |
| **Root cause analysis** | Traces an incident back through entity relationships (device → user → sign-in → prior alerts) | Directly maps to the promptbook step sequence in [`promptbook-password-spray-investigation.json`](promptbook-password-spray-investigation.json) |
| **Report writing** | Generates stakeholder-appropriate reports (technical vs. executive) from investigation data | Final step of the same promptbook — an executive summary referencing whether `soar/playbooks/playbook-disable-compromised-user.json` actually fired |

## Cost model (cited, not invented)

Microsoft prices Security Copilot in Security Compute Units (SCUs): roughly 0.5 SCU for a simple summary, 2-3 SCU for a full promptbook run, 5+ SCU for heavy analysis like script reverse-engineering. E5/E7 tenants get some included capacity; others provision SCUs directly (~$4/SCU/hour). This matters for the same reason the rest of this project cites real pricing models (Sentinel's ingestion-based billing, Front Door's Premium SKU requirement) — architecture decisions have cost consequences, and knowing that is part of the actual skill this project is meant to demonstrate.

## What this deliberately doesn't claim

This folder does not claim hands-on Security Copilot usage, a captured investigation transcript, or that the "expected output" shapes shown are guaranteed exact wording — they're a technically informed, hand-checked approximation of what the documented capability produces, built the same way the rest of this project treats anything it couldn't deploy live: clearly labeled, not blurred.
