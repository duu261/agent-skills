# Neovim Lua API: plugin reference

High-use patterns, copy-pasteable. A version tag like **0.12+** means the line holds from that release on. Claims marked *(verify)* are checked by `scripts/verify.lua`; claims marked *(docs)* come from `:help deprecated` and are not run-checked.

## Renames by version

Models trained before a release write the old name. Use the new one when your minimum version has it; otherwise keep the old one and leave a comment.

| Old | New | New name exists from | Old name still works |
|---|---|---|---|
| `buffer =` key in `nvim_create_autocmd`, `nvim_get_autocmds`, `nvim_exec_autocmds`, `nvim_clear_autocmds` | `buf =` | 0.12 *(verify)* | yes, through 0.13-dev *(verify)* |
| `buffer =` in `vim.keymap.set` / `vim.keymap.del` opts | `buf =` | 0.12 *(verify)* | yes, through 0.13-dev *(verify)* |
| `vim.diff()` | `vim.text.diff()` | 0.12 *(verify)* | yes, deprecated |
| `vim.uri_from_fname()`, `vim.uri_to_fname()`, `vim.uri_from_bufnr()`, `vim.uri_to_bufnr()` | `vim.uri.from_fname()`, `vim.uri.to_fname()`, `vim.uri.from_buf()`, `vim.uri.to_buf()` | 0.13 *(verify for from_fname)* | yes |
| `nvim_win_set_height()` / `nvim_win_set_width()` | `nvim_win_resize()` | 0.13 *(docs)* | yes |
| `vim.F.if_nil()` | `vim.nonnil()` | 0.13 *(docs)* | yes |
| decoration provider `on_line` | `on_range` | 0.12 *(docs)* | yes |
| `vim.loop` | `vim.uv` | 0.10 | alias, deprecated |

On 0.11, `buf =` is an error: `invalid key: buf` *(verify)*. A plugin that supports 0.11 must keep `buffer =`.

`vim.fs.ext()` exists only from 0.12 *(verify)*.

## Buffers

```lua
-- Lines are 0-indexed, end-exclusive. buf = 0 is the current buffer.
local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
vim.api.nvim_buf_set_lines(buf, start, finish, false, replacement) -- start == finish inserts; {} deletes

vim.api.nvim_buf_get_name(buf)   -- full path or ""
vim.api.nvim_buf_is_valid(buf)   -- handle still exists
vim.api.nvim_buf_is_loaded(buf)  -- valid and loaded; check before reading lines
```

Scratch buffer:

```lua
local buf = vim.api.nvim_create_buf(false, true) -- unlisted, scratch
-- scratch=true already sets buftype=nofile, bufhidden=hide, noswapfile (verify)
vim.bo[buf].bufhidden = "wipe"  -- if it should vanish when hidden (buffer-local keymaps go with it)
vim.bo[buf].modifiable = false
-- remove: vim.api.nvim_buf_delete(buf, { force = true })
```

## Extmarks

```lua
local ns = vim.api.nvim_create_namespace("myplugin")

vim.api.nvim_buf_set_extmark(buf, ns, row, col, {
  end_row = row, end_col = col_end,   -- highlight range
  hl_group = "Search",
  virt_text = { { "text", "Comment" } },
  virt_text_pos = "eol",              -- "eol" | "overlay" | "right_align" | "inline" (verify inline)
  sign_text = ">>",                   -- 1-2 cells in the sign column
})

vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1) -- teardown
```

`ephemeral = true` is only valid inside a decoration provider callback. Anywhere else it errors: `cannot set emphemeral mark outside of a decoration provider` (sic) *(verify)*.

## Autocommands

