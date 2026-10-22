# agent-skills

English | [Tiếng Việt](README.vi.md)

Agent skills from real work, not toy tasks.

Each skill started in day-to-day [Hermes Agent](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills) sessions doing real operator work. Hermes [writes a skill](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills#when-the-agent-creates-skills) when it works out a non-trivial workflow and refines it in its self-improvement loop as later sessions hit new cases, or builds one from an idea with [`/learn`](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills#learning-a-skill-from-sources-learn).

Nothing here is raw AI output. Before a skill lands, a human judges it, rewrites it, strips everything specific to one setup, and makes it portable to any harness that reads the [Agent Skills](https://agentskills.io) format.

## Skills

| Skill | What it fixes |
|---|---|
| [production-ops-discipline](skills/production-ops-discipline/) | Fast agents on live servers: chained edits and restarts, peeking at secrets, acting on their own "want me to...?". Written by `claude-opus-5-5`, for `claude-opus-5-5`. |
| [pre-build-discovery](skills/pre-build-discovery/) | Agents that answer "is this worth building?" by building it. Ends with build / wait / don't-build and the one check that would flip it. |
| [claim-check](skills/claim-check/) | Agents that defend a disputed claim louder, or fold without checking. Runs one discriminating check and reports Confirmed, Corrected, or Blocked. |
| [repo-state-authority](skills/repo-state-authority/) | Agents that call a merged branch lost work because its diff is huge, or trust a status file over Git. Picks the right authority per question and deletes only with a SHA rollback file. |
| [behavior-repro-fixture](skills/behavior-repro-fixture/) | Agents that "reproduce" a refusal in a session that already knows the complaint. Builds an isolated, paste-ready fixture and scorecard; includes a skill A/B design. |

Each skill folder has its own README with details and evidence.

## Install

With the [skills CLI](https://github.com/vercel-labs/skills) (Claude Code, Codex, and other agents):

```bash
npx skills add duu261/agent-skills --skill production-ops-discipline
# or every skill
npx skills add duu261/agent-skills
```

With [Hermes Agent](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills):

```bash
hermes skills install duu261/agent-skills/skills/<name>
# or subscribe to the whole repo
hermes skills tap add duu261/agent-skills
```

With [Claude Code](https://code.claude.com/docs/en/plugins/marketplace-reference) plugins, one plugin per skill:

```text
/plugin marketplace add duu261/agent-skills
/plugin install claim-check@duu261
```

Pick one way per agent: a plugin and the skills CLI together install the same skill twice.

Manual: copy `skills/<name>/` into your harness's skills directory (Claude Code `~/.claude/skills/`, Codex `~/.agents/skills/`, Hermes Agent `~/.hermes/skills/`).

## License

MIT
