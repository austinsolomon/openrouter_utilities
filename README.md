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

1. **Create `./.openrouter/`** in your current directory
   - `cc` — OpenRouter launcher script
   - `credit-guard.sh` — Spending limiter hook (Bash commands)
   - `openrouter-mcp-guard.sh` — Spending limiter hook (paid OpenRouter MCP tools)
   - `.env` — Your OpenRouter API key (chmod 600)

   > The install folder is **dot-prefixed** (`.openrouter`): hidden from `ls`/Finder
   > and it sorts *above* numbered project folders (e.g. `1_current_projects`), so it
   > stays out of your everyday clutter while sitting right at the top when you look.

2. **Configure your shell** (auto-detects bash/zsh)
   - Adds `or-opus`, `or-kimi-k3`, `or-gpt` aliases
   - Updates `~/.zshrc` or `~/.bashrc`
   - Every alias launches with `--strict-mcp-config`, so **the `or-*` sessions load
     no MCP servers** (see [Aliases & MCP behavior](#-aliases--mcp-behavior) below)

3. **Register guard hooks** in `~/.claude/settings.json`
   - Prevents accidental credit spending
   - `credit-guard` requires manual approval for credit-spending Bash commands
   - `openrouter-mcp-guard` prompts before paid OpenRouter MCP calls
     (`generate-image`, `generate-speech`, `transcribe-audio`, `send-message`)

4. **Test model connectivity**
   - Verifies `or-opus`, `or-kimi-k3`, `or-gpt` work
   - Reports any connectivity issues

5. **Guide OpenRouter MCP setup**
   - Step-by-step configuration instructions
   - Waits for MCP verification

6. **Prompt for cleanup**
   - Safely deletes this `or-github` repository
   - Keeps `.openrouter/` folder permanently

## 🎯 After Setup

### Source Shell Configuration
```bash
source ~/.zshrc    # or ~/.bashrc
```

### Launch Claude Code
```bash
or-kimi-k3     # Kimi K3 (default)
or-opus        # Claude Opus 4.8
or-gpt         # GPT-5.6 Sol
```

### Switch Models Mid-Session
```
/model <slug-from-openrouter.ai/models>
```

Example: `/model anthropic/claude-opus-4.8`

## 🔌 Aliases & MCP behavior

The `cc` launcher runs `claude --strict-mcp-config`, which tells Claude Code to use
**only** MCP servers passed via `--mcp-config` — and the launcher passes none. The
result:

| Command             | MCP servers loaded?                          |
|---------------------|----------------------------------------------|
| `claude` (plain)    | ✅ All servers from `~/.claude.json`         |
| `or-opus`           | ❌ None                                       |
| `or-kimi-k3`        | ❌ None                                       |
| `or-gpt`            | ❌ None                                       |

**Why:** MCP tool schemas are re-serialized into *every* model request. With a dozen
servers connected that is tens of thousands of input tokens on every turn — paid for
on each call when you're routing through OpenRouter. Stripping them keeps the `or-*`
sessions lean and cheap. Plain `claude` (going to Anthropic) is untouched and keeps
the full toolset.

**Opt specific servers back in** for a single session by passing your own config:

```bash
or-gpt --mcp-config '{"mcpServers":{"baserow_mcp":{ ... }}}'
```

Verify inside any `or-*` session with `/mcp` — it should list no servers.

## ✅ Requirements

- ✅ Claude Code CLI installed (`claude` available on PATH)
- ✅ OpenRouter API key from https://openrouter.ai/keys
- ✅ Python 3 (for credit-guard: `/usr/bin/python3` on Unix, PATH on Windows)
- ✅ Bash or Zsh shell
- ✅ Git installed (to clone repository)

## 📁 What Gets Installed

**Permanent (`~/Developer/.openrouter/`):**
- `cc` — Launcher script (runs `claude --strict-mcp-config` → no MCPs in `or-*` sessions)
- `credit-guard.sh` — Spending limiter (Bash commands)
- `openrouter-mcp-guard.sh` — Spending limiter (paid OpenRouter MCP tools)
- `.env` — API key (chmod 600, git-ignored)

**Shell Configuration:**
- `.zshrc` or `.bashrc` — Aliases for or-*, or-kimi-k3, or-gpt
- `~/.claude/settings.json` — credit-guard + openrouter-mcp-guard hooks

**Temporary (deleted after setup):**
- `or-github/` — This setup repository

## 🔧 Troubleshooting

**Models not working?**
```bash
# Check API key
cat ~/Developer/.openrouter/.env

# Test manually
or-opus "Say hello"

# Check OpenRouter credits at https://openrouter.ai/
```

**`anthropic/*` models work but `openai/*` or `moonshotai/*` 404 with
"No allowed providers are available"?**

Something in your environment is exporting a real `ANTHROPIC_API_KEY` (`sk-ant-...`).
Claude Code sends it as the `x-api-key` header, which makes OpenRouter pin the request
to the `anthropic` provider. The `cc` launcher already `unset`s it after sourcing
`.env` — if you wrap or replace `cc`, keep that line.

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

- API key stored in `~/Developer/.openrouter/.env` with `chmod 600`
- Credentials never committed to git (`.env` is git-ignored)
- Credit-guard hook prevents accidental credit spending
- Setup repository safely deleted after installation

## 📝 Notes

- Re-running `setup.sh` is safe: detects and skips existing configuration
- The `.openrouter/` folder remains and continues to work after deletion of `or-github`
- Credit-guard hook requires manual "run it" approval for spending Bash commands
- Works on macOS, Linux, and Windows (with bash/zsh)
