# agent-skills

English | [Tiếng Việt](README.vi.md)

Skills I use every day, pulled out of my own sessions with frontier models: `claude-opus-5-5`, `gpt-6-astra`, `gpt-5.6-sol`, `grok-4.6` and `grok-4.7`. The loop is simple. When a model does something dumb, the fix goes into a skill. When a task keeps coming back, the agent writes a skill for it. [Hermes Agent](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills) does both on its own, through its [self-improvement loop](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills#when-the-agent-creates-skills) and [`/learn`](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills#learning-a-skill-from-sources-learn).

Then I go through each one by hand. I cut whatever only makes sense on my setup and split the rest into mindset (why) and steps (what to do), so a weaker model can follow it too. They work in any harness that reads the [Agent Skills](https://agentskills.io) format.

## Skills

**[production-ops-discipline](skills/production-ops-discipline/)**: for agents on a live server. It stops chaining an edit and a restart in one command, stops peeking at `.env`, and stops treating its own "want me to...?" as a yes. It asks before changes, never before reads or tests. I built it for `claude-opus-5-5` so it would be as careful as `gpt-5.6-sol` and `gpt-6-astra`. Across about 12,000 tool calls, `cd` chained into commands dropped from 35.5% to 0.6% (field notes, not a controlled test; numbers in its README).

**[pre-build-discovery](skills/pre-build-discovery/)**: use it before you vibe-code an idea or a feature. Ask "is this worth building, does it exist already?" and it digs through prior art and the real source, then says build, wait, or don't. It writes no code and no plan. You don't need to be technical to use it.

**[claim-check](skills/claim-check/)**: the agent said something that smells wrong. Tell it "that's wrong, show me the log". It doesn't argue and it doesn't cave; it goes back to real evidence and gives one verdict: Confirmed, Corrected, or Blocked. Tip: invoke it yourself at the start of a session and it turns into a try-harder switch. The agent does more checking, so you read less nonsense. In a same-model A/B on `deepseek-v4-flash`, the session with it read the source and got the answer right; the one without it read a README and got it wrong. Loaded about 140 times so far.

**[repo-state-authority](skills/repo-state-authority/)**: for anyone too lazy to check Git. It won't call a merged branch "lost work" because the diff is huge, won't trust a status file over Git, and deletes a branch only after saving its SHA. Used about 240 times.

Each skill folder has its own README with the evidence.

## Install

Easiest way: paste this repo's link into the agent you use and tell it to install all the skills, or just the ones you want.

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
