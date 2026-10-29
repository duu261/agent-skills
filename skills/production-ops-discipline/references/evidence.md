# Evidence

Observational field notes, not a controlled experiment.

**Setup:** one operator, one production Linux server, the Hermes Agent harness, mostly Claude Opus 5.5, August to October 2026. Counts come from the harness session database. Only tool-call arguments were scanned, never tool outputs. Habit rates are percentages of shell calls in top-level sessions, deduplicated by call ID.

**Windows:**
- **A:** before the skill. 6 Opus 5.5 sessions, 265 shell calls.
- **B:** skill plus matching standing-rule text, no prompt hook. 100 sessions, 1,079 shell calls.
- **C:** B plus a per-turn reminder hook. 86 sessions, 2,276 shell calls.
- **Baselines:** GPT-5.6 Sol on the same server before the skill, 460 sessions, 13,048 shell calls. GPT-6 Astra, same server before the skill, 171 sessions, 1,925 shell calls.

## Shell habits

| % of shell calls | A | B | C | GPT-5.6 Sol | GPT-6 Astra |
|---|---|---|---|---|---|
| Explicit working directory | 60.8 | 99.4 | 99.96 | 81.4 | 94.2 |
| `cd` chained into the command | 35.5 | 0.56 | 0.62 | 2.42 | 0.73 |
| Shell file reads (`cat`, `sed -n`, `head`, `tail`) | 11.7 | 5.9 | 3.2 | 0.72 | 0.52 |
| Recursive `grep` | 6.0 | 0.09 | 0.0 | 0.26 | 0.57 |
| In-place `sed -i` / `perl -i` | 2.6 | 0.19 | 0.04 | 0.10 | 0.0 |

The big shift happened between A and B and stayed flat after the hook. Shell file reads dropped but did not reach zero.

## Delegation

| | A | B | C |
|---|---|---|---|
| Subagent calls per session | 0 | 0.28 | 1.63 |
| Sessions that delegated | 0% | 15% | 49% |

Standing-rule text about delegation, added halfway through B, did not move the rate. The rate rose after the per-turn hook was added. The skill plus standing rules did not make the model delegate much in this stack; if you want more delegation, a hook is worth trying (see [harnesses.md](harnesses.md)).

## Friction review

192 top-level sessions after the skill, 37 user corrections:

- **Targeted by the skill:** unrequested extra work, checks handed back to the user, skipped reviews. The skill has rules for these; how much it reduced them is not measured.
- **Over-strictness linked to the skill (9):** a reviewer on trivial changes, asking again after a go, treating notes as production changes, "next options" closers, SLA tone in small docs. The "Do not over-correct" section comes from these.
- **Out of scope:** wrong paths, misread intent, forgotten features. Those are competence problems, and no discipline skill fixes them.

## Confounds

- Standing-rule text with the same core rules (explicit working directory, no `cd`, no secret reads) landed the same evening as the skill. The A-to-B shift cannot be split between them.
- Window A is small: 6 sessions over about 8 hours.
- The skill was edited many times during B and C. There was no frozen version.
- One operator, one harness. Claude Code routes search through the shell by design, so the shell-habit rates may not transfer.
- The skill loaded in 73 to 83 percent of sessions, not all of them.
- A secret-access regex was dropped from the table: it counts mentions, not reads.

## Rules folded in from other skills

Learned from `gpt-5.6-sol` sessions on the same server, then merged here instead of shipping as separate skills:

- **Same-path retry and owning-layer repair.** From a recovery skill that `gpt-5.6-sol` built from its own traces. A small matched pilot (one run per condition, three models: `deepseek-v4-flash-free`, `gemini-3.5-flash-low`, `gemini-3.1-pro-low`) showed its clearest lift on a contradiction-recovery fixture. Directional, not a benchmark.
- **Fix a stale tag forward.** From the same pilot, repeated trials on `gemini-3.5-flash-low`. Without the rule the model kept proposing to delete or move a published tag; with it the model kept the tag and proposed a patch release.
- **Verify the artifact the claim names, and "ahead" is not "unmerged".** Field rules from repeated repository and release work, not measured.
- **October 2026 port.** From the private working copy after a reviewed trim, from the operator's standing rules, and from an external `gpt-5.6`-family review of this skill. Field rules, not measured:
  - *Private working copy:* numbered and mixed replies, shortlist follow-ups, scheduled destructive work as a reminder, allowlist argument guards, masked display versus bytes on disk, proving the user's exact path, shared-checkout branch hygiene, and the reviewer rules (never hand over the gated command, correctness-only scope, dispatch after the write, check reviewer-supplied flags and quotes).
  - *Standing rules:* state your reading of a terse request, never fill a gap with plausible output, retry once with a change that separates causes, and restate constraints in every subagent prompt.
  - *External review:* the untrusted-input boundary and retry by failure class. Its broader points (harness enforcement, sandboxing, deploy gates) need harness features, not skill text, so they stay out.

## Planned

A controlled A/B in Claude Code: vanilla, skill only, and skill plus hook. One pinned model, neutral paths, a realistic fake-production sandbox, at least three runs per case, scored from transcripts rather than final answers.
