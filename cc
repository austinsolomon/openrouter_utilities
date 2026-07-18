#!/bin/zsh
# Launch Claude Code with OpenRouter as the backend (one endpoint, all models).
#
#   ./cc                                  # default model (Kimi K3)
#   OR_MODEL=anthropic/claude-opus-4.8 ./cc
#   OR_MODEL=openai/gpt-5.3-codex ./cc
#   ./cc --resume        (or -c)          # resume a prior session, same brain rules
#
# Switch brains MID-SESSION without exiting:
#   /model moonshotai/kimi-k3
#   /model anthropic/claude-opus-4.8
#   /model openai/gpt-5.3-codex
# (any slug from https://openrouter.ai/models works — same session continues)

set -a
source "${0:A:h}/.env"          # loads OPENROUTER_API_KEY
set +a

MODEL="${OR_MODEL:-moonshotai/kimi-k3}"

export ANTHROPIC_BASE_URL="https://openrouter.ai/api"
export ANTHROPIC_AUTH_TOKEN="$OPENROUTER_API_KEY"
export ANTHROPIC_MODEL="$MODEL"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="$MODEL"    # background/fast calls
export ANTHROPIC_SMALL_FAST_MODEL="$MODEL"        # legacy name, harmless

exec claude "$@"
