#!/bin/bash
# One-command setup: OpenRouter-backed Claude Code on a fresh machine.
#
#   git clone <this-repo> && cd or-github && ./setup.sh
#
# What it does:
#   1. Creates ../.openrouter/ (in parent directory) in the folder you ran this from
#      (cc, credit-guard.sh, openrouter-mcp-guard.sh, .env)
#      (dot-prefixed: hidden from ls/Finder and sorts above numbered project folders)
#   2. Prompts for your OpenRouter API key and writes .env (skips if .env exists)
#   3. Detects shell (zsh, bash, PowerShell) and adds aliases (idempotent)
#   4. Registers both PreToolUse guard hooks in ~/.claude/settings.json:
#        credit-guard (Bash spends) + openrouter-mcp-guard (paid MCP tool calls)
#   5. Tests each model to ensure connectivity
#   6. Guides OpenRouter MCP setup and verification
#   7. Prompts to delete or-github (this repo) after setup completes

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"     # where the cloned repo (or-github) lives
INSTALL_PARENT="$(cd "$(dirname "$SCRIPT_DIR")" && pwd)"                     # Parent directory (.openrouter/ goes here)
INSTALL_DIR="$INSTALL_PARENT/.openrouter"        # dot-prefixed: hidden + sorts to the top of the dir
CLAUDE_SETTINGS="$HOME/.claude/settings.json"

# Detect shell
if [[ -n "$ZSH_VERSION" ]]; then
  SHELL_RC="$HOME/.zshrc"
  SHELL_NAME="zsh"
elif [[ -n "$BASH_VERSION" ]]; then
  SHELL_RC="$HOME/.bashrc"
  SHELL_NAME="bash"
else
  SHELL_RC="$HOME/.bashrc"  # Default fallback
  SHELL_NAME="bash/zsh"
fi

echo "==> Installing into $INSTALL_DIR"

# --- Prereqs ----------------------------------------------------------------
if ! command -v claude >/dev/null 2>&1; then
  echo "WARNING: 'claude' CLI not found on PATH."
  echo "         Install Claude Code first: https://claude.com/claude-code"
  echo "         (continuing anyway — aliases will work once it's installed)"
fi
# Find Python 3 (works on macOS, Linux, and Windows)
# On Windows, prefer the full path to avoid shell redirection to Microsoft Store
PYTHON3=""
if command -v /usr/bin/python3 >/dev/null 2>&1; then
  PYTHON3="/usr/bin/python3"
elif ls "$HOME"/AppData/Local/Programs/Python/*/python.exe >/dev/null 2>&1; then
  # Windows Python installation
  PYTHON3="$(ls "$HOME"/AppData/Local/Programs/Python/*/python.exe 2>/dev/null | head -1)"
fi

if [[ -z "$PYTHON3" ]]; then
  if command -v python3 >/dev/null 2>&1; then
    PYTHON3="python3"
  elif command -v python >/dev/null 2>&1; then
    # Last resort - try python (may be redirected on Windows, but worth trying)
    PYTHON3="python"
  fi
fi

if [[ -z "$PYTHON3" ]]; then
  echo "ERROR: Python 3 not found (needed by credit-guard.sh)." >&2
  exit 1
fi

# --- 1. .openrouter/ folder ----------------------------------------------------
mkdir -p "$INSTALL_DIR"
cp "$SCRIPT_DIR/cc" "$INSTALL_DIR/cc"
cp "$SCRIPT_DIR/credit-guard.sh" "$INSTALL_DIR/credit-guard.sh"
cp "$SCRIPT_DIR/openrouter-mcp-guard.sh" "$INSTALL_DIR/openrouter-mcp-guard.sh"
chmod +x "$INSTALL_DIR/cc" "$INSTALL_DIR/credit-guard.sh" "$INSTALL_DIR/openrouter-mcp-guard.sh"
echo "    copied cc + credit-guard.sh + openrouter-mcp-guard.sh"

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

# --- 3. shell aliases -----------------------------------------------------------
ALIAS_BLOCK="# OpenRouter-backed Claude Code launchers (see $INSTALL_DIR)
alias or-opus='OR_MODEL=anthropic/claude-opus-4.8 $INSTALL_DIR/cc'
alias or-kimi-k3='OR_MODEL=moonshotai/kimi-k3 $INSTALL_DIR/cc'
alias or-gpt='OR_MODEL=openai/gpt-5.3-codex $INSTALL_DIR/cc'"

echo "==> Configuring $SHELL_NAME shell aliases"
touch "$SHELL_RC"
if grep -q "OR_MODEL=anthropic/claude-opus-4.8" "$SHELL_RC" 2>/dev/null; then
  echo "    Aliases already in $SHELL_RC — skipping"
else
  echo "    Adding aliases to $SHELL_RC"
  printf '\n%s\n' "$ALIAS_BLOCK" >> "$SHELL_RC"
fi

# --- 4. guard hooks in ~/.claude/settings.json -----------------------------------
echo "==> Registering PreToolUse guard hooks (credit-guard + openrouter-mcp-guard)"
INSTALL_DIR="$INSTALL_DIR" "$PYTHON3" - <<'PY'
import json, os, sys

path = os.path.expanduser("~/.claude/settings.json")
install = os.environ["INSTALL_DIR"]

