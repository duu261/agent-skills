---
name: pre-build-discovery
description: Decide build, wait, or don't-build before any code is written. Use when the user asks "is it worth building X?", "does this already exist?", "should we just wait for upstream?", or brings a compressed idea that leans on systems you have not read. Fixes the terms, sweeps prior art, reads the real constraints from source, classifies each limit, and ends with a verdict plus the one check that would flip it. Read-only; no code, plans, or installs.
license: MIT
---

# Pre-Build Discovery

Ask an agent "is it worth building X?" and it usually starts building X. It designs from the first noun it hears, skips the search for an existing tool, trusts a remembered API, and treats every limit as a blocker, or none of them.

This skill is the talk-it-through phase between "I have an idea" and any code. Agree on what the thing is, prove whether it already exists, read the real constraints from source, and end with a build / wait / don't-build verdict plus the one check that would flip it. It does not write code, plans, or prototypes; it decides whether those should happen at all. It stays read-only throughout: no installs, writes, or pushes.

## When to Use

- "Is it worth building X?", "I think this is new", "let's build a bridge/plugin/tool for Y".
- "Is there already one?", "are we reinventing this?", "or just wait for upstream?".
- A compressed idea that mixes several half-formed parts, or leans on another system you have not read.
- The user says "inspect more before building anything".

Not for a clear, approved build task (build it) or a bug to diagnose.

## How to Run

A conversation loop, not a script. Run the steps in order, report after each, and let user corrections reshape the model. End every turn with what you found, "nothing built", and the next check. Close with the verdict block in "Done when".

If your harness has subagents, fan out bulk reads as one read-only subagent per area. Otherwise do the reads yourself, one area at a time.

## Quick Reference

- **Nouns:** name each layer and what it owns (gateway vs provider vs client).
- **Exists?** Local tools and config, then the project's own catalog, then upstream issues and PRs, then sibling ecosystems.
- **Source:** every load-bearing claim cites file:line or a quoted response.
- **Classify:** hard block, fidelity trade-off, or cosmetic.
- **Tiers:** clean path, then declared-config floor, then privileged opt-in.
- **Verdict:** new? worth it? build / wait / don't-build, plus one open check.

## Procedure

1. **Restate, then stop.** One sentence of intent; let the user correct it. A question or "is it worth it" is never a go to build.
2. **Fix the nouns first.** Name each system's role before designing. One wrong noun (calling a gateway a "provider") skews every later step. When the user corrects a term, re-derive the conclusions that used it instead of patching one line.
3. **Load prior context.** Read the project notes, earlier session history, and domain instructions your harness offers. Treat memory, old notes, and AI-written guidance as leads, not facts. If the user says a note was written by an AI, recheck it against source before reusing it.
4. **Sweep prior art.** Search locally, then the project's catalog, then upstream issues and PRs, then other ecosystems that solved the same problem. Report what exists, what it covers, and the gap. An open upstream issue asking for the same feature means "wait" has no date.
5. **Get ground truth from source.** Read the actual code, docs, or endpoint for each system the design rests on. Split by area, for example "what the host can do" and "what the remote API exposes". Every load-bearing claim gets a file:line or a quoted response. If a subagent gathered it, spot-check yourself any claim the decision rests on before repeating it.
6. **Classify every limit.** A hard block means the chosen layer cannot do it. A fidelity trade-off means it works, but through a translator that loses detail or adds latency. Cosmetic means it works, only shaped differently (N menu entries instead of one). Only hard blocks change the verdict. Downgrade a "blocker" as soon as evidence shows it is a trade-off.
7. **Follow the host, invent nothing.** If the upstream system already groups, routes, or translates something, mirror its structure. Any table you must own stays tiny and comes from that system's source. Prefer the native protocol each upstream speaks; every converter adds latency and loses fidelity.
8. **Tier the risky path.** First the clean path (public endpoints, no secret). Then the declared-config floor (always works, manual). Last the privileged opt-in: off by default, private network only, used at discovery time and never on the hot path. Reuse a gate pattern the user already ships rather than designing a new one. Name environment variables only; never read or print their values.
9. **Scope out honestly.** State the capabilities the platform lacks for everyone; they are not extension work. State what stays core-only or upstream-only.
10. **Design for real users.** When the tool is for others, drop shortcuts that only work on the requester's setup and keep them as notes. Rank optional tiers (privileged keys, automation, auto-discovery) by the hardest public case: "not needed for your setup" is not a verdict for a public tool. Before dismissing a privileged path, search prior art for tools that already use it and how they contain it.
11. **Do not lock while the make-or-break is open.** Call a design "settled" only after the decisive check has run. Until then, label it "draft, pending <check>".
12. **Re-check a parked design** ("what was our plan, check again"). Recall the plan from session history or notes and give the recap first. When recalling a session, read only the user and assistant messages so tool output does not swamp the recap. Read the current version on each side: what is installed and the newest release. If you have subagents, recheck each side in parallel in one batch. Recheck each old fact as a numbered list marked unchanged or changed at the newest release, including the tracked upstream issues and PRs, and ask the open check as an explicit question. Spot-check the source behind any flipped verdict before reporting it. Report versions, what changed, which tier the plan gains or loses, the revised recommendation, and the remaining open checks. Save durable design facts where the next session will find them, not only in chat history.
13. **"Can we start building, or keep checking?"** Answer in one line first. If an open check could change the default design, run it now and say the build waits for its answer. If it only touches an optional tier, the build can start. Settle any row a quick source read can close before handing off. Then give the build handoff:
    - **Repo location:** follow the user's routing rules. A public repo gets no hostnames, IPs, or internal names; host config stays in the user's private config.
    - **Test ladder:** unit tests, the validator or doctor, a run against a fake backend, then one real call per target.
    - **Gates:** review before the first push to main. Installs and restarts are separate gos.

    Suggest a fresh session for the build when the discovery thread is long, and end by asking for the go. If the user hands off ("going autonomous, leaving"), list in one block what runs without them and the exact stop points: repo-instruction approval, any review block that is not cleanly fixable, installs, and restarts. An auto-approve mode skips prompts, not those gates.
