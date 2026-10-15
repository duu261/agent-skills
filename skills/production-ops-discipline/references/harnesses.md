# Harness mapping

The core skill is harness-neutral. This file maps it to specific harnesses. Checked against vendor docs on 2026-10-16. Harnesses change fast; when the live docs differ, trust the docs.

## Install locations

| Harness | User skills | Project skills |
|---|---|---|
| Claude Code | `~/.claude/skills/production-ops-discipline/` | `.claude/skills/production-ops-discipline/` |
| Codex | `~/.agents/skills/production-ops-discipline/` | `<repo>/.agents/skills/production-ops-discipline/` |
| Hermes Agent | `~/.hermes/skills/production-ops-discipline/` | n/a |
| Other Agent Skills harnesses | the harness's skills directory | |

## Claude Code

| Job | Tool |
|---|---|
| Read a file | `Read` |
| Edit or create a file | `Edit`, `Write` |
| Shell | `Bash` |
| Fetch a page | `WebFetch` |
| Reviewer subagent | `Agent` |

- **Search goes through the shell by default.** On macOS, Linux, and WSL, `Grep` and `Glob` are left out of the default tool set, and Claude Code searches with `grep` and `find` through `Bash` (embedded `ugrep` and `bfs`). That is the intended path there, not a slip. Reads and edits still go through `Read` and `Edit`.
- **`cd` persists in the main session** for later `Bash` calls while it stays inside the project or an added directory. Subagents never carry it over. For production targets, still prefer absolute paths or `cd dir && cmd` in one call, so each command reads on its own.
- **Read before edit.** Older models must `Read` a file before `Edit`; newer models may edit an unread file when reading it would not need a permission prompt. If `Edit` refuses, re-read and retry. Do not switch to `sed -i` or a heredoc through `Bash`: that is the bypass reflex this skill exists to stop.
- **Permission modes are not approval.** Auto mode, `acceptEdits`, and `bypassPermissions` reduce prompts. They are not the user naming a production change.
- **Reviewer subagents.** A subagent's `tools` field can restrict it to `Read`, `Grep`, and `Glob`, which makes "read-only" real instead of prompt-only. Prefer that for reviewers.
- **Hooks.** `PreToolUse` can block a tool call. `UserPromptSubmit` adds plain-text stdout to the context Claude sees.

### Optional delegation hook (Claude Opus 5.5)

**Problem.** Claude Opus 5.5 rarely spawns subagents or asks another model for review on its own initiative, even when the skill, project instructions (`CLAUDE.md`, `AGENTS.md`), or a system prompt tell it to. In the field notes it delegated reliably only when the latest user message itself said to use another model. Community reports describe a post-release fix in the Opus 5 line that stops the model from calling subagents autonomously, after autonomous subagents burned through usage limits. That cause is reported, not confirmed by Anthropic; the behavior is what was observed.

**Why a hook.** Standing rules are not read as a user request for this decision. A per-turn hook puts the directive next to the user's latest message, which is where the model looks for permission. In the field notes, delegation stayed at 0.28 subagent calls per session with the skill and standing rules, then rose to 1.63 after the hook (see [evidence.md](evidence.md)). The hook there was appended to the user turn without a label; a labeled "system note" was more likely to be skimmed as not coming from the user.

**Claude Code.** In `~/.claude/settings.json` or `.claude/settings.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Reviewer required before any production change, install, push, or deploy. Delegate bulk reads and parallel research freely.'"
          }
        ]
      }
    ]
  }
}
```

- It fires on every turn. That is the point: the permission has to arrive with each message, and it keeps the reviewer trigger hard to forget.
- Claude Code injects hook output as a system reminder that starts with the hook's name, not as the user's own text. Whether that carries the same weight for Opus 5.5 as the unlabeled Hermes version is untested. The planned A/B checks it.
- `UserPromptSubmit` input has no model field, so the hook cannot filter by model. Install it only in setups that run Opus 5.5. Other models delegate without it and only pay the extra tokens.
- Drop "Delegate bulk reads and parallel research freely" if you only want reviews and not extra subagent spend.

## Codex

- Skills load from `<repo>/.agents/skills` and `~/.agents/skills`.
- Hooks live in `~/.codex/hooks.json` or `<repo>/.codex/hooks.json` (or inline `[hooks]` in `config.toml`). Events include `UserPromptSubmit` and `PreToolUse`. Non-managed hooks must be reviewed and trusted before they run.
- GPT-family models tend to be strict already. The "Do not over-correct" section matters most here.

## Hermes Agent

| Job | Tool |
|---|---|
| Read a file | `read_file` |
| Search | `search_files` |
| Edit or create a file | `patch`, `write_file` |
| Shell | `terminal` with `workdir` |
| Probe script | `execute_code` |
| Fetch a page | `web_extract` |
| Reviewer subagent | `delegate_task` |

- `patch` and `write_file` write a temp file and rename it, which replaces the inode. Use the staged-copy and `cp` pattern for bind-mounted files.
- `write_file` refuses a file that changed since it was read. Re-read, then write.
- `delegate_task` children inherit the parent's toolsets minus a blocked list, so "read-only" is prompt-only.
- Hermes adds extra execution guidance for GPT-like model names by default, and none for Claude. Claude models start with less rule pressure there, so this skill fills more of the gap.
- Delegation hook equivalent: a plugin on the `pre_llm_call` hook that returns `{"context": "<reminder>"}` when the model name matches `opus-5-5` or `opus-5.5`, and returns nothing for subagent sessions (`parent_session_id` set), since those cannot delegate. The context rides the user turn, unlabeled.

## Any other harness

Find the harness's read, search, edit, shell (with working directory), fetch, and subagent tools. Where a harness has no dedicated tool for a job, the shell is fine for that job. Keep every other default.
