# AGENTS.md

This repo publishes one Agent Skill: `skills/production-ops-discipline/`.

## Editing the skill

- Add a rule only when repeated real use shows the failure. One incident or one model's guess is not enough.
- Every new rule must say why. The skill is mindset first; a bare do/don't list fails on cases it does not name.
- Keep `SKILL.md` harness-neutral. Tool names for a specific harness go in `references/harnesses.md`.
- Keep `SKILL.md` under 500 lines. When adding, look for something to cut or merge.
- When a rule adds strictness, check it against "Do not over-correct". Ceremony costs the user a turn too.
- Never add operator-specific details: hostnames, home paths, service or vendor names from a private stack, user names, or incident narratives.
- `name` stays lowercase with hyphens, 64 characters or fewer, and must not contain "claude" or "anthropic". `description` stays at 1,024 characters or fewer.

## Evidence

- `references/evidence.md` holds measured numbers only, with the method and confounds. Label observational data as observational.
- Do not claim the skill causes an effect until a controlled run shows it.

## Git

- Conventional commits, imperative subject of 50 characters or fewer.
