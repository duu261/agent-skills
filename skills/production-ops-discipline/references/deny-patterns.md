# Deny patterns

A sample hard-deny list for agent shell commands, with what it deliberately leaves alone and why. Use it as a seatbelt for honest mistakes, not as a sandbox.

The skill's rules tell an agent not to run these commands. A deny rule makes the harness refuse them even when the agent forgets. In the field notes behind this file, standing rules already required approval for any deletion, and an agent still ran a host-wide prune inside a test cleanup. A deny rule would have stopped it.

## How the list was built

Each pattern was replayed against one operator's real agent history: about 22,000 shell commands for the first list, about 34,000 by the time the later Docker rows were added. Every new match was then sorted as harmful, legitimate, or mention-only. A pattern stayed only when it caught real harm and broke almost no legitimate work.

- A first draft used filename patterns (`*.env`) and a broad `*printenv*`. Replayed, it would have broken about 650 legitimate jobs, mostly deploys that pass `--env-file`, backup copies of env files, and `printenv` of one named variable inside a container. It was replaced by patterns for the ways a secret actually gets dumped.
- The final 33-pattern list (secrets, force-push, lockout, and the first data-wipe rows) matched 209 of about 22,000 commands at the time. About 200 were real exposures, mostly `set -a` exports of an env file and `/proc/*/environ` reads. Only 1 was a legitimate job.

## Sample list

Hermes Agent `approvals.deny` glob syntax: `fnmatch`, case-insensitive, matched against the whole command text. Translate the intent, not the text, for other harnesses (see "Other harnesses").

| Risk | Patterns |
|---|---|
| Secret exposure | `*set -a*`, `*set -o allexport*`, `printenv`, `* printenv`, `*printenv \|*`, `env`, `env \|*`, `* env \|*`, `*docker* exec * env`, `*/proc/*/environ*`, `*compose* config`, `*compose* config \|*`, `*dotenv_values*`, `*load_dotenv(*` |
| Force-push | `git push --force`, `git push --force *`, `* git push --force`, `* git push --force *`, the same four for `-f`, `*git push * --force`, `*git push +*`, `*git push * +*` |
| Lockout | `*ufw disable*`, `*ufw reset*`, `*tailscale down*`, `*tailscale logout*` |
| Data wipe | `*redis-cli*flushall*`, `*redis-cli*flushdb*`, `*drop database*`, `*prune*--volumes*`, `*docker volume prune*`, `*docker system prune*`, `*docker container prune*`, `*docker compose* down -v*`, `*docker compose* down * -v*`, `*docker-compose* down -v*`, `*docker-compose* down * -v*`, `*docker*down*--volumes*` |

`*compose* config` blocks only the bare and piped forms, which print every interpolated secret. `docker compose config --quiet` still runs.

## The incident behind the Docker rows

A smoke test started a throwaway container and cleaned up with `docker volume prune -f` in its exit trap. Prune is host-wide. It deleted every unused anonymous volume on the host, not just the test's own. Docker keeps no record of what a pruned volume held. Command history points to leftovers from earlier test database containers, which had been started without `--rm` and removed with `docker rm -f`. That removes the container but keeps its anonymous volume. Production data sat on bind mounts and named volumes, so it survived.

Replayed against history, the three prune patterns matched 3 commands: this incident, plus two deliberate wipes of a retired host that the operator now runs by hand. The five `down -v` patterns matched 4 of 1,145 commands containing "down": two one-off teardowns and two commands that only quoted the patterns.

## Deliberately not blocked

| Command | Why it stays allowed |
|---|---|
| `docker volume rm <name>` | Removing a test volume by exact name is a real workflow. The danger in prune is scope, not the verb. |
| `docker rm -v`, `docker run --rm` | These delete only the container's own anonymous volumes. They are the fix for orphans. |
| `docker compose down` (no `-v`) | Keeps named volumes. |
| `docker compose rm -v` | Removes only anonymous volumes of stopped services. Low risk when real data is on named volumes or bind mounts. |
| `docker image prune`, `docker builder prune` | Images and build cache can be rebuilt or pulled again. Caveat: if a container runs an untagged image and is then removed, a later image prune deletes that image. |
| `git push --force-with-lease` | The lease refuses to overwrite commits you have not seen. |
| `dropdb`, `TRUNCATE`, `git reset --hard`, `iptables -F` | History showed legitimate uses, such as resetting a test database. Leave these to approval prompts and the skill's rules. |
| Secret filenames (`*.env`) | Deploys legitimately name env files. Block how a secret gets exposed (`set -a`, `printenv`, `/proc/*/environ`), not where it is stored. |
| `docker inspect` | Most uses are safe `--format` reads. The skill's rule (always pass `--format`, never dump the env block) covers it better than a pattern. |

## Pitfalls

- **Plain `volume prune` vs `-a`.** On Docker Engine 23 and later, `docker volume prune` removes only unused anonymous volumes. `-a` also removes unused named volumes. A stopped container still protects its volumes. A stack taken down with `compose down` does not, so `prune -a` during a maintenance window can delete its database volume.
- **Whole-text matching blocks mentions.** `rg 'docker volume prune' notes.md` and `echo docker volume prune` are refused like the real command. Search for a shorter token (`volume prune`). Never requote or encode a command to get past a block. That is a bypass.
- **A `*` spans chained commands.** `*docker compose* down * -v*` also matches `docker compose down && docker run -v ...`. Run the two commands as separate calls.
- **The list blocks its own edit.** An agent applying a new list puts every existing pattern into the command text, so `*set -a*` blocks the apply. That is the intended behavior: the owner applies deny-list changes. The agent hands over a script that sets the full list and then reads it back.
- **Anchor on spaces, not letters.** `*docker*down*-v*` also caught `--verbose`, `--version`, and `docker run --name down -v`. `*git push*+*` caught `g++` and `feat+login`. Write `* down -v*` and `*git push +*`.
- **Check suffix variants.** `*.env` is end-anchored and misses `.env.local`.
- **Not a security boundary.** Depending on the harness, `/bin/rm`, `bash -c '...'`, or a different flag order can slip past a text rule. The threat model is an honest agent's slip. For hard isolation, use the harness sandbox or withhold the credential.
- **Replay before you ship.** Run every new pattern against your own command history through the harness's real matcher. A list that blocks a weekly job gets switched off.

## Other harnesses

- **Claude Code:** `permissions.deny` with `Bash(...)` rules, for example `Bash(docker volume prune *)`. Claude Code splits compound commands and strips wrappers such as `timeout` and `nice` before matching. A deny rule still does not match `/bin/rm` or `bash -c`. See the [permissions docs](https://code.claude.com/docs/en/permissions). A `PreToolUse` hook can apply custom logic.
- **Codex:** `prefix_rule(pattern=[...], decision="forbidden")` in a `.rules` file. Rules govern commands that ask to run outside the sandbox; inside it, the sandbox is the guard. Patterns are token prefixes, so `docker compose -p x down -v` needs its own rule. Test with `codex execpolicy check`. See the [rules docs](https://learn.chatgpt.com/docs/agent-configuration/rules).
- **Parser-based hooks:** [dcg](https://github.com/dicklesworthstone/destructive_command_guard) tokenizes commands, so it does not block a `grep` for a dangerous string. It ships an environment-variable bypass that an agent can also type, so decide whether to keep it. [irreversible-command-gate](https://github.com/jedarden/irreversible-command-gate) tells the agent the safe alternative with every denial.
