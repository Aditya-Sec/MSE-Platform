"""
Generates a real MITRE ATT&CK Navigator layer from the technique IDs
referenced in this project's KQL rule headers — same proven pattern used
in Sentinel-Detection-Response-Pack and SIEM-Tool-Matrix. Upload the output
to https://mitre-attack.github.io/attack-navigator/ for a visual heatmap.

Two rules are deliberately excluded from ATT&CK coverage and that's stated
here, not silently skipped: defender-cloud-posture-drift.kql uses a NIST
CSF tag instead (it detects posture drift, not an attack technique), and
privileged-signin-noncompliant-device.kql is a control-effectiveness check
for CA003 rather than a technique detection.
"""

import re
import json
from pathlib import Path

KQL_DIR = Path(__file__).parent / "kql"
OUTPUT_FILE = Path(__file__).parent / "attack_navigator_layer.json"

TECHNIQUE_PATTERN = re.compile(r"ATT&CK:\s*(T\d{4}(?:\.\d{3})?)")


def extract_techniques():
    techniques = {}
    skipped = []
    for kql_file in sorted(KQL_DIR.glob("*.kql")):
        text = kql_file.read_text()
        match = TECHNIQUE_PATTERN.search(text)
        if match:
            techniques[match.group(1)] = kql_file.stem
        else:
            skipped.append(kql_file.stem)
    return techniques, skipped


def build_layer(techniques: dict) -> dict:
    return {
        "name": "MSE-Platform — Detection Coverage",
        "versions": {"attack": "16", "navigator": "5.1", "layer": "4.5"},
        "domain": "enterprise-attack",
        "description": "Auto-generated from KQL rule headers across all phases of this repo.",
        "techniques": [
            {
                "techniqueID": tid,
                "color": "#4dd4e8",
                "comment": f"Covered by: {rule_name}.kql",
                "enabled": True,
            }
            for tid, rule_name in techniques.items()
        ],
        "gradient": {"colors": ["#0d1012", "#4dd4e8"], "minValue": 0, "maxValue": 1},
        "legendItems": [{"label": "Covered by this project", "color": "#4dd4e8"}],
    }


def main():
    techniques, skipped = extract_techniques()
    layer = build_layer(techniques)
    OUTPUT_FILE.write_text(json.dumps(layer, indent=2))

    print(f"Wrote {OUTPUT_FILE} with {len(techniques)} technique(s):")
    for tid, name in techniques.items():
        print(f"  {tid} — {name}")

    if skipped:
        print(f"\n{len(skipped)} rule(s) deliberately not ATT&CK-tagged (other frameworks or control checks):")
        for name in skipped:
            print(f"  - {name}")


if __name__ == "__main__":
    main()
