#!/bin/zsh
# PreToolUse (Bash) hook: block commands that draw OpenRouter (paid) credits
# unless they carry the CREDIT_OK=1 approval marker.
#
# Flow: Claude proposes a credit-drawing command -> this hook DENIES it ->
# Claude asks the user for an explicit "run it" -> on approval Claude re-runs
# the exact command prefixed with `CREDIT_OK=1 ` -> hook allows it.
#
# `deny` is authoritative in every permission mode (including dangerous mode),
# so it can't be silently bypassed.

input=$(cat)
cmd=$(printf '%s' "$input" | /usr/bin/python3 -c "import json,sys; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null)

# Does this command spend OpenRouter credits?
if printf '%s' "$cmd" | grep -qiE 'openrouter\.ai|OR_MODEL=|openrouter/cc'; then
  # Already approved for this run?
  if ! printf '%s' "$cmd" | grep -q 'CREDIT_OK=1'; then
    cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"BLOCKED: this command draws OpenRouter (paid) credits. Ask the user for an explicit \"run it\" first. After they approve, re-run the exact command prefixed with `CREDIT_OK=1 `."}}
JSON
    exit 0
  fi
fi
exit 0
