# or-github

One-command setup for OpenRouter-backed Claude Code on a fresh machine.
Replicates: the `openrouter/` launcher folder, the `or-*` zsh aliases, and the
credit-guard PreToolUse hook.

## The one command

Clone, then run `setup.sh` **from the folder where you want `openrouter/` to live**
(e.g. `~/Developer`):

```zsh
git clone <this-repo-url> && ./or-github/setup.sh
```

The script will:

1. Create `./openrouter/` (in the folder you ran the command from) containing:
   - `cc` — the launcher that points Claude Code at OpenRouter
   - `credit-guard.sh` — blocks credit-spending commands until you say "run it"
2. Prompt you to paste your **OpenRouter API key**
   ([get one here](https://openrouter.ai/keys), starts with `sk-or-v1-...`) and write
   `openrouter/.env` in this format:
   ```
   OPENROUTER_API_KEY=sk-or-v1-xxxx....
   ```
   (If `.env` already exists, it's left untouched.)
3. Append these aliases to your `~/.zshrc` (skips if already present):
   ```zsh
   alias or-opus='OR_MODEL=anthropic/claude-opus-4.8 <path>/openrouter/cc'
   alias or-kimi-k3='OR_MODEL=moonshotai/kimi-k3 <path>/openrouter/cc'
   alias or-gpt='OR_MODEL=openai/gpt-5.3-codex <path>/openrouter/cc'
   ```
4. Register `credit-guard.sh` as a PreToolUse hook in `~/.claude/settings.json`
   (merges into existing settings, skips if already registered).

## After setup

```zsh
source ~/.zshrc
```

Then:

```zsh
or-kimi-k3     # Claude Code on Kimi K3 (default)
or-opus        # Claude Code on Claude Opus 4.8
or-gpt         # Claude Code on GPT-5.3 Codex
```

Switch models mid-session without exiting:

```
/model <any-slug-from-https://openrouter.ai/models>
```

## Prerequisites

- macOS with zsh and `/usr/bin/python3` (both standard)
- [Claude Code](https://claude.com/claude-code) installed (`claude` on PATH)
- An OpenRouter API key

## Notes

- `.env` is git-ignored and created with `chmod 600` — your key never enters the repo.
- Re-running `setup.sh` is safe: existing `.env`, aliases, and hook are detected and skipped.
- The credit-guard hook makes Claude ask for an explicit "run it" before any Bash
  command that would spend OpenRouter credits.
