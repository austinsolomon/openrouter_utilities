# 🚀 or-github — OpenRouter Setup

Complete one-click setup for OpenRouter-backed Claude Code with automatic model testing, MCP configuration, and cleanup.

## ⚡ Quick Start (Recommended)

From Claude Code, run the setup skill:

```
/setup-openrouter
```

The skill will interactively guide you through:
- Environment detection (OS + shell)
- OpenRouter API key configuration
- Shell alias setup (auto-detects bash/zsh)
- Model connectivity testing
- OpenRouter MCP installation & verification
- Safe cleanup of this repository

## 📋 Manual Setup (Alternative)

If you prefer to run the setup script directly:

```bash
git clone <this-repo-url> ~/Developer/or-github
cd ~/Developer/or-github
./setup.sh
```

The `setup.sh` script will:

1. **Create `./openrouter/`** in your current directory
   - `cc` — OpenRouter launcher script
   - `credit-guard.sh` — Spending limiter hook
   - `.env` — Your OpenRouter API key (chmod 600)

2. **Configure your shell** (auto-detects bash/zsh)
   - Adds `or-opus`, `or-kimi-k3`, `or-gpt` aliases
   - Updates `~/.zshrc` or `~/.bashrc`

3. **Register credit-guard hook** in `~/.claude/settings.json`
   - Prevents accidental credit spending
   - Requires manual approval for Bash commands

4. **Test model connectivity**
   - Verifies `or-opus`, `or-kimi-k3`, `or-gpt` work
   - Reports any connectivity issues

5. **Guide OpenRouter MCP setup**
   - Step-by-step configuration instructions
   - Waits for MCP verification

6. **Prompt for cleanup**
   - Safely deletes this `or-github` repository
   - Keeps `openrouter/` folder permanently

## 🎯 After Setup

### Source Shell Configuration
```bash
source ~/.zshrc    # or ~/.bashrc
```

### Launch Claude Code
```bash
or-kimi-k3     # Kimi K3 (default)
or-opus        # Claude Opus 4.8
or-gpt         # GPT-5.3 Codex
```

### Switch Models Mid-Session
```
/model <slug-from-openrouter.ai/models>
```

Example: `/model anthropic/claude-opus-4.8`

## ✅ Requirements

- ✅ Claude Code CLI installed (`claude` available on PATH)
- ✅ OpenRouter API key from https://openrouter.ai/keys
- ✅ Python 3 (for credit-guard: `/usr/bin/python3` on Unix, PATH on Windows)
- ✅ Bash or Zsh shell
- ✅ Git installed (to clone repository)

## 📁 What Gets Installed

**Permanent (`~/Developer/openrouter/`):**
- `cc` — Launcher script
- `credit-guard.sh` — Spending limiter
- `.env` — API key (chmod 600, git-ignored)

**Shell Configuration:**
- `.zshrc` or `.bashrc` — Aliases for or-*, or-kimi-k3, or-gpt
- `~/.claude/settings.json` — credit-guard hook

**Temporary (deleted after setup):**
- `or-github/` — This setup repository

## 🔧 Troubleshooting

**Models not working?**
```bash
# Check API key
cat ~/Developer/openrouter/.env

# Test manually
or-opus "Say hello"

# Check OpenRouter credits at https://openrouter.ai/
```

**Aliases not found?**
```bash
# Reload shell
source ~/.zshrc  # or ~/.bashrc

# Verify aliases
grep "or-opus" ~/.zshrc
```

**MCP won't connect?**
- Check `~/.claude/settings.json` for correct MCP server path
- Verify OpenRouter API key in `.env`
- Restart Claude Code and run `/mcp list`

**Permission denied?**
```bash
chmod +x ~/Developer/or-github/setup.sh
./setup.sh
```

## 🔐 Security

- API key stored in `~/.openrouter/.env` with `chmod 600`
- Credentials never committed to git (`.env` is git-ignored)
- Credit-guard hook prevents accidental credit spending
- Setup repository safely deleted after installation

## 📝 Notes

- Re-running `setup.sh` is safe: detects and skips existing configuration
- The `openrouter/` folder remains and continues to work after deletion of `or-github`
- Credit-guard hook requires manual "run it" approval for spending Bash commands
- Works on macOS, Linux, and Windows (with bash/zsh)
