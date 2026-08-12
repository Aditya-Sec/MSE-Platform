# Runbook — Kubernetes Attack (AKS)

## Scenario
Three related but distinct AKS attack patterns this project detects: a privileged container gets created, a suspicious `exec` into a running pod occurs, or an image gets pulled from an untrusted registry.

## Detection
- **Rules:** [`aks-privileged-container-creation.kql`](../detections/kql/aks-privileged-container-creation.kql) (T1611 — Escape to Host), [`aks-suspicious-pod-exec.kql`](../detections/kql/aks-suspicious-pod-exec.kql) (T1609), [`aks-untrusted-registry-image-pull.kql`](../detections/kql/aks-untrusted-registry-image-pull.kql) (T1204) — treated as three separate runbook entry points below since the right response differs by which one fired
- **Backing capability:** [`bicep/cloud-network-security/defender-for-cloud.bicep`](../bicep/cloud-network-security/defender-for-cloud.bicep) — `defenderForContainers` plan

## Incident → Automated Response
No dedicated playbook yet. The natural shape: pod isolation (via a NetworkPolicy that denies all ingress/egress for the specific pod, not the whole node) triggered on privileged-container-creation specifically, since that's the highest-severity of the three signals — it's the one most consistent with an active container-escape attempt rather than a misconfiguration.

## Manual Investigation (analyst steps)
1. **Privileged container creation:** was this a legitimate deployment (some workloads genuinely need `privileged: true`, e.g. certain CNI/storage plugins) or unexpected? Check against your known-workload allowlist before treating as malicious
2. **Suspicious pod exec:** who ran the `kubectl exec`? Was it a human via `kubectl`, or a service account doing something it shouldn't? The identity matters more than the fact of the exec itself
3. **Untrusted registry pull:** what registry, and is it a typosquat of an approved one (e.g. `docker.io` vs. a lookalike)?

## Containment
Pod-level network isolation (preferred over node isolation — an AKS node likely runs other tenants' pods too, and isolating the whole node is a much bigger blast radius than the incident usually warrants).

## Recovery
Redeploy the workload from a known-good image/manifest rather than attempting to "clean" a potentially-compromised running container — containers are meant to be disposable, treat them that way here.

## Lessons learned — questions to actually ask
- Is there an admission-control policy (e.g. Azure Policy for AKS, or OPA/Gatekeeper) that should have blocked the privileged-container creation before it ever ran? If this fired, that's a preventive-control gap worth naming specifically, not just a detection win
