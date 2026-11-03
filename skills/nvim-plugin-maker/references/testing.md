# Testing plugins headless (plenary busted)

Set the harness up before feature code; retrofitting tests is far more work. `plenary.nvim` is a test dependency here, cloned into `deps/` and kept out of git.

## Makefile

```make
PLENARY_DIR ?= deps/plenary.nvim
NVIM ?= nvim

test: $(PLENARY_DIR)
	$(NVIM) --headless --noplugin -u tests/minimal_init.lua \
		-c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/minimal_init.lua' }"

test-file: $(PLENARY_DIR)
	$(NVIM) --headless --noplugin -u tests/minimal_init.lua -c "PlenaryBustedFile $(FILE)"

$(PLENARY_DIR):
	git clone --depth 1 https://github.com/nvim-lua/plenary.nvim $(PLENARY_DIR)

.PHONY: test test-file
```

- `--depth 1`: full plenary history is wasted CI time. Add `deps/` to `.gitignore`.
- `NVIM ?=` lets CI or a developer point at another binary: `make test NVIM=/path/to/nightly/nvim`.
- Exit code: 0 when every spec passes, non-zero when one fails, so CI can use `make test` directly.

## tests/minimal_init.lua

```lua
-- Isolated runtimepath: this plugin, plenary, and Neovim's runtime. Nothing
-- from the user's config.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local plenary = vim.env.PLENARY_DIR or (root .. "/deps/plenary.nvim")

vim.opt.runtimepath = { root, plenary, vim.env.VIMRUNTIME }
vim.opt.packpath = {}
vim.opt.swapfile = false -- parallel spec processes collide on swap files

-- --noplugin skips plugin/ scripts, including plenary's, so load it by hand.
vim.cmd("runtime plugin/plenary.vim")
```

### `--noplugin` and the plenary command

`--noplugin` keeps stray plugins out of the run, but it also skips `plenary/plugin/plenary.vim`, which defines `PlenaryBustedDirectory`. Without the `runtime plugin/plenary.vim` line the run prints `E492: Not an editor command: PlenaryBustedDirectory` and then **hangs** instead of exiting, which looks like a stuck test in CI.

Two setups work: `--noplugin` plus the `runtime` line (above), or no `--noplugin` and no `runtime` line, relying on the isolated `runtimepath`. Pick one; do not mix them.

## Optional dependency stubs

```lua
-- in minimal_init.lua: lets specs require an optional dependency that is not installed
if not pcall(require, "some-optional-dep") then
  package.preload["some-optional-dep"] = function()
    return { open = function() end, close = function() end }
  end
end
```

## Spec shape

```lua
-- tests/config_spec.lua
describe("config", function()
  local config

  before_each(function()
    package.loaded["myplugin.config"] = nil -- fresh module state per test
    config = require("myplugin.config")
  end)

  it("merges user opts over defaults", function()
    config.setup({ width = 42 })
    assert.equals(42, config.get().width)
    assert.is_not_nil(config.get().keymaps.accept) -- default survived
  end)
end)
```

The `package.loaded[...] = nil` reset matters most *(verify)*. Without it, module-level state leaks between specs: the suite passes as a whole but a spec fails alone, or reordering breaks it.

## Async and vim.uv code

Specs run on the main loop. `vim.uv` callbacks need the loop to turn, so poll with `vim.wait`, which pumps the loop:

```lua
it("server accepts a connection", function()
  local got_client = false
  server.start(function() got_client = true end)

  assert.is_true(vim.wait(2000, function() return got_client end, 10), "timed out")

  server.stop() -- leaked handles hang the headless run
end)
```

`vim.wait` returns true as soon as the predicate holds and false on timeout *(verify)*. Never use a bare sleep.

**`make test` hangs?** Almost always a `vim.uv` handle (timer, socket, fs watcher) that was never closed, or the plenary command missing (see above). Put `stop()` calls in `after_each` so a failing assertion cannot skip them.

## Red, then green

When a spec is written for a bug or new behavior, run it before the fix and check it fails **for the expected reason**. "module not found" is not the same failure as a wrong assertion. Then implement, and stop when `make test` is green with no error output.

## Fixtures and sandboxes

Small fixture files live in `tests/fixtures/` and are committed. Throwaway files come from `vim.fn.tempname()` and are deleted in the spec. A spec never writes into the repo tree.

```lua
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")
local cwd = vim.fn.getcwd()
vim.fn.chdir(dir)
-- ... test ...
vim.fn.chdir(cwd)
vim.fn.delete(dir, "rf")
```

## Real transport, not mocks

Test socket servers with a real `vim.uv.new_tcp()` client: connect, write bytes, poll for the reply with `vim.wait`. It catches framing bugs a mocked transport hides. Close the client and stop the server in `after_each`.

## Temporary global overrides

```lua
it("works without TMUX", function()
  local saved = vim.env.TMUX
  vim.env.TMUX = nil
  -- ... test ...
  vim.env.TMUX = saved
end)
```