# (matcher, script) pairs this installer keeps registered. credit-guard covers
# Bash commands that spend OpenRouter credits; openrouter-mcp-guard covers the
# paid OpenRouter MCP tool calls (which aren't Bash and bypass credit-guard).
guards = [
    ("Bash", os.path.join(install, "credit-guard.sh")),
    (
        "mcp__openrouter__(generate-image|generate-speech|transcribe-audio|send-message)",
        os.path.join(install, "openrouter-mcp-guard.sh"),
    ),
]

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

changed = False
for matcher, guard in guards:
    name = os.path.basename(guard)
    already = any(
        h.get("command") == guard
        for entry in pre
        for h in entry.get("hooks", [])
    )
    if already:
        print(f"    {name} already registered — skipping")
    else:
        pre.append({
            "matcher": matcher,
            "hooks": [{"type": "command", "command": guard}],
        })
        changed = True
        print(f"    registered {name}")

if changed:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        json.dump(cfg, f, indent=2)
        f.write("\n")
    print(f"    wrote {path}")
PY

# --- 5. Model Testing -------------------------------------------------------
echo "==> Testing OpenRouter models"
echo ""
echo "    Sourcing shell configuration to load aliases..."
source "$SHELL_RC" 2>/dev/null || true

if command -v claude >/dev/null 2>&1; then
  echo "    Testing model connectivity (this may take a moment)..."
  echo ""

  # Export env for testing
  export OPENROUTER_API_KEY=$(grep OPENROUTER_API_KEY "$INSTALL_DIR/.env" | cut -d= -f2)
  export OR_MODEL="anthropic/claude-opus-4.8"

  models=("or-opus:anthropic/claude-opus-4.8" "or-kimi-k3:moonshotai/kimi-k3" "or-gpt:openai/gpt-5.3-codex")
  for model_pair in "${models[@]}"; do
    IFS=: read -r name slug <<< "$model_pair"
    printf "    Testing %-15s ... " "$name"
    if timeout 10 "$INSTALL_DIR/cc" "Say 'working'" > /dev/null 2>&1; then
      echo "✓"
    else
      echo "⚠ (may be rate-limited, check manually later)"
    fi
    export OR_MODEL="$slug"
  done
else
  echo "    Claude CLI not found — skipping model tests"
  echo "    You can test models manually after setup completes"
fi

# --- 7. OpenRouter MCP setup -------------------------------------------------------
echo ""
echo "==> Setting up OpenRouter MCP"
echo ""
echo "    The OpenRouter MCP allows Claude Code to route requests through OpenRouter."
echo "    This is REQUIRED for the or-* aliases to work properly."
echo ""
printf "    Do you want to install/configure the openrouter MCP now? (y/n): "
read -r install_mcp
if [[ "$install_mcp" =~ ^[Yy]$ ]]; then
  echo ""
  echo "    📋 MCP Configuration Steps:"
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
  echo "    ⚠️  Skipping MCP setup (you can add it later)"
fi

# --- 8. Cleanup -------------------------------------------------------
echo ""
echo "==> Installation complete! ✅"
echo ""
echo "    ✓ .openrouter/ folder installed at: $INSTALL_DIR"
echo "    ✓ Aliases configured in: $SHELL_RC"
echo "    ✓ Credit-guard hook registered in: $CLAUDE_SETTINGS"
echo ""
echo "Next steps:"
echo ""
echo "    1. Reload shell configuration:"
echo "       source $SHELL_RC"
echo ""
echo "    2. Launch Claude Code on any model:"
echo "       or-kimi-k3     # Kimi K3 (default)"
echo "       or-opus        # Claude Opus 4.8"
echo "       or-gpt         # GPT-5.3 Codex"
echo ""
echo "    3. Switch models mid-session with: /model <slug-from-openrouter.ai/models>"
echo ""


# --- 9. Cleanup or-github -------------------------------------------------------
echo ""
echo "==> Ready to clean up setup repository"
echo ""
echo "    The .openrouter/ folder at $INSTALL_DIR will remain and continue to work."
echo "    The or-github setup repository can now be safely deleted."
echo ""
printf "    Delete the or-github folder? (y/n): "
read -r cleanup
if [[ "$cleanup" == "y" || "$cleanup" == "Y" ]]; then
  if [[ -d "$SCRIPT_DIR/.git" ]]; then
    echo ""
    echo "    Deleting or-github repository..."
    rm -rf "$SCRIPT_DIR"
    
    if [[ ! -d "$SCRIPT_DIR" ]]; then
      echo "    ✓ Successfully deleted or-github"
      echo ""
      echo "Setup complete! Your .openrouter/ installation at:"
      echo "  $INSTALL_DIR"
      echo ""
      echo "is ready to use. You can now:"
      echo "  1. Source your shell config: source $SHELL_RC"
      echo "  2. Use the aliases: or-kimi-k3, or-opus, or-gpt"
    else
      echo "    ⚠️  Could not delete directory. Please manually delete:"
      echo "       rm -rf $SCRIPT_DIR"
    fi
  else
    echo "    ⚠️  Could not verify git repository. Please manually delete:"
    echo "       rm -rf $SCRIPT_DIR"
  fi
else
  echo "    Keeping or-github folder for reference"
  echo ""
  echo "To delete it later, run:"
  echo "    rm -rf $SCRIPT_DIR"
fi
