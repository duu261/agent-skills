#!/usr/bin/env bash
# Read-only: classify local branches against a base by ancestry and patch identity.
# Usage: classify_branches.sh [base] [backup-file]
#   base         default: origin/HEAD's branch (for example origin/main), else main
#   backup-file  optional; writes "<full-sha> <ref>" for every local and remote branch,
#                which is the rollback list to keep before deleting anything.
# Lists every local branch except the base itself. A local branch whose tip equals the
# base (for example local main == origin/main) is reported as "same as base".
# Writes nothing to the repository. Run `git fetch` yourself first if remote refs matter.
set -euo pipefail

base="${1:-}"
if [ -z "$base" ]; then
  base=$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null || echo main)
fi
base_sha=$(git rev-parse --verify -q "$base^{commit}") || { echo "unknown base: $base" >&2; exit 2; }

if [ -n "${2:-}" ]; then
  if [ -e "$2" ]; then echo "refusing to overwrite $2" >&2; exit 2; fi
  git for-each-ref --format='%(objectname) %(refname)' refs/heads refs/remotes > "$2"
  echo "backup: $2 ($(wc -l < "$2") refs)"
fi

current=$(git symbolic-ref -q --short HEAD || true)
worktree_branches=$(git worktree list --porcelain | sed -n 's|^branch refs/heads/||p')

# Exact string match; branch names are not patterns (release-1.0 must not match release-1x0).
in_worktree() {
  local name
  while IFS= read -r name; do
    [ "$name" = "$1" ] && return 0
  done <<< "$worktree_branches"
  return 1
}

printf '%-40s %6s %6s %6s  %s\n' BRANCH BEHIND AHEAD UNIQUE VERDICT
git for-each-ref --format='%(refname:short)' refs/heads | while IFS= read -r b; do
  [ "$b" = "$base" ] && continue
  read -r behind ahead < <(git rev-list --left-right --count "$base...$b")
  unique=$(git cherry "$base" "$b" | grep -c '^+' || true)
  if [ "$(git rev-parse "$b^{commit}")" = "$base_sha" ]; then
    verdict="same as $base"
  elif [ "$ahead" -eq 0 ]; then
    verdict="merged (ancestor of $base)"
  elif [ "$unique" -eq 0 ]; then
    verdict="equivalent (patches already on $base under other SHAs)"
  else
    verdict="UNIQUE: $unique patch(es) not on $base; check for revert chains before calling it lost"
  fi
  notes=""
  [ "$b" = "$current" ] && notes=" [checked out]"
  if [ "$b" != "$current" ] && in_worktree "$b"; then notes="$notes [in a worktree]"; fi
  printf '%-40s %6s %6s %6s  %s%s\n' "$b" "$behind" "$ahead" "$unique" "$verdict" "$notes"
done
