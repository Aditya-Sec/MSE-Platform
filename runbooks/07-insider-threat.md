# Runbook — Insider Threat (Sensitive Data Exfiltration)

## Scenario
A user copies or externally shares a file labeled Confidential/Highly Confidential — Purview DLP should have blocked it, but the detection exists as a secondary control for gaps in labeling or policy coverage.

## Detection
- **Rule:** [`detections/kql/purview-confidential-file-external-share.kql`](../detections/kql/purview-confidential-file-external-share.kql) — T1567
- **Primary control:** [`data-protection/dlp-confidential-data-policy.json`](../data-protection/dlp-confidential-data-policy.json) — set to `BlockAccess`, not just audit, so this detection firing at all means either the label wasn't applied correctly (check [`sensitivity-labels.json`](../data-protection/sensitivity-labels.json)'s auto-labeling rules) or the share happened through a channel the DLP policy doesn't cover yet (the policy's `workloads` list is SharePoint/OneDrive/Teams/Exchange — anything outside those, e.g. a personal cloud storage upload, is a real, common gap)

## Incident → Automated Response
No automated playbook — this is deliberately kept as a manager-notification workflow rather than an account-disable one, matching the original brief's own design ("Manager Notification," not "Disable User"). Insider-threat response needs human judgment about intent (mistake vs. malice) in a way password-spray detection doesn't — automating straight to punitive action here would be the wrong call, not just an unfinished feature.

## Manual Investigation (analyst steps)
1. Confirm the file's actual sensitivity label at time of share — was it correctly applied?
2. Check the sharing channel — did it go through a Purview-covered workload (policy should have blocked it — investigate why it didn't) or an uncovered one (policy gap, not a detection failure)?
3. Review the user's recent activity for a pattern (single mistake vs. repeated attempts vs. bulk data staging beforehand — cross-reference against a mass-download pattern if one exists in the same time window)

## Containment
No automated action. Notify the user's manager (per the original scenario design) and, if warranted after investigation, HR/Legal — this is the one runbook in this set where the "response" is organizational process, not a technical control.

## Recovery
Revoke the specific share/link if the platform supports it; this doesn't require disabling the user's account unless investigation independently supports that.

## Lessons learned — questions to actually ask
- Was this genuinely malicious, or a mislabeled file / a legitimate business need that the DLP policy was too strict to accommodate? Insider-threat runbooks that don't ask this honestly turn into a tool for punishing normal mistakes, which erodes trust in the whole security program over time
