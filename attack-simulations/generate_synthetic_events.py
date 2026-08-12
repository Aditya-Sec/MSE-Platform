"""
Generates SYNTHETIC log events shaped exactly like what each of this
project's 7 runbook scenarios' KQL detections expects — for testing
detection logic against known-good/known-bad data, NOT real attack
tooling. Nothing here touches a real system, sends real traffic, or
performs any actual malicious action; it produces JSON matching the
schema Sentinel tables use, so a detection rule's logic can be validated
against a case that should fire and a case that shouldn't.

This is deliberately data-generation only — the responsible way to test
detection coverage without needing (or building) real attack capability.
"""

import json
import random
from datetime import datetime, timedelta, timezone


def _now_iso(offset_minutes=0):
    return (datetime.now(timezone.utc) + timedelta(minutes=offset_minutes)).isoformat()


def simulate_password_spray(num_accounts=8, attempts_per_account=2) -> list:
    """Shape matches SigninLogs — many distinct accounts, few attempts each,
    same source IP. Should trigger password-spray-pattern.kql; a single
    account with many attempts should NOT (that's brute force, a different
    pattern the same rule deliberately distinguishes)."""
    events = []
    source_ip = "198.51.100.77"
    for i in range(num_accounts):
        for attempt in range(attempts_per_account):
            events.append({
                "TimeGenerated": _now_iso(offset_minutes=-random.randint(0, 30)),
                "UserPrincipalName": f"user{i}@domain.example",
                "IPAddress": source_ip,
                "ResultType": "50126",  # invalid credentials
                "AppDisplayName": "Office 365",
            })
    return events


def simulate_ti_watchlist_match() -> list:
    """Shape matches DeviceNetworkEvents — a connection to an IP that IS on
    the ThreatIntelIOCs watchlist. Should trigger ti-watchlist-match.kql."""
    return [{
        "TimeGenerated": _now_iso(),
        "DeviceName": "FIN-WORKSTATION-07",
        "RemoteIP": "185.220.101.45",  # matches sentinel-ti-watchlist.json sample row
        "RemoteIPType": "Public",
        "RemotePort": 443,
    }]


def simulate_benign_control() -> list:
    """A normal sign-in — single account, single attempt, known-good IP.
    Should NOT trigger any detection. Testing what shouldn't fire matters
    as much as testing what should — same discipline as this profile's
    other detection test suites."""
    return [{
        "TimeGenerated": _now_iso(),
        "UserPrincipalName": "regular.employee@domain.example",
        "IPAddress": "10.10.2.15",  # internal, matches this project's workload subnet range
        "ResultType": "0",  # success
        "AppDisplayName": "Office 365",
    }]


SCENARIOS = {
    "password-spray": simulate_password_spray,
    "ti-watchlist-match": simulate_ti_watchlist_match,
    "benign-control": simulate_benign_control,
}


if __name__ == "__main__":
    import sys
    scenario = sys.argv[1] if len(sys.argv) > 1 else "password-spray"
    if scenario not in SCENARIOS:
        print(f"Unknown scenario '{scenario}'. Options: {list(SCENARIOS.keys())}")
        sys.exit(1)

    events = SCENARIOS[scenario]()
    print(f"Generated {len(events)} synthetic event(s) for scenario: {scenario}\n")
    print(json.dumps(events, indent=2))
