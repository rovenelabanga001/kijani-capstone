#!/usr/bin/env bash
# diagnose-failure.sh
# Collects basic diagnostic data after a smoke test failure
# and sends it to Claude for analysis.
#
# GOVERNANCE: Output is advisory only. A human reviews it

NAMESPACE="${1:-kijani-staging}"

echo "=== Collecting diagnostics from ${NAMESPACE} ==="

# Collect the three most useful signals
POD_STATUS=$(kubectl get pods -n "${NAMESPACE}" -l app=kk-payments 2>/dev/null)
RECENT_EVENTS=$(kubectl get events -n "${NAMESPACE}" --sort-by='.lastTimestamp' 2>/dev/null | tail -10)
POD_LOGS=$(kubectl logs -n "${NAMESPACE}" -l app=kk-payments --tail=20 2>/dev/null)

echo "=== Asking Claude to diagnose ==="

# Build the prompt
PROMPT="A Kubernetes smoke test just failed in namespace ${NAMESPACE}.
Here is the diagnostic data:

POD STATUS:
${POD_STATUS}

RECENT EVENTS:
${RECENT_EVENTS}

POD LOGS:
${POD_LOGS}

In under 150 words: what is the most likely cause and what should the engineer check first?"

# Call Claude API
RESPONSE=$(curl -s https://api.anthropic.com/v1/messages \
  -H "Content-Type: application/json" \
  -H "x-api-key: ${ANTHROPIC_API_KEY}" \
  -H "anthropic-version: 2023-06-01" \
  -d "{
    \"model\": \"claude-sonnet-4-20250514\",
    \"max_tokens\": 300,
    \"messages\": [{
      \"role\": \"user\",
      \"content\": $(echo "${PROMPT}" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')
    }]
  }")

# Extract and print the diagnosis
echo ""
echo "============================================"
echo "  AI DIAGNOSIS — HUMAN REVIEW REQUIRED"
echo "============================================"
echo "${RESPONSE}" | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(data['content'][0]['text'])
"
echo "============================================"
echo "  Do not rollback based on this alone."
echo "  Review the raw data above first."
echo "============================================"
