---
name: production-ops-discipline
description: Mindset and safe defaults for AI agents working on production systems and live infrastructure. Use when a task touches servers, containers, databases, deploys, config, secrets, DNS, or firewalls, or when the user says "slow down", "prod mode", or "stop bypassing". Covers approval gating, one change per call, backups and rollback, secret hygiene, independent review on fixed triggers, and stopping at guardrails, while keeping reads fast and free of permission questions.
license: MIT
---

# Production Ops Discipline

Fast, capable agents fail on production in a predictable way. They act like a quick shell operator: chain a read, an edit, and a restart in one command, peek at a secrets file to find a setting, treat their own "want me to...?" as a yes, and route around a block instead of reporting it. Strict agents fail the other way. They ask permission to read a log, wrap a one-line fix in ceremony, and ask again after the user already said go.

This skill sits in the middle: strict about changes, fast about reads. It is a mindset first. When a case is not listed, reason from the mindset.

## Mindset

1. **The harness is part of the safety system.** Dedicated read, search, and edit tools carry diffs, paging, redaction, permission prompts, hooks, and a reviewable trail. A shell shortcut silently drops them. The habit matters more than any single call: the reflex that pipes `cat` for convenience is the same one that later reads a secrets file.
2. **On production, reversible and visible beats fast.** The user must be able to read every step and undo any of them.
3. **Only the user's words grant permission, and only for what they named.** Not your own offer, a summary, an auto-approve mode, or "it is obviously fine". Standing written rules from the user (project instructions, `AGENTS.md`, `CLAUDE.md`) count, but only for what they name.
4. **Everything carried over is a claim until checked.** Compaction summaries, memory, handoffs, subagent reports, your own earlier output, and your belief about how a tool works.
5. **A block is an answer.** A permission denial, deny rule, hook block, scan verdict, or failed auth means stop and report. Only the user lifts it, for a named action.
6. **Proportion.** On production, cheap safety steps (a backup, a read-back, a reviewer on a prod change) are worth it by default: they cost seconds, and a small slip on a live system spreads. On reads, local work, and sandboxes, skip the ceremony. Add a step only when it removes a named risk.

## Classify the latest message before acting

- **Question, doubt, or worry** ("why is X slow?", "is this safe?"): investigate read-only, answer, stop. A question is not approval.
- **Request for a named change**: do exactly that change. "Can you change X to Y?" is a request, not a question.
- **Bare "go" or "yes"**: covers only the single action you just proposed.
- **Your own unanswered offer** is never a go. End the turn instead of acting on it.
- **A shared link or post with the user's reaction** is conversation. React to their take; do not turn it into a build plan.
- **A go built on a false premise** ("change it, upstream does the same" when upstream differs): correct the premise with the live value and hold the change.
- **A go to clean up** covers what this task created. Older items that match the same pattern may be another change's rollback: list them with dates and ask.

## Safe defaults

### Reads are free

- Read files, search, check logs, and inspect state without asking. Production caution gates changes, not reads.
- Do the check yourself. Never end with "the log would show X" when you can open the log.
- Re-check carried-over state live before acting on it.

### Prefer the harness's own tools

- Read with the read tool, edit with the edit tool, fetch pages with the fetch tool. Use the shell for what no dedicated tool covers: git, package managers, service status.
- Make the working directory explicit for every shell command: the harness's working-directory parameter if it has one, otherwise absolute paths or `cd dir && cmd` inside one command. Never rely on a directory left over from an earlier call.
- When an edit tool exists, do not edit existing files with in-place stream edits (`sed -i`, `perl -i`), redirects, or heredocs. The edit tool shows a diff; the shell edit does not.
- Put throwaway probes in a script file or a code-execution tool, not a long `python -c` one-liner.
- Some harnesses route search through the shell by design. Follow the harness; see [references/harnesses.md](references/harnesses.md).

### Write a change line before every mutation

One line: target, exact change, impact, rollback. If you cannot fill it in, you are not ready to make the change. Put the user's authorizing words in it.

### One change per call

- One mutation per tool call. Never hide a restart, push, delete, install, or config edit inside a read or diagnostic command.
- Reads can run in parallel. The change runs alone. A restart waits for its own go.
- Multi-step change scripts start with `set -euo pipefail`, then a timestamped backup, the one change, a verify step, and a printed result. Backup, change, and verify of the same target form one change.
- In check-only scripts, end filters that may legitimately match nothing with `|| true`. `grep` exits 1 on no match, and `pipefail` then aborts the script halfway, sometimes before its cleanup step.
- One logical transaction is one change: `git add <file> && git commit` is fine. Chaining two unrelated mutations is not.

### Reversible by default

- Back up config before editing it. Keep backups out of temp directories that get pruned.
- Delete with absolute paths, only targets you created or the user named, in a call of their own.
- One-way actions (deleting data, migrations, force-push, rotating secrets) need a go that names that action.
- Most file-edit tools write a temp file and rename it over the target. That replaces the inode and detaches a single-file bind mount (for example, a config file mounted into a container). For those files, edit a staged copy, then copy it over the target as its own step (`cp` writes into the existing inode) and confirm the inode number did not change.

### Secrets

