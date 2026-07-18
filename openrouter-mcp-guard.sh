#!/bin/zsh
# PreToolUse hook: require EXPLICIT user approval before any OpenRouter MCP tool
# call that spends OpenRouter (paid) credits.
#
# The Bash credit-guard.sh only covers shell commands hitting openrouter.ai /
# OR_MODEL= / openrouter/cc. MCP tool calls aren't Bash, so they bypassed it —
# this hook closes that gap.
#
# Registered in ~/.claude/settings.json with a matcher scoped to the paid tools:
#   mcp__openrouter__(generate-image|generate-speech|transcribe-audio|send-message)
# so this script only fires for cost-incurring calls and can unconditionally ask.
#
# Emits an "ask" decision -> the harness prompts the user to confirm the spend
# before the call runs. Read-only OpenRouter MCP tools (list-*, get-*, ping,
# search-docs, view-skills) are NOT matched and run without a prompt.

tool=$(cat | /usr/bin/python3 -c "import json,sys; print(json.load(sys.stdin).get('tool_name',''))" 2>/dev/null)

cat <<JSON
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"'$tool' spends OpenRouter (paid) credits (image / speech / transcription / model generation). Approve to incur this cost, or decline to route it elsewhere (e.g. the free local model)."}}
JSON
exit 0
