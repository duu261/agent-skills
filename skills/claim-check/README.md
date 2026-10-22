# claim-check

English | [Tiếng Việt](README.vi.md)

**For anyone who tells an agent "that's wrong" and gets either a lecture or a cave-in.**

Push back on an agent's claim and it usually does one of two things. It defends the claim with the same reasoning, louder. Or it folds and agrees with you without checking anything. Neither tells you whether the claim was true.

This skill makes the agent treat your doubt as a trigger to verify, not as evidence either way. It isolates one falsifiable claim, labels what the old answer actually rested on (observed, tool-reported, inferred, recalled, or self-attested), and runs one check that could have come out differently: a disabled fallback, a hidden nonce, the target endpoint queried directly. It ends with exactly one status: Confirmed, Corrected, or Blocked.

## Where it came from

Built with Hermes Agent's [`/learn`](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills#learning-a-skill-from-sources-learn) by `gpt-5.6-sol`, from the operator's own request, right after a model claimed to have used native vision when it had not. Hermes has loaded it about 140 times since, and its background review refined it once along the way. The public version drops the harness-specific tool names and setup details.

## Install

```bash
npx skills add duu261/agent-skills --skill claim-check
# Hermes Agent
hermes skills install duu261/agent-skills/skills/claim-check
```

Or copy `skills/claim-check/` into your harness's skills directory.

## License

MIT
