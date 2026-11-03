---
name: nvim-plugin-maker
description: Build, test, and release Neovim plugins in pure Lua. Use when creating or extending a Neovim plugin, setting up headless plenary tests or plugin CI, writing a health check or vimdoc, or writing vim.uv async code, autocmds, extmarks, or keymaps inside a plugin. Covers the plugin layout, the never-crash-Neovim rules for callbacks and fast events, and an API reference whose claims scripts/verify.lua checks against the running Neovim. Not for editing a personal init.lua.
license: MIT
---

# Neovim Plugin Maker

Pure Lua plugins: correct layout, a headless test harness, callbacks that cannot take the editor down, and a clean release. No Node, no Rust, no runtime dependencies unless the user asks.

The references are the main value here. Neovim renames APIs between releases (0.12 renamed the `buffer` key to `buf`, `vim.diff` to `vim.text.diff`), and a model trained before a release writes the old names. Every version-sensitive claim in `references/` carries the version it holds for, and `scripts/verify.lua` checks them on the Neovim you run.

## When to Use

- Creating a plugin, or adding a feature, test, health check, vimdoc, or CI to one.
- Writing `vim.uv` timers, sockets, file watchers, `vim.system` callbacks, autocmds, extmarks, or buffer-local keymaps in plugin code.
- `make test` hangs, specs pass together but fail alone, or `E5560` shows up.

Not for: tuning a personal Neovim config. The layout and release rules below do not apply there.

## Workflow

1. **Existing plugin?** Read what is there first (`lua/`, `plugin/`, `tests/`, `Makefile`, CI). Do not rescaffold or restyle working code. Do one vertical slice: the smallest requested change, its spec, `make test`, stop.
2. **New plugin:** create the layout below and the test harness (`references/testing.md`) before feature code. Done when `make test` runs one passing spec.
3. **Write tests where behavior can regress:** async, IO, config merge, commands, anything parsing input. Skip them for one-line glue and for docs-only changes.
4. **Wire the surface:** `setup()`, user commands, health check (`references/architecture.md`).
5. **Release:** README, vimdoc, CI, tag (`references/release.md`), only when the user is releasing.

Match ceremony to the change. A README fix does not need a CI run; a tested fix does not need a second full verification pass.

## Layout

```
myplugin.nvim/
├── lua/myplugin/
│   ├── init.lua          -- setup(), public API
│   ├── config.lua        -- defaults, merge, get()
│   ├── health.lua        -- :checkhealth myplugin
│   └── <feature>.lua     -- one responsibility per file
├── plugin/myplugin.lua   -- command registration only
├── doc/myplugin.txt      -- vimdoc
├── tests/
│   ├── minimal_init.lua
│   └── <feature>_spec.lua
├── Makefile              -- make test
├── stylua.toml
└── .luacheckrc
```

- `plugin/*.lua` runs at startup for every user. It only registers commands and autocmds whose callbacks `require()` the module on first use. Real work at startup is a bug users will file.
- The plugin must work when `setup()` is never called. Read options through a `get()` that falls back to defaults; lazy.nvim users often skip `setup()`.
- One file, one responsibility, small explicit interfaces between them. That is also what makes them testable headless.

## P0: never crash or wedge Neovim

These are the failures that get a plugin uninstalled. `scripts/verify.lua` checks the fast-event and handle-close rules.

- **Fast events cannot touch the editor.** `vim.uv` callbacks (timers, sockets, fs events) and `vim.system` `on_exit` callbacks run in a fast event. Calling `vim.api`, most of `vim.fn`, or reading buffers there fails with `E5560: ... must not be called in a fast event context`. Wrap the editor work in `vim.schedule()` or the callback in `vim.schedule_wrap()`. `jobstart` callbacks are not fast. `vim.in_fast_event()` tells you where you are.
- **Catch errors in every callback Neovim or libuv calls.** An uncaught error there does not kill Neovim, but the user gets a stack trace, and the code after the error never runs, so the handle you meant to close stays open. Wrap the body in `pcall`, notify once, log the detail.
- **Close what you open.** Timers (`timer:stop(); timer:close()`), sockets, fs watchers, temp files, autocmd groups, namespaces. A leaked handle hangs `make test` and plugin reloads. Keep every handle reachable from one module table and release them all in `stop()`.
- **Notify once, log the rest.** `vim.notify_once` for user-facing failures; detail goes to a log the user can open. Repeated notifications train users to uninstall.
- **Secrets and sockets:** tokens from `vim.uv.random()`, never `math.random`. Never log them. Bind listeners to `127.0.0.1`, never `0.0.0.0`. Cap the read buffer for any peer you do not control.
- **Paths:** `vim.fn.fnameescape()` before putting a path in an Ex command, or use the table form `vim.cmd({ cmd = "edit", args = { path } })`.

## Versions

Declare the minimum Neovim version in the README and in `health.lua`, and test that exact version in CI next to stable and nightly. Do not polyfill older versions unless asked; each extra version doubles the test matrix.

When you support a version where an API was renamed, use the old name until you drop that version, and note the rename in a comment. The rename table is in `references/api.md`.

## Dependencies

Builtins first. Add a dependency only when it removes real work.

- `plenary.nvim`: test dependency by default (the busted runner). Runtime dependency only if shipped code needs its modules.
- `nui.nvim`: layouts and stateful UI. For one prompt or list, `vim.ui.input()` / `vim.ui.select()` first.
- `telescope.nvim`: only for Telescope pickers. `nvim-web-devicons`: icon-heavy lists.

A runtime dependency goes in the README install snippet with the reason it is needed.

## References

Read the one the task needs, not all of them.

- `references/api.md`: buffers, extmarks, autocmds, keymaps, `vim.uv`, `vim.system`, notify, options, and the rename table by version. Read before writing API calls.
- `references/lua-version.md`: Lua 5.1 as the interface, what LuaJIT adds, what is missing. Read when unsure whether a Lua feature exists.
- `references/architecture.md`: config merge, lazy commands, health check, logging, async patterns, atomic file writes, debounce, sockets. Read when wiring the plugin surface or async code.
- `references/testing.md`: `minimal_init.lua`, Makefile, spec isolation, async tests, why `make test` hangs. Read when setting up or debugging tests.
- `references/release.md`: README, vimdoc, CI, tags. Read at release time.

## Pitfalls

- **Old API names from training data.** Check `references/api.md` before writing `buffer =`, `vim.diff`, `vim.uri_from_fname`, or `ephemeral = true`.
- **`--noplugin` without loading plenary.** The test command fails with `E492: Not an editor command: PlenaryBustedDirectory` and then hangs instead of exiting. See `references/testing.md`.
- **Rewriting a working plugin to match this layout.** The layout is for new plugins. In an existing one, follow its conventions.

## Verification

- `make test` exits 0 with zero failures and no error output.
- `:checkhealth myplugin` is accurate on a clean config.
- After a Neovim upgrade, or before trusting a reference claim: `nvim --clean --headless -l scripts/verify.lua` from this skill's folder. Any `FAIL` line names the reference file to fix.
