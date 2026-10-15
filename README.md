# claude-wannabe-gpt

English | [Tiếng Việt](README.vi.md)

**Make a fast agent behave like a careful operator on production, without the ceremony.**

Claude Opus is a beast for real work. But if you came from GPT models, you notice what is missing on a live server: GPT asks before it changes things, keeps secrets out of its output, makes one change at a time, and gets a second opinion before a deploy. Fast agents tend to chain a read, an edit, and a restart in one command, peek at `.env` to find a setting, and treat their own "want me to...?" as a yes.

This repo packages that strictness as an [Agent Skill](https://agentskills.io): a mindset plus safe defaults. Strict about changes, fast about reads. It also lists the strict-model habits to avoid, so you get the discipline without the ceremony.

The skill is named `production-ops-discipline`. The Agent Skills spec reserves "claude" in skill names, so only the repo carries the joke.

## What it teaches

- **Classify the latest message before acting.** A question is not approval. Your own offer is not a go.
- **Write a change line** before each mutation: target, exact change, impact, rollback.
- **One change per call**, with `set -euo pipefail`, a backup, and a verify step.
- **Secret hygiene:** never read `.env` or credential files; allowlist output instead of filtering it.
- **Independent review on fixed triggers** (prod config, releases, migrations, deletions), not on every message.
- **A block is an answer:** stop and report, never route around a guardrail.
- **Do not over-correct:** no permission questions for reads, no asking twice, no SLA prose in a small README.

Built and tuned on Claude Opus 5.5. The mechanical defaults (backups, one change per call, secret hygiene, fixed review triggers) are simple patterns that should carry over to other models, but that is untested. The judgment sections assume a strong model; pair weaker models with harness deny rules or hooks.

## Install

Copy `skills/production-ops-discipline/` into your harness's skills directory:

| Harness | Location |
|---|---|
| Claude Code | `~/.claude/skills/` or `.claude/skills/` |
| Codex | `~/.agents/skills/` or `<repo>/.agents/skills/` |
| Hermes Agent | `~/.hermes/skills/` |

```bash
git clone https://github.com/duu261/claude-wannabe-gpt
cp -r claude-wannabe-gpt/skills/production-ops-discipline ~/.claude/skills/
```

The skill loads when a task touches production. Invoke it directly with `/production-ops-discipline` in Claude Code.

For the Opus 5.5 delegation hook (why the model needs a per-turn user-side nudge to use subagents) and harness-specific tool mapping, see [references/harnesses.md](skills/production-ops-discipline/references/harnesses.md).

## Evidence

Field notes from one operator running Claude Opus 5.5 on a production server, about 12,000 tool calls. This is observational, not a controlled test.

| % of shell calls | Opus before | Opus after | GPT-5.6 Sol | GPT-6 Astra |
|---|---|---|---|---|
| Explicit working directory | 60.8 | 99.4 | 81.4 | 94.2 |
| `cd` chained into commands | 35.5 | 0.6 | 2.4 | 0.7 |
| Shell file reads (`cat`, `sed -n`, `head`, `tail`) | 11.7 | 5.9 | 0.7 | 0.5 |
| Recursive `grep` | 6.0 | 0.1 | 0.3 | 0.6 |
| In-place `sed -i` | 2.6 | 0.2 | 0.1 | 0.0 |

After the skill, Opus matches or beats both GPT models on working directory, `cd`, and recursive `grep`. Shell file reads are the clear gap that stays, and in-place edits are close but still above both. The GPT columns are from the same server before the skill, with different periods and task mix, so read them as directional.

"Opus after" means the skill plus matching standing rules that landed the same evening, so this table cannot credit the skill alone. Review delegation barely moved until a one-line per-turn prompt hook was added. Confounds and the full numbers are in [references/evidence.md](skills/production-ops-discipline/references/evidence.md). A controlled A/B in Claude Code is planned.

## License

MIT
