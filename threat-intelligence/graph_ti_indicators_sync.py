"""
Submits IOCs to Microsoft Graph Security's real tiIndicators API
(POST https://graph.microsoft.com/v1.0/security/tiIndicators) — this is
how a custom threat intel feed actually gets pushed into the Microsoft
security stack so Defender/Sentinel can act on it, not just how you'd
read someone else's Defender TI data.

Same dry-run discipline as casb/deploy_casb_policies.py: no token set,
no live call, prints exactly what would be sent.
"""

import os
import json
from pathlib import Path

GRAPH_TOKEN = os.getenv("GRAPH_ACCESS_TOKEN", "")
GRAPH_URL = "https://graph.microsoft.com/v1.0/security/tiIndicators"

WATCHLIST_PATH = Path(__file__).parent / "sentinel-ti-watchlist.json"


def load_indicators() -> list:
    data = json.loads(WATCHLIST_PATH.read_text())
    return data["sampleRows"]


def build_ti_indicator(row: dict) -> dict:
    """Maps this project's watchlist schema to the real Graph tiIndicator
    schema — the field names below (action, targetProduct, threatType,
    tlpLevel) match Microsoft's actual API contract, not invented ones."""
    type_field_map = {
        "ip": "networkIPv4",
        "domain": "domainName",
        "file_hash": "fileHashValue",
        "url": "url",
    }
    field_name = type_field_map.get(row["IndicatorType"], "url")

    return {
        field_name: row["IndicatorValue"],
        "action": "alert",
        "threatType": row["ThreatType"],
        "confidence": row["Confidence"],
        "targetProduct": "Microsoft Sentinel",
        "tlpLevel": "amber",
        "expirationDateTime": row["Expiration"],
        "description": f"Submitted from MSE-Platform threat-intelligence/ — source: {row['SourceFeed']}",
    }


def submit(dry_run: bool = True):
    indicators = load_indicators()
    print(f"Preparing to submit {len(indicators)} indicator(s) to Microsoft Graph Security.\n")

    for row in indicators:
        indicator = build_ti_indicator(row)
        print(f"POST {GRAPH_URL}")
        print(f"  Body: {json.dumps(indicator, indent=2)}")

        if dry_run or not GRAPH_TOKEN:
            print("  [DRY RUN] — not sent. Set GRAPH_ACCESS_TOKEN to submit for real.\n")
            continue

        import requests
        resp = requests.post(
            GRAPH_URL,
            headers={"Authorization": f"Bearer {GRAPH_TOKEN}", "Content-Type": "application/json"},
            json=indicator,
            timeout=15,
        )
        print(f"  Response: {resp.status_code}\n")


if __name__ == "__main__":
    submit(dry_run=True)
