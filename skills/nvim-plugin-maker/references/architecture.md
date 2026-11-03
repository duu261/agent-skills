# Plugin architecture patterns

Working shapes for the plugin surface. Adapt names, keep the shapes. Buffer-local keys below use `buffer =`, which works on every supported version; on a 0.12+ minimum you may write `buf =` (see the rename table in `api.md`).

## Config: defaults, merge, get()

```lua
-- lua/myplugin/config.lua
local M = {}

local defaults = {
  width = 80,
  keymaps = { accept = "<leader>a" },
}

local options = vim.deepcopy(defaults)

function M.setup(opts)
  options = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
end

function M.get()
  return options
end

return M
```

`tbl_deep_extend("force", ...)` lets a user override one nested key without restating the table *(verify)*. Starting `options` from the defaults means every path works when `setup()` is never called.

Validate loudly, fail soft: on a bad value, `vim.notify` once naming the key and fall back to the default. Never error out of `setup()`; that breaks the user's whole config.

## plugin/myplugin.lua: registration only

```lua
if vim.g.loaded_myplugin then
  return
end
vim.g.loaded_myplugin = true

vim.api.nvim_create_user_command("MyPlugin", function(cmd)
  require("myplugin").run(cmd.fargs)
end, { nargs = "*", desc = "Run myplugin" })
```

The `require()` inside the callback is the lazy loading: nothing is parsed until the command runs.

## Command boundary: the never-crash wrapper

Every entry point the user can trigger goes through one guard, so a bug becomes one notification and a log line, not a stack trace.

```lua
-- lua/myplugin/guard.lua
local M = {}

function M.wrap(name, fn)
  return function(...)
    local ok, err = xpcall(fn, debug.traceback, ...)
    if not ok then
      require("myplugin.log").log("ERROR", name .. ": " .. err)
      vim.notify_once("myplugin: " .. name .. " failed, see :MyPluginLog", vim.log.levels.ERROR)
    end
  end
end

return M
```

Use it for user commands, autocmd callbacks, keymaps, and anything scheduled from async code.

## Health check

```lua
-- lua/myplugin/health.lua   (:checkhealth myplugin)
local M = {}

function M.check()
  vim.health.start("myplugin")

  if vim.fn.has("nvim-0.11") == 1 then -- your declared minimum
    vim.health.ok("Neovim >= 0.11")
  else
    vim.health.error("Neovim >= 0.11 required")
  end

  if vim.fn.executable("some-cli") == 1 then
    vim.health.ok("some-cli: " .. vim.fn.exepath("some-cli"))
  else
    vim.health.warn("some-cli not found", { "Install it from https://..." })
  end
end

return M
```

Check every external assumption: binaries, versions, optional integrations. It is the first thing to ask a bug reporter for.

## Logging: a ring buffer, not :messages

```lua
-- lua/myplugin/log.lua
local M = {}
local lines, max = {}, 500

function M.log(level, msg)
  lines[#lines + 1] = string.format("[%s] %s %s", level, os.date("%H:%M:%S"), msg)
  if #lines > max then
    table.remove(lines, 1)
  end
end

function M.show() -- :MyPluginLog
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.cmd.split()
  vim.api.nvim_win_set_buf(0, buf)
end

return M
```

`M.log` only appends to a Lua table, so it is safe to call from a fast event. `M.show` touches buffers, so call it from a command.

## Async: the two rules

1. Catch errors in every callback Neovim or libuv calls.
2. Do not touch the editor from a fast event; schedule it.

```lua
local uv = vim.uv
local log = require("myplugin.log")

local server = uv.new_tcp()
server:bind("127.0.0.1", 0) -- loopback only; port 0 lets the OS pick
server:listen(16, function(err)
  local ok, perr = pcall(function()
    if err then
      return log.log("ERROR", err)
    end
    local client = uv.new_tcp()
    server:accept(client)
    client:read_start(function(rerr, chunk)
      local rok, rperr = pcall(function()
        if rerr or not chunk then
          client:close()
          return
        end
        vim.schedule(function() -- rule 2
          handle_data(chunk)
        end)
      end)
      if not rok then
        log.log("ERROR", rperr)
      end
    end)
  end)
  if not ok then
    log.log("ERROR", perr)
  end
end)
```

Teardown: keep every handle (server, clients, timers, watchers) reachable from one module table and close them all in `stop()`. Tests, `:checkhealth`, and plugin reload depend on `stop()` releasing everything.

## Subprocesses

```lua
vim.system({ "mvn", "-q", "dependency:list" }, { text = true, cwd = root }, function(res)
  -- fast event (verify): no vim.api here
  vim.schedule(function()
    if res.code ~= 0 then
      vim.notify_once("myplugin: mvn failed, see :MyPluginLog", vim.log.levels.WARN)
      return log.log("ERROR", res.stderr)
    end
    render(res.stdout)
  end)
end)
```

Pass the command as a list, never a shell string, so paths with spaces and user input cannot inject flags or commands.

## File I/O

Small files, outside hot paths: `vim.fn.readfile` / `vim.fn.writefile` are simple and run on the main loop.

Atomic write, so no reader sees a half-written file:

```lua
local function write_atomic(path, content)
  local tmp = path .. ".tmp"
  local fd = assert(vim.uv.fs_open(tmp, "w", 420)) -- 420 = 0644
  local ok, err = pcall(function()
    assert(vim.uv.fs_write(fd, content, 0))
  end)
  vim.uv.fs_close(fd)
  if not ok then
    vim.uv.fs_unlink(tmp)
    error(err)
  end
  assert(vim.uv.fs_rename(tmp, path)) -- atomic on the same filesystem
end
```

Modes are decimal numbers: `420` = 0644, `384` = 0600, `493` = 0755.

If the file may be open in a buffer, write through the buffer instead (`nvim_buf_set_lines` then `:write`), or the user gets a "file changed on disk" prompt. When writing a file must not trigger the user's `BufWritePre` formatters, wrap the write: `vim.cmd({ cmd = "write", mods = { noautocmd = true } })`.

## Debounce with a uv timer

```lua
local timer = vim.uv.new_timer()

vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
  group = group,
  callback = function()
    timer:stop()
    timer:start(150, 0, vim.schedule_wrap(function()
      refresh() -- runs once after typing pauses
    end))
  end,
})
-- teardown: timer:stop(); timer:close()
```

`stop()` then `start()` resets the window on each event.

## Network safety

- Cap the read buffer for any peer you do not control, or a slow or hostile peer exhausts memory:

```lua
local MAX = 256 * 1024
local pending = ""
client:read_start(function(err, chunk)
  pcall(function()
    if err or not chunk then return client:close() end
    pending = pending .. chunk
    if #pending > MAX then client:close() end
  end)
end)
```

- Check `client:is_closing()` before writing.
- `ECONNRESET` on read is a normal disconnect. Close quietly; do not notify.
- Tokens: `vim.uv.random(16)` *(verify)*, never `math.random`. Never log them.

## Buffer-local UI: one namespace, one teardown

```lua
local ns = vim.api.nvim_create_namespace("myplugin")

-- render
vim.api.nvim_buf_set_extmark(buf, ns, row, 0, { virt_text = { { "hint", "Comment" } } })
vim.keymap.set("n", "ga", accept, { buffer = buf, desc = "myplugin: accept" })

-- teardown
vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
pcall(vim.keymap.del, "n", "ga", { buffer = buf }) -- the buffer may already be gone
```
