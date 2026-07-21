#!/bin/bash
# Launch Claude Code with OpenRouter as the backend (one endpoint, all models).
#
#   ./cc                                  # default model (Kimi K3)
#   OR_MODEL=anthropic/claude-opus-4.8 ./cc
#   OR_MODEL=openai/gpt-5.6-sol ./cc
#   ./cc --resume        (or -c)          # resume a prior session, same brain rules
#
# Switch brains MID-SESSION without exiting:
#   /model moonshotai/kimi-k3
#   /model anthropic/claude-opus-4.8
#   /model openai/gpt-5.6-sol
# (any slug from https://openrouter.ai/models works — same session continues)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load OPENROUTER_API_KEY. Prefer the .env installed next to this script; fall back
# to a canonical workspace .env if you keep one central credentials file instead.
set -a
if [[ -f "$SCRIPT_DIR/.env" ]]; then
  source "$SCRIPT_DIR/.env"
elif [[ -f "$HOME/Developer/.env" ]]; then
  source "$HOME/Developer/.env"
else
  echo "ERROR: no .env found (looked in $SCRIPT_DIR and $HOME/Developer)." >&2
  exit 1
fi
set +a

# CRITICAL: a shared .env often also defines ANTHROPIC_API_KEY (a real sk-ant-...
# key). If it reaches Claude Code it is sent as `x-api-key`, which makes OpenRouter
# pin the request to the `anthropic` provider — so anthropic/* models work but
# openai/* and moonshotai/* 404 with "No allowed providers are available".
# We authenticate to OpenRouter via ANTHROPIC_AUTH_TOKEN (Bearer) only, so drop it.
unset ANTHROPIC_API_KEY

MODEL="${OR_MODEL:-moonshotai/kimi-k3}"

export ANTHROPIC_BASE_URL="https://openrouter.ai/api"
export ANTHROPIC_AUTH_TOKEN="$OPENROUTER_API_KEY"
export ANTHROPIC_MODEL="$MODEL"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="$MODEL"    # background/fast calls
export ANTHROPIC_SMALL_FAST_MODEL="$MODEL"        # legacy name, harmless

# --strict-mcp-config: load ONLY MCP servers passed via --mcp-config (none here),
# ignoring every user/project-scope server in ~/.claude.json. Keeps or-* sessions
# free of the MCP tool-schema overhead (~tens of k input tokens/turn) that plain
# `claude` carries. Pass `--mcp-config '{...}'` after the alias to opt specific
# servers back in for a single session.
exec claude --strict-mcp-config "$@"