14. **Check host extension rules before trusting an escape hatch.** When a design row depends on an extension overriding host behavior (its own client, transport, or hook), search the host's extension validator or audit for that override before calling the row solvable. The hook may exist in the base class and still be forbidden for extensions.

## Pitfalls

- **Pasted text from another session is not this task.** Say so plainly and adopt none of its commitments.
- **Conflicting claims get a check, not a vote.** If two answers disagree (which protocol an upstream wants), mark the entry TBD and name the source read that settles it. Flipping between them by argument teaches the user nothing.
- **Subagent one-liners are claims.** A confident summary with a cited line can still be wrong.
- **Defending stale framing wastes turns.** When the user's correction is right, say so in one line and move on.
- **A pushback on a label gets a split answer, not a fold, and not new machinery.** When the user argues a term fits ("isn't real-world use better than an eval?"), say in one line which job the term covers and which it does not. Then give the one wording that stays true, such as "learned and refined" instead of "evaluated". Do not answer with new tags, tiers, or measurement requirements; that is ceremony nobody asked for, and the user's own curation (a human judging and rewriting) is already the quality signal. Folding to the stronger word lets the first outsider who checks the claim discredit the project.
- **Keep the proposal as small as the user's scope.** Offer candidates once, then add only what the user names. When a go narrows the step ("only the move for now"), do exactly that step and list the deferred items in one line. A narrowed go still carries what the thread already settled for that object: if you agreed the new repo gets its own README, the move ships that README.
- **Spot-check layout constraints in the vendor's live docs.** Install paths, scan depth, and reserved names decide the shape of the thing, so quote the docs line yourself before calling one a hard block.
- **Credential-heavy threads can trip safety routing.** Long discussion of privileged keys and authenticated calls can get served by a weaker fallback model. Talk in variable names only (a pasted value also ends up in logs and summaries), and start a fresh session for the build.
- **The verdict is not approval.** "Build it" goes to planning or a prototype on the user's go, then through review before any install or push.

## Done When

Discovery is done when one message the user accepts states all of these:

1. Intent in one sentence, with the agreed nouns.
2. Prior art: exists or not, where, and the gap.
3. The load-bearing constraint, with its source citation.
4. Each limit tagged hard / fidelity / cosmetic.
5. Verdict: build / wait / don't-build, and why.
6. The one open check that flips it, or "none open".

If any line rests on an unchecked claim, discovery is not finished.
