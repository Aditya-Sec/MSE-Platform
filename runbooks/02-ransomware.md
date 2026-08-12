# Runbook — Ransomware

## Scenario
Endpoint shows indicators of ransomware behavior — mass file operations, shadow copy deletion, or Defender for Endpoint tamper attempts (often a precursor, since attackers disable EDR before detonating).

## Detection
- **Rule:** [`detections/kql/defender-tamper-attempt.kql`](../detections/kql/defender-tamper-attempt.kql) — T1562.001, often fires *before* encryption starts, which is exactly why it matters as a leading indicator, not just a lagging one
- **Backing capability:** [`bicep/endpoint/defender-for-servers.bicep`](../bicep/endpoint/defender-for-servers.bicep) must be deployed and healthy for this signal to exist at all

## Incident → Automated Response
**Honest gap, stated plainly:** no dedicated auto-isolation playbook exists yet for this specific scenario. [`soar/playbooks/playbook-enrich-and-respond.json`](../soar/playbooks/playbook-enrich-and-respond.json) covers IP-based enrichment and conditional isolation, but a ransomware-specific device-isolation playbook (isolate immediately on tamper-attempt + high-severity Defender alert, no enrichment delay — because with ransomware, minutes matter more than confirmation) is a natural addition when this project's SOAR library expands further.

## Manual Investigation (analyst steps, until the gap above is closed)
1. Treat the tamper-attempt alert as time-critical — don't wait for a second signal
2. Check Defender for Endpoint's own device timeline for the host (outside this repo's scope — this is where you'd actually be in the Defender portal)
3. Identify blast radius: what other devices does this host have active sessions to (see the RDP/SSH-restricted-to-Bastion NSG rules in [`bicep/foundation/nsg.bicep`](../bicep/foundation/nsg.bicep) — lateral movement should be constrained by design, verify it actually was)

## Containment
Manual device isolation via Defender for Endpoint console (Selective isolation — same reasoning as this profile's other EDR work: keep the device talking to security tooling during investigation, don't go fully dark).

## Recovery
Restore from backup (out of scope for this repo — a real production runbook would name the specific backup solution and RTO/RPO here). Do not pay ransom, do not restore before confirming the initial access vector is closed (otherwise you restore into the same hole).

## Lessons learned — questions to actually ask
- How long between the tamper-attempt alert and encryption starting? That gap is your real detection-to-response SLA target
- This is the scenario that most directly argues for building the missing auto-isolation playbook — worth naming as a concrete next step, not a vague "improve automation" note
