"""
Deploys Defender for Cloud Apps policies via its real REST API
(<tenant>.<region>.portal.cloudappsecurity.com/api/v1/policies/) —
a third distinct deployment surface in this phase, alongside ARM/Bicep
(Phase 1-4 resources) and Exchange Online PowerShell (email-security/).

Same dry-run pattern as the rest of this profile: no token set, no live
call — this prints exactly what would be sent instead.
"""

import os
import json
from pathlib import Path

TENANT_URL = os.getenv("CLOUDAPPS_TENANT_URL", "")  # e.g. https://yourtenant.us2.portal.cloudappsecurity.com
API_TOKEN = os.getenv("CLOUDAPPS_API_TOKEN", "")

POLICY_DIR = Path(__file__).parent


def load_policies() -> list:
    return [json.loads(f.read_text()) for f in POLICY_DIR.glob("*.json")]


def build_request(policy: dict) -> dict:
    return {
        "method": "POST",
        "url": f"{TENANT_URL or '<CLOUDAPPS_TENANT_URL not set>'}/api/v1/policies/",
        "headers": {"Authorization": f"Token {API_TOKEN or '<CLOUDAPPS_API_TOKEN not set>'}"},
        "json": policy,
    }


def deploy(dry_run: bool = True):
    policies = load_policies()
    print(f"Found {len(policies)} CASB polic{'y' if len(policies) == 1 else 'ies'} to deploy.\n")

    for policy in policies:
        request = build_request(policy)
        print(f"Policy: {policy['policyName']}")
        print(f"  {request['method']} {request['url']}")

        if dry_run or not (TENANT_URL and API_TOKEN):
            print("  [DRY RUN] — not sent. Set CLOUDAPPS_TENANT_URL and CLOUDAPPS_API_TOKEN to deploy for real.\n")
            continue

        import requests
        resp = requests.post(request["url"], headers=request["headers"], json=request["json"], timeout=15)
        print(f"  Response: {resp.status_code}\n")


if __name__ == "__main__":
    deploy(dry_run=True)
