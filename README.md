# agent-skills

English | [Tiếng Việt](README.vi.md)

Agent skills from real work, not toy tasks.

Each skill started in day-to-day [Hermes Agent](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills) sessions on a live production server. Hermes [writes a skill](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills#when-the-agent-creates-skills) when it works out a non-trivial workflow and refines it in its self-improvement loop as later sessions hit new cases, or builds one from an idea with [`/learn`](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills#learning-a-skill-from-sources-learn).

Nothing here is raw AI output. Before a skill lands, a human judges it, rewrites it, strips everything specific to one setup, and makes it portable to any harness that reads the [Agent Skills](https://agentskills.io) format.

## Skills

| Skill | What it fixes |
|---|---|
| [production-ops-discipline](skills/production-ops-discipline/) | Fast agents on live servers: chained edits and restarts, peeking at secrets, acting on their own "want me to...?". Written by `claude-opus-5-5`, for `claude-opus-5-5`. |

Each skill folder has its own README with details and evidence.

## Install

With the [skills CLI](https://github.com/vercel-labs/skills) (Claude Code, Codex, and other agents):

```bash
npx skills add duu261/agent-skills --skill production-ops-discipline
```

With [Hermes Agent](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills):

```bash
hermes skills install duu261/agent-skills/skills/production-ops-discipline
# or subscribe to the whole repo
hermes skills tap add duu261/agent-skills
```

Manual: copy `skills/<name>/` into your harness's skills directory (Claude Code `~/.claude/skills/`, Codex `~/.agents/skills/`, Hermes Agent `~/.hermes/skills/`).

## License

MIT
