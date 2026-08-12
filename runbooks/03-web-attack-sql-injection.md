# Runbook — Web Attack (SQL Injection)

## Scenario
A burst of SQL-injection-pattern requests hits a web application behind Front Door/WAF.

## Detection
- **Rule:** [`detections/kql/waf-sql-injection-burst.kql`](../detections/kql/waf-sql-injection-burst.kql) — T1190
- **Backing capability:** [`bicep/cloud-network-security/front-door-waf.bicep`](../bicep/cloud-network-security/front-door-waf.bicep) — WAF policy in **Prevention mode**, meaning most of this attack is already blocked before it ever becomes an incident. The detection rule is watching the *attempt volume*, not confirming damage — that distinction matters for how urgently you triage it.

## Incident → Automated Response
No dedicated playbook yet — this is the other honest gap alongside the ransomware runbook. A real next addition: auto-block the source IP at the Firewall/WAF custom rule level when this detection fires above a severity threshold, rather than relying on WAF's built-in matching alone.

## Manual Investigation (analyst steps)
1. Confirm from Front Door/WAF logs whether requests were actually blocked (Prevention mode) or only logged — a misconfigured policy in Detection-only mode changes this from "handled" to "active exposure"
2. Identify the targeted endpoint/parameter — is this a known vulnerable pattern in the app, or blind probing?
3. Check whether the same source IP appears in [`threat-intelligence/sentinel-ti-watchlist.json`](../threat-intelligence/sentinel-ti-watchlist.json)

## Containment
Manual IP block at Firewall (network-layer, broader than WAF's request-layer block) if the source persists past WAF blocking — belt-and-suspenders, not redundant, since WAF and Firewall operate at different layers as documented in [`bicep/cloud-network-security/main.bicep`](../bicep/cloud-network-security/main.bicep).

## Recovery
No user-facing recovery needed if WAF held (Prevention mode did its job). If any request got through, that's a distinct, more serious incident — treat as a possible web-shell/injection-success scenario, not a continuation of this one.

## Lessons learned — questions to actually ask
- Was the WAF actually in Prevention mode, or had someone switched it to Detection for troubleshooting and forgotten to switch back? This is a real, common operational failure mode worth explicitly checking, not assuming
