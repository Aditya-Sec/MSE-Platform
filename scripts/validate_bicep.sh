#!/usr/bin/env bash
# Compiles every .bicep file in this repo with the real Bicep CLI and fails
# loudly if any of them don't compile clean. Requires the Bicep CLI:
#   curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64
#   chmod +x bicep && sudo mv bicep /usr/local/bin/
# (or use the Azure CLI's built-in `az bicep build` if you have az installed)

set -e

BICEP_BIN="${BICEP_BIN:-bicep}"
FAILED=0
COUNT=0

echo "Validating all Bicep templates with: $($BICEP_BIN --version)"
echo ""

for f in $(find bicep -name "*.bicep" | sort); do
  COUNT=$((COUNT+1))
  if $BICEP_BIN build "$f" --stdout > /dev/null 2>/tmp/bicep_err.log; then
    echo "✅ PASS — $f"
  else
    echo "❌ FAIL — $f"
    cat /tmp/bicep_err.log
    FAILED=$((FAILED+1))
  fi
done

echo ""
echo "$((COUNT-FAILED))/$COUNT Bicep files compiled clean."

if [ $FAILED -gt 0 ]; then
  exit 1
fi
