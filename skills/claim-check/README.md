# claim-check

English | [Tiếng Việt](README.vi.md)

**For anyone who tells an agent "that's wrong" and gets either a lecture or a cave-in.**

Push back on an agent's claim and it usually does one of two things. It defends the claim with the same reasoning, louder. Or it folds and agrees with you without checking anything. Neither tells you whether the claim was true.

This skill makes the agent treat your doubt as a trigger to verify, not as evidence either way. It isolates one falsifiable claim, labels what the old answer actually rested on (observed, tool-reported, inferred, recalled, or self-attested), and runs one check that could have come out differently: a disabled fallback, a hidden nonce, the target endpoint queried directly. It ends with exactly one status: Confirmed, Corrected, or Blocked.

## Where it came from

Built with Hermes Agent's [`/learn`](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills#learning-a-skill-from-sources-learn) by `gpt-5.6-sol`, from the operator's own request, right after a model claimed to have used native vision when it had not. Hermes has loaded it about 140 times since, and its background review refined it once along the way. The public version drops the harness-specific tool names and setup details.

## Bonus: a same-model A/B

Two fresh sessions on the same model, `deepseek-v4-flash`, a minute apart. Both asked the same question: explain how a coding-style plugin works. The plugin was installed on the host but disabled.

- **Skill loaded:** the agent read the plugin's source, its hook registration, and the harness's own plugin list. It answered: installed, not enabled, injecting nothing. Correct.
- **Skill forbidden:** the agent found copies of the plugin in other agents' folders and read the README. It ended with "Your setup already uses it." Wrong. It corrected itself only after it was shown the first session and ran the checks it had skipped.

The gap comes from one step: inspect the authoritative source, not the easiest matching file. This is one pair, not a benchmark. The skill also ran up front, before any claim was disputed, which is outside its main trigger. Read it as a picture of the mechanism, not a score.

## Install

```bash
npx skills add duu261/agent-skills --skill claim-check
# Hermes Agent
hermes skills install duu261/agent-skills/skills/claim-check
```

Or copy `skills/claim-check/` into your harness's skills directory.

## License

MIT
