# pre-build-discovery

English | [Tiếng Việt](README.vi.md)

**For anyone who asks an agent "is this worth building?" and gets code back.**

Agents answer a feasibility question by starting the build. They design from the first noun they hear, skip the search for an existing tool, trust an API they remember instead of the one in the source, and treat every limit as a blocker, or none of them.

This skill keeps the agent in the talk-it-through phase until there is a verdict. It fixes the terms first, sweeps prior art (local, project catalog, upstream issues, sibling ecosystems), reads the real constraints from source with citations, and tags each limit as a hard block, a fidelity trade-off, or cosmetic. Only hard blocks change the answer. It ends with build / wait / don't-build plus the one check that would flip it, and it stays read-only the whole time.

## Where it came from

Built with Hermes Agent's [`/learn`](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills#learning-a-skill-from-sources-learn) by `claude-opus-5-5`, from a real design session about whether a provider plugin was worth building. It was then refined over later discovery sessions (repo layout, publishing, upstream waits) as they hit new cases. The public version drops the harness-specific tool names and setup details.

## Install

```bash
npx skills add duu261/agent-skills --skill pre-build-discovery
# Hermes Agent
hermes skills install duu261/agent-skills/skills/pre-build-discovery
```

Or copy `skills/pre-build-discovery/` into your harness's skills directory.

## License

MIT
