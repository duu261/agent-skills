---
name: repo-state-authority
description: Decide what a repository's state really is before cleaning, merging, deleting, or reporting it. Use when asked "are these branches stale?", "is anything unmerged?", "clean up and push all", "where did that file go?", "is prod on the right commit?", or when a status file, handoff, or branch name claims a state. Separates Git, runtime, and notes as different authorities, classifies branches by ancestry and patch identity instead of diff size, preserves human-owned work, and deletes only with a ref backup.
license: MIT
---

# Repo State Authority

Agents read repository state from the easiest signal instead of the right one. They call a branch stale because its name is old, call it lost work because `git diff main <branch>` is huge, trust a `STATUS.md` over `git log`, and conclude a file is gone because `git diff` is empty. Then they delete, merge, or report on that belief.

This skill fixes the order: decide which source is authoritative for each question, read that source, and only then clean up.

## When to Use

- "Are these branches stale?", "do any branches hold unmerged work?", "delete merged branches".
- "Clean and push all repos", "consolidate to one branch per repo".
- "Where did file X go?", "why isn't X committed?".
- "Is production on the right commit?", "did the merge deploy?".
- A status file, handoff note, or session summary claims what the repository contains.

Not for writing new features, or for one obvious command the user named exactly.

## Authority Model

Each question has one owning source. Using a different one produces confident wrong answers.

| Question | Authority |
|---|---|
| Stable rules and constraints | Project instructions (`AGENTS.md`, `CONTRIBUTING.md`) |
| What source exists, branches, history | Git |
| What is deployed | Runtime readback: container image label, version endpoint, installed package version |
| What outsiders see | The public or logged-out path |
| What the owner intends | The owner's latest explicit words; human-written notes are owner content |

A status file, handoff, or summary is a claim about one of these. Read the owning source before acting on it. Do not add a new status file to fix stale state: it becomes the next stale claim.

## Procedure

1. **Inventory before judging.** Run in parallel: `git status -sb`, `git branch -vv`, `git worktree list`, `git log --oneline --graph -20 --all`, `git remote -v`, and `git fetch --dry-run --verbose origin` (shows new remote branches without writing refs). Note every dirty, untracked, and stashed item before touching anything.

2. **Classify every branch by ancestry and patch identity, not by size or name.**
   - `git rev-list --left-right --count main...<branch>`: the right number is commits on the branch that `main` lacks.
   - `git cherry main <branch>`: `+` lines are patches not on `main`; `-` lines are already applied under another SHA (squash or cherry-pick).
   - Right count 0, or every cherry line `-`, means merged. This holds even when `git diff main <branch>` shows thousands of lines; that diff only measures how far `main` moved on.
   - `git cherry` reports a revert chain as unique even when `main` already has the final behavior. For each branch with `+` lines, decide which it is: equivalent patch already on `main`, squash-merged PR, deliberately reverted experiment, or genuinely missing behavior. Only the last is lost work.
   - A worktree under a temporary or auto-pruned directory will vanish with its uncommitted files. Flag it.

3. **Keep three identities apart.** The deployed revision, the source branch it was built from, and the canonical commit after a merge can all differ correctly. A merge commit can be canonical while production rightly stays on its tested parent. Report all three instead of calling the difference drift.

4. **Know what a push to the main branch triggers.** Before pushing, read the `on:` triggers in `.github/workflows/*.yml` (or the CI config) and say whether a push builds, releases, or deploys. Tag-only triggers mean a branch push deploys nothing; a push-to-main deploy means the push is a deployment and needs its own go.

5. **Preserve human-owned work exactly.** Dirty files you did not create, notes, and stashes stay as they are. Commit them only when the user asks for consolidation, with their exact content. Never rewrite owner text for a tidier history, and never stash or reset it away to make a merge easier.

6. **Clean up in this order, one repository at a time.**
   1. Classify each path as needed, stale or generated, or ambiguous before staging. Ambiguous items go back to the user as an exact list.
   2. Stage explicit paths. Use separate commits when code, config, and docs have different intent.
   3. Run the focused tests for what changed.
   4. Push without force, `git fetch`, and confirm `HEAD` equals `origin/<branch>`.
   5. Only after that readback, delete branches whose history is contained in the pushed branch.

