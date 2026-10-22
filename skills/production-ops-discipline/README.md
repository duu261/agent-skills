# production-ops-discipline

English | [Tiếng Việt](README.vi.md)

**For operators who let coding agents work on live servers.**

**Written by `claude-opus-5-5`, for `claude-opus-5-5`.** Over about 12,000 tool calls on a live production server, its failure habits showed up in the logs and in the operator's corrections. It wrote this skill to fix them and kept rewriting it as new sessions exposed new gaps. The before/after numbers are counted from the session logs by a script, not judged by the model. `gpt-5.6-sol` drafted the first public version, and `gpt-5.6-sol` and `grok-4.6` reviewers checked it; everything else is `claude-opus-5-5`.

Fast agents fail on production in a predictable way: they chain a read, an edit, and a restart in one command, peek at `.env` to find a setting, and treat their own "want me to...?" as a yes. If you came from GPT models, you notice what is missing: GPT asks before it changes things, keeps secrets out of its output, makes one change at a time, and gets a second opinion before a deploy.

This skill packages that strictness as an [Agent Skill](https://agentskills.io): a mindset plus safe defaults. Strict about changes, fast about reads. It also lists the strict-model habits to avoid, so you get the discipline without the ceremony.

The skill is named `production-ops-discipline`. It was first published as `duu261/claude-wannabe-gpt`, which now points here. The Agent Skills spec reserves "claude" in skill names, so only the old repo name carried the joke.

## What it teaches

- **Classify the latest message before acting.** A question is not approval. Your own offer is not a go.
- **Write a change line** before each mutation: target, exact change, impact, rollback.
- **One change per call**, with `set -euo pipefail`, a backup, and a verify step.
- **Secret hygiene:** never read `.env` or credential files; allowlist output instead of filtering it.
- **Independent review on fixed triggers** (prod config, releases, migrations, deletions), not on every message.
- **A block is an answer:** stop and report, never route around a guardrail.
- **Do not over-correct:** no permission questions for reads, no asking twice, no SLA prose in a small README.

Built and tuned on `claude-opus-5-5`. The mechanical defaults (backups, one change per call, secret hygiene, fixed review triggers) are simple patterns that should carry over to other models, but that is untested. The judgment sections assume a strong model; pair weaker models with harness deny rules or hooks.

## Install

### Easiest: let your agent do it

Paste this into Claude Code, Codex, Hermes Agent, or any coding agent that supports Agent Skills:

```text
Install the Agent Skill "production-ops-discipline" from https://github.com/duu261/agent-skills.
1. Clone the repo into a temporary directory.
2. Copy the folder skills/production-ops-discipline into the user-level skills directory of the agent you are running in (Claude Code: ~/.claude/skills/, Codex: ~/.agents/skills/, Hermes Agent: ~/.hermes/skills/). If you are not sure which one applies, ask me.
3. If a folder with that name already exists, stop and ask me before replacing it.
4. Do not install the optional delegation hook unless I ask for it.
5. Confirm the installed path and that SKILL.md is there, then delete the temporary clone.
```

### Manual

Copy `skills/production-ops-discipline/` into your harness's skills directory:

| Harness | Location |
|---|---|
| Claude Code | `~/.claude/skills/` or `.claude/skills/` |
| Codex | `~/.agents/skills/` or `<repo>/.agents/skills/` |
| Hermes Agent | `~/.hermes/skills/` |

```bash
git clone https://github.com/duu261/agent-skills
cp -r agent-skills/skills/production-ops-discipline ~/.claude/skills/
```

The skill loads when a task touches production. Invoke it directly with `/production-ops-discipline` in Claude Code.

For the `claude-opus-5-5` delegation hook (why the model needs a per-turn user-side nudge to use subagents) and harness-specific tool mapping, see [references/harnesses.md](references/harnesses.md).

## Evidence

Field notes from one operator running `claude-opus-5-5` on a production server, about 12,000 tool calls. This is observational, not a controlled test.

| % of shell calls | `claude-opus-5-5` before | `claude-opus-5-5` after | `gpt-5.6-sol` | `gpt-6-astra` |
|---|---|---|---|---|
| Explicit working directory | 60.8 | 99.4 | 81.4 | 94.2 |
| `cd` chained into commands | 35.5 | 0.6 | 2.4 | 0.7 |
| Shell file reads (`cat`, `sed -n`, `head`, `tail`) | 11.7 | 5.9 | 0.7 | 0.5 |
| Recursive `grep` | 6.0 | 0.1 | 0.3 | 0.6 |
| In-place `sed -i` | 2.6 | 0.2 | 0.1 | 0.0 |

After the skill, `claude-opus-5-5` matches or beats both GPT models on working directory, `cd`, and recursive `grep`. Shell file reads are the clear gap that stays, and in-place edits are close but still above both. The GPT columns are from the same server before the skill, with different periods and task mix, so read them as directional.

"After" means the skill plus matching standing rules that landed the same evening, so this table cannot credit the skill alone. Review delegation barely moved until a one-line per-turn prompt hook was added. Confounds and the full numbers are in [references/evidence.md](references/evidence.md). A controlled A/B in Claude Code is planned.

## License

MIT
