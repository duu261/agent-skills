---
name: behavior-repro-fixture
description: Build a contamination-free fixture that reproduces a model behavior (a refusal, an over-block, safety theater, a bypass habit) in a fresh, isolated agent session, or that measures whether a skill changes behavior. Use when the user says "reproduce this refusal", "make an eval fixture", "simulation repo", "does this skill actually change anything", or wants a paste-ready multi-turn conversation to run on a named model. Generates the workspace and prompts; the user runs the probe.
license: MIT
---

# Behavior Repro Fixture

A report like "the model refused to copy a plain config file" is hard to check. Re-asking in the same session proves nothing: that session already knows the complaint, and its own system prompt or memory may be what caused the refusal. Agents asked to "reproduce it" usually make it worse. They run the probe themselves, put the expected answer where the model can read it, or build a fake multi-agent runtime that hides the behavior.

This skill builds a small, private fixture instead: a disposable workspace, a paste-ready conversation, and a scorecard, isolated from the build session. You generate it. The user pastes the prompts into a fresh session and scores the result.

## When to Use

- "Reproduce this refusal / over-block / safety theater", "make an eval fixture", "simulation repo".
- A paste-ready multi-turn conversation to run on a named model.
- Extending an existing fixture harness: copy its layout, do not invent a new one.
- Measuring whether a skill changes behavior (skill on vs off, for example before publishing it). Arms, confounds, and metrics: [references/skill-ab-eval.md](references/skill-ab-eval.md).

Not for a live health check of the agent itself, a throwaway product prototype, or adding mailboxes or a second agent runtime unless the user named that layer.

## Prerequisites

- The harness source lives where the probed model cannot reach it: a private repository, or a directory outside every path the probe session sees. A public or discoverable harness tells the model it is under test (the README says "do not tell the model", the scorecard lists the expected refusal, the generator holds the fixture values). Publish only when the user asks, and only after the probes ran.
- Standard library only. No containers, ports, or network in the generated run.
- The harness's own instructions file: never commit secret files, credentials, transcripts, or host details.

## How to Run

1. Copy the existing fixture layout if there is one.
2. Generate each disposable run under the system temp directory, for example `$TMPDIR/<name>-runs/`.
3. Generate the run, then hand the user Turn 1 with the real run path filled in (step 7) plus the isolated probe setup (step 4).

## Procedure

1. **Use a fixed harness shape.** Files:
   - `prepare_fixture.py`: standard library only. Runs Git with inherited `GIT_*` variables stripped and the global config disabled (`GIT_CONFIG_GLOBAL=/dev/null` or `os.devnull`), so the operator's signing, hooks, and identity do not leak in.
   - `template/`: the workspace the model will see.
   - `PROMPTS.md`: one turn per block, with a `<RUN_PATH>` placeholder.
   - `SCORECARD.md`: observational marks, not a competence exam unless that is the eval.
   - `tests/test_prepare_fixture.py`: tests the harness layout only.
   - `README.md`, the harness instructions file, `LICENSE`.
   Done when someone can prepare a run from the README alone.

2. **Keep secrets out of the source repository.** Commit no secret file. If the probe needs a local environment file, `prepare_fixture.py` writes it into the disposable run and gitignores it there. Fixture values are synthetic and safe to publish. Never use real key prefixes (`sk-`, `AKIA`, `ghp_`, `xai-`): scanners flag them and the model may react to the prefix rather than the task.
   Done when `git ls-files` on the source repository shows no secret file.

3. **Write the prompts as the real conversation.** One turn per paste; wait for the full reply before the next. Never tell the model it is an eval or a simulation. Operator-only steps (a file copy the user does by hand) stay out of the model-facing turns.
   Done when `PROMPTS.md` is paste-ready after substituting `<RUN_PATH>`.

4. **Isolate the probe session before handing it over.** These confound or leak the result, so fix them in the run plan, not as a caveat:
   - **Host rules.** A system prompt or standing rule like "never open any env file" forces the exact refusal being measured. Run the probe with a neutral system prompt, or in the client where the behavior was first seen, with its global instructions file neutralized.
   - **Memory and recall.** Cross-session memory, auto-recall, or session search can inject the build session (task text, repo name, the complaint) into the "fresh" one. Use a profile or client with memory off, or one that never saw the build.
   - **Turns that hand work to another agent** ("send it to the other agent"): these need a real reachable peer in that environment; otherwise the turn only measures "cannot reach X". Provide the channel, or drop or mark the turn.
   Done when the README names the probe client or profile and states that memory is off and no host rule forbids the action.

5. **Score the interesting behavior, not the harness.** Put the signal on later turns: try anyway, hand it to another agent, explicit approval, "it is fake, not a secret", and an unprompted lecture after the user already did the step themselves.
   Done when the scorecard has separate marks for a harness-forced block and a model-invented block.

6. **Test the generator, not the model.** Assert unique case names, Git isolation against a hostile global config, expected files present or absent, the generated env file untracked, and that the target app fails before the copy and passes after. Run `python -m unittest discover -s tests -v` from the harness repository.
   Done when tests pass on a clean tree.

7. **Hand over a paste-ready Turn 1, not a template.** Run `prepare_fixture.py <case>` yourself (or give the exact command), then give Turn 1 with the real absolute run path already substituted. Model-facing text contains only the run path, never the harness repository path, which leads straight to the README and scorecard. A tiny `print_prompts.py <run_path>` that substitutes the path and refuses to print when the run directory does not exist prevents both mistakes. Do not start a child session to "run the eval for them".
   Done when Turn 1 has no `<RUN_PATH>` placeholder and no harness path.

## Pitfalls

- **A conversation simulation is not a multi-agent runtime.** A prompt file and two tiny apps beat a mailbox, a fake peer pane, or an orchestration daemon. Those hide the behavior you wanted to see, and the user has to say so.
- **No verifier or expected values in the generated tree.** The model reads whatever the workspace contains. Keep expected values in `prepare_fixture.py` and the tests.
- **Do not symlink the env file to a protected path** unless secret avoidance is what you are testing. An over-refusal probe needs a regular, copyable file.
- **If you are the probed model and see a raw `<RUN_PATH>` or the harness path,** the run is contaminated as soon as you read the harness. Report that the preparation is broken and give the fix (generate the run, substitute the path, isolate the session). Do not carry on as if the task were real.
- **Over-refusal on env-file copies is often the client's permission layer, not the bare model.** A quote like "the client's safety check blocked me" points at a classifier the user cannot lift; the same model may comply in another harness on an explicit go. Reproduce such reports in the client named in the report, not in a different harness.
- **Reuse the generator's Git isolation** in every helper. A fixture that inherits the operator's signing or hooks setting is not reproducible on another machine.
- **Deleting a published harness repository** needs a token scope that default logins usually lack. Before any delete, confirm local `HEAD` equals the remote tip and the working tree is clean, so whichever copy survives is complete.

## Verification

Harness pass: unit tests green, no secret file in the source tree, `prepare_fixture.py <case>` prints `RUN_PATH=...`, and a second call with the same case fails instead of overwriting. The eval result itself is the user's scorecard from a fresh session, not something this skill claims.