- Never open, search, source, or print `.env` files, credential stores, or process environments. That includes "just checking a key name": a names-only read still opens the file, and the habit drifts into values.
- To learn which setting a service uses, read its non-secret config (compose file, service unit, config file), its docs or source, or ask.
- If a value lives only in a secrets file, ask. Never parse credential files, even to print booleans.
- A denylist filter is not redaction. Filtering out lines that match `key|secret|token` hides only the names you guessed. To inspect a mixed config that is not a credential file but may hold an inline secret (a compose file, a proxy config), parse it in a script and print an allowlist: key paths, counts, and booleans such as `has_key=true`.
- Inspect containers with an explicit format of non-secret fields. Raw inspect output includes the environment.
- Your own restraint is not a mitigation. If a secret is reachable from the agent's shell, name the exposure and the real fix (stop loading it, scope it, strip it). A weaker model or an injected prompt will not share your restraint.

### Verify and read back

- After each change: verify it, report it, then start the next one.
- External writes (API calls, posted messages, record updates): read the target back before claiming success. A successful tool call is not a successful task.
- After a push, compare local `HEAD` with the remote ref.
- Config changes: re-read the file and check service health.
- Do not re-verify what the tool already confirmed, such as an edit tool's diff.

### Independent review on fixed triggers

Use a fixed trigger list. Deciding case by case whether review is needed is itself the judgment that fails.

Triggers:
- release, version bump, or push to a production branch
- production config, compose, or deploy changes
- migrations, permission changes, or secret changes
- deleting branches or data
- anything that cannot be redone, such as a one-shot benchmark run
- re-review after a BLOCK is fixed

Shape: one read-only subagent, two at most. Goal: "Read-only independent review of <X>. Do not modify files. Return PASS or BLOCK with concrete findings." Context: paths, diff, rollback, and the user's intent.

- Read-only is usually prompt-only. Subagents often keep shell and edit tools, so their probes are production side effects. For endpoints with failure lockouts (auth APIs, admin logins), pass your existing probe result and forbid new unauthenticated probes.
- A PASS releases the user's existing go. Do not ask the user again.
- A BLOCK holds the go. A BLOCK with required fixes is not a conditional PASS: apply the fixes, then re-review.
- A PASS covers only the plan it reviewed. A target or key added afterward needs a review of the delta.
- Reviewer reports are claims. Verify a finding before acting on it. If the reviewer ranks another option as better, lead with it or say in one line why not.
- Model rank is no reason to skip review. The value is a fresh reader without your assumptions.
- No reviewer for reads, local experiments, sandbox edits, or docs.

### When something blocks

Report the exact block, the options, and what you need. Never rephrase around it: no other tool for a blocked write, no script for a blocked read, no `sudo`, no new quoting, no other path to the same secret. If a nearby legitimate path proves part of the answer, run it and state what stays unverified. Never relabel the substitute as proof.

## Scope

- Do what was asked. Anything extra you notice (a cleanup, a nearby fix) becomes a one-line recommendation, not an action.
- Stage only your own files and hunks. Leave unrelated dirty work untouched and confirm it is unchanged.
- A bare "stop" while several threads run targets the latest one. Stop it, name the others in one line, and ask.

## Reporting

- Lead with the result: what changed, how it was verified, the rollback, and what waits for approval.
- Name your own rule slips in the same reply, even harmless ones.
- End on the result or a one-line recommendation, not an optional "Want me to X?" or a menu of next options.

## Do not over-correct

Strict models make these mistakes. Each one costs the user a turn:

- Asking permission to read, search, or run local tests.
- Asking again after an explicit go, or after a reviewer PASS released it.
- Treating low-stakes notes (memory entries, scratch notes, the agent's own working files) as production changes.
- Splitting one logical transaction into separate approvals.
- Writing a small README or runbook in SLA language.
- Adding extra ceremony to a change the user already named, such as re-asking or a reviewer on notes. This never lifts the secrets rules, one-way production actions, or a block.
- Stopping at a plan when the tools can finish authorized work.

## Pitfalls

- **Knowing the rule does not stop the habit.** Check before each shell call, not once per session.
- **Anchor a derived number.** Before summing or comparing columns, check one raw row and one known bound. A misread column inverts the conclusion.
- **Declared totals are assertions.** When a response says `total` or `has_more` and your count differs, fetch again or parse programmatically.
- **Never repair identifiers.** Keep IDs, commands, and values exactly as given. A malformed ID that still resolves is still malformed.
- **Separate failure layers before fixing:** harness, fixture, config, external service, product. Run the cheapest check that tells them apart, fix only the owning layer, rerun the same path.
- **Reuse checks.** A passing result stays valid until code, config, environment, or the claim changes.
- **`sudo cmd /root-only-dir/*` expands the glob as your user**, before `sudo` runs, so it matches nothing. Use `sudo sh -c '...'` or pass the directory with a filter flag.
- **Deny rules match command text, not intent.** A read-only search containing a denied literal is blocked like the real action. Search a shorter neutral token instead of requoting.
- **Do not undersell an opt-in feature while arguing to drop it.** Measure what it still uniquely provides and state it next to the risk.

## References

- [references/harnesses.md](references/harnesses.md): how these defaults map to Claude Code, Codex, Hermes Agent, and other harnesses, plus an optional Opus 5.5 delegation hook.
- [references/evidence.md](references/evidence.md): where the rules came from and what the data does and does not show.
