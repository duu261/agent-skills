# AGENTS.md

This repo publishes Agent Skills, one per folder: `skills/<name>/SKILL.md`. The root README is the catalog; each skill folder has its own README.

## Layout

- Flat: `skills/<name>/`, never nested categories. Some installers scan deeper, but Hermes Agent taps only scan one level under `skills/`, so flat is the only layout every channel finds.
- `name` in frontmatter equals the folder name: lowercase, hyphens, 64 characters or fewer, no "claude" or "anthropic".
- `description` says what the skill does and when to use it, 1,024 characters or fewer. It is what an agent reads to decide whether to load the skill.
- Frontmatter: `name`, `description`, `license: MIT`. Nothing harness-specific.
- `SKILL.md` stays under 500 lines. Put long detail in `references/`, helpers in `scripts/`.
- Each skill folder has `README.md` and `README.vi.md`: what failure it fixes, where it came from, install.

## Adding a skill

Skills come from real work in agent sessions, then a human judges and rewrites them. An agent may draft a public version; the maintainer decides what lands.

1. Start from the working skill. Keep its procedure and its pitfalls; those are the parts that real sessions earned.
2. Make it harness-neutral. Describe actions ("read the file", "search session history", "use a read-only subagent if your harness has one"), not one harness's tool names. Harness-specific mapping goes in `references/`.
3. Strip the operator: no hostnames, IPs, home paths, usernames, product, pool, or account names, private incident stories, or rules that only make sense on one setup.
4. Keep claims true. Say "learned" or "refined", not "evaluated", unless a controlled run backs it. Credit models by exact ID (`claude-opus-5-5`, not "Opus").
5. Add the skill's row to both root READMEs, and its plugin entry to `.claude-plugin/marketplace.json`.
6. Validate, then get an independent review before pushing.

## Editing a skill

- Add a rule only when repeated real use shows the failure. One incident or one model's guess is not enough.
- Every rule says why. A bare do/don't list fails on cases it does not name.
- When a rule adds strictness, check it does not add ceremony. Asking twice costs the user a turn too.
- Keep EN and VI READMEs in step. English is the source of truth.

## Checks

- Validate every skill: `for d in skills/*/; do uvx --from skills-ref==0.1.1 agentskills validate "$d"; done`. CI runs the same loop on every push.
- Before pushing, scan staged text for the operator details listed above.

## Git

- Conventional commits, imperative subject of 50 characters or fewer.
- No force-push to `main`.