```lua
local group = vim.api.nvim_create_augroup("MyPlugin", { clear = true })

vim.api.nvim_create_autocmd("BufWritePost", {
  group = group,
  pattern = "*.lua",          -- string, list, or nil for all; cannot combine with buffer/buf
  desc = "myplugin: reload",
  callback = function(args)   -- args.buf, args.file, args.match, args.event, args.id, args.data
    -- return true to delete this autocmd after this run (verify)
  end,
})

-- Buffer-local: buffer = bufnr (all versions) or buf = bufnr (0.12+)
-- Clear the group:  vim.api.nvim_clear_autocmds({ group = group })
-- Fire your own:    vim.api.nvim_exec_autocmds("User", { pattern = "MyPluginDone", data = {} })
```

`once = true` also makes it one-shot.

## Keymaps

```lua
vim.keymap.set("n", "ga", accept, { buffer = bufnr, desc = "myplugin: accept" }) -- buf = on 0.12+
vim.keymap.del("n", "ga", { buffer = bufnr })
```

Plugins map `<Plug>(myplugin-action)` and let users bind keys, or use buffer-local maps in buffers they own. Never set global maps the user did not ask for.

## Async: vim.uv, vim.system, jobs

Which callbacks run in a fast event, where `vim.api` fails with `E5560`:

| Callback | Fast event? |
|---|---|
| `vim.uv` timer, socket, fs_event, fs_poll callbacks | yes *(verify)* |
| `vim.system(cmd, opts, on_exit)` `on_exit` | yes *(verify)* |
| `vim.fn.jobstart` `on_exit` / `on_stdout` | no *(verify on_exit)* |
| autocmd callbacks, user command callbacks, `vim.schedule` | no |

```lua
-- Timer: schedule_wrap moves the body onto the main loop (verify)
local timer = vim.uv.new_timer()
timer:start(delay_ms, repeat_ms, vim.schedule_wrap(function()
  -- vim.api is safe here
end))
-- teardown: timer:stop(); timer:close()

-- Subprocess
vim.system({ "git", "status", "--porcelain" }, { text = true, cwd = root }, function(res)
  -- fast event: res.code, res.stdout, res.stderr are fine, vim.api is not
  vim.schedule(function()
    render(res.stdout)
  end)
end)

-- Blocking form, for tests and :checkhealth only
local res = vim.system({ "echo", "hi" }, { text = true }):wait() -- res.code == 0, res.stdout == "hi\n" (verify)

-- File watcher
local w = vim.uv.new_fs_event()
w:start(path, {}, vim.schedule_wrap(function(err, filename, events)
  if err then return end
  -- events.change, events.rename
end))
-- teardown: w:stop(); w:close()

-- Stat (synchronous form, fine outside hot paths)
local stat = vim.uv.fs_stat(path) -- nil if missing; stat.type, stat.size, stat.mtime.sec, stat.mtime.nsec
```

`vim.in_fast_event()` returns true inside a fast callback *(verify)*.

## Notifications

```lua
vim.notify("myplugin: msg", vim.log.levels.WARN)       -- TRACE DEBUG INFO WARN ERROR
vim.notify_once("myplugin: msg", vim.log.levels.WARN)  -- true the first time, false after (verify)
```

## vim.cmd

Prefer the API. When there is none, use the table form for anything with a path or user text, because it escapes for you:

```lua
vim.cmd({ cmd = "edit", args = { path } })
vim.cmd({ cmd = "split", args = { path }, mods = { vertical = true } })
vim.cmd.write()
```

## Options

```lua
vim.o.shiftwidth = 4          -- like :set
vim.bo[bufnr].shiftwidth = 2  -- buffer-local
vim.wo[winid].number = true   -- window-local
vim.go.background = "dark"    -- global only
```

Plugins set options only on buffers and windows they own.

## Paths and vim.fn

```lua
vim.fs.joinpath(dir, "file.lua")
vim.fs.dirname(path); vim.fs.basename(path)
vim.fs.root(0, { ".git", "pom.xml" })    -- project root for the current buffer
vim.fn.fnamemodify(path, ":p")           -- absolute path
vim.fn.executable("git") == 1
vim.fn.exepath("git")                    -- full path or ""
vim.fn.has("nvim-0.12") == 1             -- version gate
vim.fn.stdpath("data")                   -- per-user plugin data dir
vim.fn.tempname()
```
