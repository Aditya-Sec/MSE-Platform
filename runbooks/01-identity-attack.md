# Runbook — Identity Attack (Impossible Travel / Password Spray)

## Scenario
An attacker attempts credential-based compromise via password spraying or uses stolen credentials from a geographically distant location.

## Detection
- **Rule:** [`detections/kql/password-spray-pattern.kql`](../detections/kql/password-spray-pattern.kql) — distinguishes spray (many accounts, few attempts each) from brute force
- **Secondary signal:** [`detections/kql/identity-lateral-movement-enriched.kql`](../detections/kql/identity-lateral-movement-enriched.kql) if the attacker pivots after initial access
- **ATT&CK:** T1110.003 (Password Spraying), T1550.002 (lateral movement variant)

## Incident → Automated Response
[`soar/playbooks/playbook-disable-compromised-user.json`](../soar/playbooks/playbook-disable-compromised-user.json) fires **only** when the triggering rule name matches `password-spray-pattern`, `identity-lateral-movement-enriched`, or `guest-user-privilege-escalation` — not on any generic identity alert. On match: disables the account via Graph, revokes all active sign-in sessions, comments the incident with the specific triggering rule for audit.

## Manual Investigation (analyst steps)
1. Confirm the affected account(s) via the Sentinel incident's related entities
2. Check [`conditional-access/ca001-require-mfa-all-users.json`](../conditional-access/ca001-require-mfa-all-users.json) and [`ca003-require-compliant-device-privileged-roles.json`](../conditional-access/ca003-require-compliant-device-privileged-roles.json) — did these policies apply, and were they still in report-only mode? (Report-only means they logged but didn't block — check this first, it changes the whole investigation.)
3. Cross-reference source IPs against [`threat-intelligence/sentinel-ti-watchlist.json`](../threat-intelligence/sentinel-ti-watchlist.json) via [`detections/kql/ti-watchlist-match.kql`](../detections/kql/ti-watchlist-match.kql)
4. If Security Copilot is available: run the promptbook in [`security-copilot/promptbook-password-spray-investigation.json`](../security-copilot/promptbook-password-spray-investigation.json)

## Containment
Account disable + session revocation (automated, see above). If lateral movement is confirmed, also isolate any device the account signed into — see the Ransomware runbook's containment step for the isolation mechanism.

## Recovery
Password reset (forced), re-enable account only after MFA re-registration is confirmed, review the account's role assignments for any changes made during the compromise window.

## Lessons learned — questions to actually ask
- If CA001/CA003 were still in report-only mode, this is the trigger to move them to enforced (a real operational decision, not a checkbox)
- Was the account a service account exempted from MFA? Service account exemptions are a common real-world gap this scenario exposes