7. **Delete branches with a rollback file.** Deletion needs the user's go that names it.
   - First write every target's full SHA to a backup file outside temp directories: `git for-each-ref --format='%(objectname) %(refname)' <refs>` plus `git ls-remote --heads origin <names>`. That file is the whole rollback (`git branch <b> <sha>`, `git push origin <sha>:refs/heads/<b>`).
   - Split targets into remote plus local, local-only, and stale tracking refs (present under `refs/remotes/origin/` but absent from `ls-remote`). Only the first group gets a remote delete.
   - Per branch, confirm: local tip equals remote tip, `git merge-base --is-ancestor <sha> main`, not checked out in any worktree, not the default branch, and no open pull request uses it as head.
   - Delete the remote ref first, in its own call, then the local one with `git branch -d`. `-d` refuses unmerged work; never reach for `-D` to get past it.
   - `-d` checks against the branch's upstream, or `HEAD` when none is set. A branch with no upstream on a checkout whose local `main` is stale (a build machine, a second clone) is refused even when `origin/main` contains it: fetch, confirm with `git branch --merged refs/remotes/origin/main`, set `git branch -u origin/main <b>`, then `-d`. A branch whose upstream already contains its tip deletes normally. Do not fast-forward that checkout's `main` unasked.
   - Finish with `git fetch --prune origin` and read back `git for-each-ref refs/heads refs/remotes` and `git ls-remote --heads origin`. Release tags keep merged commits reachable; say so.

8. **Answer "where did the file go" from the filesystem and Git separately.** `git diff` never shows untracked or ignored files, so an empty diff proves nothing about a missing file. Check:
   - the filesystem, including ignored files (`rg --files -uu`, or `ls -a`);
   - `git ls-files --error-unmatch <path>` (exit 1 means not in the index: untracked, ignored, or absent alike, so use the other checks to tell them apart);
   - `git check-ignore -v -- <path>`, which names the exact rule and file;
   - `git log --all --full-history -- <path>` for historical copies.
   Report the absolute path and one status: tracked, untracked, ignored, historical-only, or absent.

9. **Treat a deliberate exclusion as a decision.** When asked to commit a file that is ignored, `check-ignore -v` tells you who decided: `.gitignore` is a shared team decision, `.git/info/exclude` is one clone's private decision (common for local agent notes), and a global excludes file is user-wide noise. An exclusion rule means stop and ask. A file that documents its own exclusion means recommend doing nothing. A file holding credentials is never committed, whatever the request. "No secrets in it" is not enough to commit: local notes, per-person assignment lists, and internal strategy are still visible to everyone on a shared branch. Offer doing nothing, or versioning it privately (a dotfiles or private repository). Editing the exclude rule so the commit works is a second, unrequested policy change.

## Pitfalls

- **Counting branches is not evidence.** Twenty old branches can all be merged; one recent one can hold the only copy of a fix.
- **A session summary is not the owner's intent.** For behavior-sensitive state, compare against the owner's last explicit instruction before calling a branch a regression or proposing a restore.
- **Stale snapshot commits.** A branch holding a prepared change for an event that never ran (a maintenance window, a resize, a migration) describes the state at that time. Re-check the live state before re-arming it, and do not merge it blindly.
- **State documents: check before you claim, and clean both halves.** Before saying a status or handoff file exists, check its exact path in the filesystem and in Git; memory and earlier reports are hints, not evidence. If it is already gone, do not recreate it or stage a deletion. When you remove one, also remove the instructions that point to it, or the next agent recreates it; when both the deletion and the reference cleanup were asked for, do both in one pass instead of asking again. Keep durable history, labeled as historical.
- **Do not populate an empty owner file** just because a request mentioned it.
- **One blocked command is not a blocked task.** If an authorized exact ref deletion is refused by a shell guard on one porcelain command, an equally narrow plumbing command (`git update-ref -d refs/heads/<name>`) does the same thing; verify the ref afterward. Never use the workaround to widen scope.
- **Corrupt tracking ref.** `fatal: bad object refs/remotes/origin/main` on fetch usually means the tracking ref file holds a null or truncated SHA. Delete only that tracking ref (`git update-ref -d refs/remotes/origin/main`) and fetch again; local branches are untouched.
- **"No commits between main and branch" on a pull request.** The commit was made on `main` before the branch was cut, so both point at the same SHA. Check `git rev-list --count origin/main..<branch>` is at least 1 before opening the request. Prevent it by creating the branch first, then committing. If it already happened: on `main`, `git reset --soft origin/main`, drop the staged change (`git restore --staged . && git checkout -- .`), switch to the branch, and `git cherry-pick <stray-sha>` onto it. If the wrong SHA was already pushed, fixing the branch needs a force push, which needs its own go. In fork or multi-remote setups the request can also fail on repository detection alone: name the repository explicitly in the request command before touching history.
- **Cleanup commits break consumers.** After a sweep that deletes files, search the remaining tree for every deleted path. A retained script that loads a deleted data file, or a report that cites it, leaves a broken path. Either restore the file or retire every consumer in the same change.

## Done When

The report states, per repository:

1. Canonical branch and its remote-verified SHA.
2. Each branch classified (merged, equivalent, reverted, or unique), with the command output that decided it.
3. Deployed, source, and canonical identities when deployment matters.
4. What changed: exact refs and files; what was deleted, and the rollback file path.
5. Dirty or human-owned work left untouched.
6. Whether anything was pushed, released, or deployed.
