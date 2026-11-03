# nvim-plugin-maker

English | [Tiếng Việt](README.vi.md)

**For anyone building a Neovim plugin with an agent that keeps writing last year's API.**

Models learn Neovim from code written before their cutoff. Neovim keeps renaming things: 0.12 renamed the `buffer` key to `buf` and `vim.diff` to `vim.text.diff`, and 0.13 moves the `vim.uri_*` functions under `vim.uri`. Agents also call `vim.api` inside `vim.uv` callbacks, which fails with `E5560`, and leave timers open until `make test` hangs.

This skill gives the agent a plugin layout, a headless plenary test harness, the rules that keep a plugin from crashing or wedging the editor, and an API reference. Every version-sensitive API claim is tagged with the Neovim version it holds for. `scripts/verify.lua` runs those claims against a real Neovim (37 checks), and CI runs it every week on 0.11.6, stable, and nightly. When Neovim changes something, the build fails instead of the reference going quietly wrong.

## Where it came from

The maintainer built it in Claude Code and refined it with the skill-creator evals there: five plugin tasks covering scaffolding, an async file watcher, release prep, extmarks with buffer-local keymaps, and a `vim.ui.input` rename flow. Then `gpt-5.6-sol` used it in Codex CLI across 17 sessions to build [duke.nvim](https://github.com/duu261/duke.nvim), a Maven and Gradle project tool for Neovim. The duke.nvim [project story](https://github.com/duu261/duke.nvim/blob/main/PROJECT-STORY.md) describes the workflow.

The maintainer and `claude-opus-5-5` refreshed it in November 2026. They ran every API claim on Neovim 0.11.6, 0.12.6, and 0.13-dev and fixed the ones that had gone stale:

- the `buffer` to `buf` rename, and the `vim.diff` rename
- `ephemeral` extmarks, which error outside a decoration provider
- a test-harness rule that banned `--noplugin`, even though duke.nvim's working harness uses it
- the Neovim version pin and the CI action versions

They also cut ceremony that the real sessions showed was wasted: test-first on every fix, reading every reference at the start of every session, and a description so broad it loaded on personal config edits.

No controlled with-and-without run backs it. It is a reference, not a benchmark claim.

## Install

```bash
npx skills add duu261/agent-skills --skill nvim-plugin-maker
# Hermes Agent
hermes skills install duu261/agent-skills/skills/nvim-plugin-maker
```

Or copy `skills/nvim-plugin-maker/` into your harness's skills directory.

Check the references against your own Neovim:

```bash
nvim --clean --headless -l skills/nvim-plugin-maker/scripts/verify.lua
```

## License

MIT
