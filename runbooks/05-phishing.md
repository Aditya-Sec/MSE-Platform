# Runbook — Phishing

## Scenario
A user receives a phishing email; either they click through a Safe Links warning, or a rule to auto-forward mail externally appears (a common post-compromise persistence technique, not just a phishing symptom).

## Detection
- **Rules:** [`detections/kql/safelinks-clickthrough-despite-warning.kql`](../detections/kql/safelinks-clickthrough-despite-warning.kql) (T1566.002) and [`detections/kql/mailbox-external-autoforward-rule.kql`](../detections/kql/mailbox-external-autoforward-rule.kql) (T1114.003) — two related but distinct signals, worth treating separately since one is "user made a mistake" and the other is "mailbox may already be compromised"
- **Primary control:** [`email-security/safe-links-policy.json`](../email-security/safe-links-policy.json) — click-through is disabled outright in this project's policy, not just warned, so the click-through detection firing at all is itself informative (it means the policy either wasn't applied to this user/domain, or is still rolling out)

## Incident → Automated Response
No dedicated playbook. If the auto-forward-rule detection fires, that's a strong enough signal to warrant the same account-disable treatment as the Identity Attack runbook — worth extending `playbook-disable-compromised-user.json`'s trigger-rule list to include `mailbox-external-autoforward-rule` as a future addition, rather than leaving it manual indefinitely.

## Manual Investigation (analyst steps)
1. For click-through: confirm whether Safe Links policy actually applied to this recipient (check `email-security/safe-links-policy.json`'s `appliesTo.exceptions` — was this user accidentally in an exception list?)
2. For auto-forward: identify the forwarding destination domain — internal typo/personal-account forwarding is very different from forwarding to an unknown external domain
3. Check the sender/URL against [`threat-intelligence/sentinel-ti-watchlist.json`](../threat-intelligence/sentinel-ti-watchlist.json)

## Containment
Remove the malicious auto-forward rule immediately if found (this is the higher-urgency half of this runbook — an active exfiltration channel, not just a risky click). Reset the account's credentials as a precaution even if no other compromise indicator exists yet.

## Recovery
User awareness follow-up for click-through cases (not punitive — the point of Safe Links' warning page existing is that some people will click anyway, that's expected, not a failure). For auto-forward cases, treat as a confirmed-compromise recovery, same as the Identity Attack runbook.

## Lessons learned — questions to actually ask
- Was the auto-forward rule created around the same time as a suspicious sign-in? If so, this and the Identity Attack scenario are the same incident, not two — check `identity-lateral-movement-enriched.kql`'s time window against this one before treating them as unrelated
