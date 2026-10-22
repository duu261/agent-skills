# behavior-repro-fixture

English | [Tiếng Việt](README.vi.md)

**For anyone who wants to check "the model refused X" without the test itself causing the refusal.**

Re-asking in the same session proves nothing: that session already knows the complaint, and its own system prompt or memory may be the cause. Agents asked to reproduce a behavior usually contaminate it. They run the probe themselves, leave the expected answer where the model can read it, or build a fake multi-agent runtime that hides what you wanted to see.

This skill builds a small private fixture instead: a disposable workspace, a paste-ready multi-turn conversation that never says "this is a test", and a scorecard that separates a block forced by the harness from one the model invented. It isolates the probe session from host rules, memory, and recall, and keeps expected values out of the model's reach. You run the probe in a fresh session and score it. A reference covers skill A/B evals: arms, confounds, and metrics that transfer across harnesses.

## Where it came from

Created by Hermes Agent's [background skill review](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills#when-the-agent-creates-skills) after a session run on `grok-4.6` about a reported over-refusal on copying a non-secret environment file. Refined over later sessions run on `claude-opus-5-5` that built and ran such fixtures, and extended with the skill A/B design two days later. The public version drops the harness-specific profile, memory, and session-store details.

## Install

```bash
npx skills add duu261/agent-skills --skill behavior-repro-fixture
# Hermes Agent
hermes skills install duu261/agent-skills/skills/behavior-repro-fixture
```

Or copy `skills/behavior-repro-fixture/` into your harness's skills directory.

## License

MIT
