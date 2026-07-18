#!/bin/zsh
# One-command setup: OpenRouter-backed Claude Code on a fresh machine.
#
#   git clone <this-repo> && ./or-github/setup.sh
#
# What it does:
#   1. Creates ./openrouter/ in the folder you ran this from (cc, credit-guard.sh, .env)
#   2. Prompts for your OpenRouter API key and writes .env (skips if .env exists)
#   3. Adds the or-* aliases to ~/.zshrc (idempotent)
#   4. Registers the credit-guard PreToolUse hook in ~/.claude/settings.json
#   5. Tells you to: source ~/.zshrc

set -e

SCRIPT_DIR="${0:A:h}"          # where the cloned repo lives
INSTALL_PARENT="$PWD"          # openrouter/ goes where the command was run from
INSTALL_DIR="$INSTALL_PARENT/openrouter"
ZSHRC="$HOME/.zshrc"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"

echo "==> Installing into $INSTALL_DIR"

# --- Prereqs ----------------------------------------------------------------
if ! command -v claude >/dev/null 2>&1; then
  echo "WARNING: 'claude' CLI not found on PATH."
  echo "         Install Claude Code first: https://claude.com/claude-code"
  echo "         (continuing anyway — aliases will work once it's installed)"
fi
if ! command -v /usr/bin/python3 >/dev/null 2>&1; then
  echo "ERROR: /usr/bin/python3 not found (needed by credit-guard.sh)." >&2
  exit 1
fi

# --- 1. openrouter/ folder ----------------------------------------------------
mkdir -p "$INSTALL_DIR"
cp "$SCRIPT_DIR/cc" "$INSTALL_DIR/cc"
cp "$SCRIPT_DIR/credit-guard.sh" "$INSTALL_DIR/credit-guard.sh"
chmod +x "$INSTALL_DIR/cc" "$INSTALL_DIR/credit-guard.sh"
echo "    copied cc + credit-guard.sh"

# --- 2. .env ------------------------------------------------------------------
if [[ -f "$INSTALL_DIR/.env" ]]; then
  echo "==> .env already exists — leaving it untouched"
else
  echo "==> Creating .env"
  echo ""
  echo "    Get your key at https://openrouter.ai/keys (starts with sk-or-v1-...)"
  echo "    The file will look like this:"
  echo ""
  echo "      OPENROUTER_API_KEY=sk-or-v1-xxxx...."
  echo ""
  printf "    Paste your OpenRouter API key: "
  read -r api_key
  if [[ -z "$api_key" ]]; then
    echo "ERROR: no key entered. Re-run setup.sh to try again." >&2
    exit 1
  fi
  umask 077
  cat > "$INSTALL_DIR/.env" <<EOF
# claude-code-router / OpenRouter credentials
# Get your key at https://openrouter.ai/keys  (starts with sk-or-v1-...)
# One key covers all models: Opus, Kimi, Codex, etc.

OPENROUTER_API_KEY=$api_key
EOF
  echo "    wrote $INSTALL_DIR/.env (chmod 600)"
fi

# --- 3. zshrc aliases -----------------------------------------------------------
ALIAS_BLOCK="# OpenRouter-backed Claude Code launchers (see $INSTALL_DIR)
alias or-opus='OR_MODEL=anthropic/claude-opus-4.8 $INSTALL_DIR/cc'
alias or-kimi-k3='OR_MODEL=moonshotai/kimi-k3 $INSTALL_DIR/cc'
alias or-gpt='OR_MODEL=openai/gpt-5.3-codex $INSTALL_DIR/cc'"

touch "$ZSHRC"
if grep -q "OR_MODEL=anthropic/claude-opus-4.8" "$ZSHRC" 2>/dev/null; then
  echo "==> Aliases already in $ZSHRC — skipping"
else
  echo "==> Adding aliases to $ZSHRC"
  printf '\n%s\n' "$ALIAS_BLOCK" >> "$ZSHRC"
fi

# --- 4. credit-guard hook in ~/.claude/settings.json -----------------------------
echo "==> Registering credit-guard PreToolUse hook"
INSTALL_DIR="$INSTALL_DIR" /usr/bin/python3 - <<'PY'
import json, os, sys

path = os.path.expanduser("~/.claude/settings.json")
guard = os.path.join(os.environ["INSTALL_DIR"], "credit-guard.sh")

cfg = {}
if os.path.exists(path):
    with open(path) as f:
        try:
            cfg = json.load(f)
        except json.JSONDecodeError:
            print(f"    WARNING: {path} is not valid JSON — skipping hook registration")
            sys.exit(0)

hooks = cfg.setdefault("hooks", {})
pre = hooks.setdefault("PreToolUse", [])

already = any(
    h.get("command") == guard
    for entry in pre
    for h in entry.get("hooks", [])
)
if already:
    print("    hook already registered — skipping")
else:
    pre.append({
        "matcher": "Bash",
        "hooks": [{"type": "command", "command": guard}],
    })
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        json.dump(cfg, f, indent=2)
        f.write("\n")
    print(f"    added to {path}")
PY

# --- 5. OpenRouter MCP setup -------------------------------------------------------
echo "==> Setting up OpenRouter MCP"
echo ""
echo "    The OpenRouter MCP allows Claude Code to route requests through OpenRouter."
echo "    This is REQUIRED for the or-* aliases to work properly."
echo ""
printf "    Do you want to install/configure the openrouter MCP now? (y/n): "
read -r install_mcp
if [[ "$install_mcp" =~ ^[Yy]$ ]]; then
  echo ""
  echo "    1. Open Claude Code settings: ~/.claude/settings.json"
  echo "    2. Add the following to the 'mcpServers' section:"
  echo ""
  cat <<'MCP_CONFIG'
    "openrouter": {
      "command": "node",
      "args": ["path/to/openrouter-mcp/index.js"],
      "env": {
        "OPENROUTER_API_KEY": "sk-or-v1-...",
        "OR_MODEL": "anthropic/claude-opus-4.8"
      }
    }
MCP_CONFIG
  echo ""
  echo "    3. Save and restart Claude Code"
  echo "    4. Verify MCP is connected: /mcp list"
  echo ""
  printf "    Press Enter when MCP is confirmed connected: "
  read -r
  echo "    ✓ OpenRouter MCP confirmed!"
else
  echo "    Skipping MCP setup (you can add it later)"
fi

# --- 6. cleanup instructions -------------------------------------------------------
echo ""
echo "==> Installation complete!"
echo ""
echo "    ✓ openrouter/ folder installed at: $INSTALL_PARENT/openrouter"
echo "    ✓ Aliases configured in: $ZSHRC"
echo "    ✓ Credit-guard hook registered in: $CLAUDE_SETTINGS"
echo ""
echo "Next steps:"
echo ""
echo "    1. Reload shell configuration:"
echo "       source ~/.zshrc"
echo ""
echo "    2. Launch Claude Code on any model:"
echo "       or-kimi-k3     # Kimi K3 (default)"
echo "       or-opus        # Claude Opus 4.8"
echo "       or-gpt         # GPT-5.3 Codex"
echo ""
echo "    3. Switch models mid-session with: /model <slug-from-openrouter.ai/models>"
echo ""
echo "    ⚠️  IMPORTANT: After confirming everything works, you can delete or-github:"
echo "       rm -rf $SCRIPT_DIR"
echo ""
echo "       The openrouter/ folder at $INSTALL_DIR will remain and continue to work."
