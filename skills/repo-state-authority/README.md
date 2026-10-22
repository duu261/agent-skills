# repo-state-authority

English | [Tiếng Việt](README.vi.md)

**For anyone who has watched an agent delete a branch because its diff looked huge, or trust a status file over `git log`.**

Agents read repository state from the easiest signal. They call a branch lost work because `git diff main <branch>` is thousands of lines, when it is fully merged and `main` simply moved on. They trust a status file or a handoff note over Git, and they decide a file is gone because `git diff` is empty, when it is only untracked or ignored.

This skill makes the agent pick the right authority for each question first: Git for source, runtime readback for what is deployed, the public path for what outsiders see, and the owner's own words for intent. It classifies branches by ancestry and patch identity (`rev-list --left-right`, `git cherry`), keeps deployed, source, and canonical commits apart, leaves human-owned work untouched, and deletes branches only after writing a SHA rollback file.

## Where it came from

Created by an agent in Hermes Agent's [self-improvement loop](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills#when-the-agent-creates-skills) during real repository cleanups in August 2026. It was then used about 240 times and patched about 90 times, mostly by background review after sessions run on `claude-opus-5-5`, `gpt-5.6-sol`, and `gpt-6-astra`. The public version keeps the Git authority procedure and drops the parts specific to one setup (fork overlays, host consolidation, firmware forks).

## Install

```bash
npx skills add duu261/agent-skills --skill repo-state-authority
# Hermes Agent
hermes skills install duu261/agent-skills/skills/repo-state-authority
```

Or copy `skills/repo-state-authority/` into your harness's skills directory.

## License

MIT
