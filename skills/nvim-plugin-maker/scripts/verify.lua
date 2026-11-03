-- Checks the API claims in this skill's references against the running Neovim.
--
--   nvim --clean --headless -l scripts/verify.lua
--
-- Exit code 0 when every claim holds, 1 otherwise. CI runs it on the oldest
-- supported release, stable, and nightly, so a Neovim change that makes a
-- reference wrong fails the build instead of going stale quietly.
--
-- Each check names the reference file whose claim it proves. When a check
-- fails, fix the claim in that file first, then the check.

local passed, failed = 0, 0

local function out(line)
  io.stdout:write(line, "\n")
end

local function check(ref, name, fn)
  local ok, res = pcall(fn)
  if ok and res == true then
    passed = passed + 1
    out("ok    [" .. ref .. "] " .. name)
  else
    failed = failed + 1
    local why = ok and ("got " .. vim.inspect(res)) or tostring(res)
    out("FAIL  [" .. ref .. "] " .. name .. ": " .. why)
  end
end

local function has(version)
  return vim.fn.has("nvim-" .. version) == 1
end

local function accepts(f, ...)
  return (pcall(f, ...))
end

local function fails_with(needle, f, ...)
  local ok, err = pcall(f, ...)
  return (not ok) and tostring(err):find(needle, 1, true) ~= nil
end

-- Runs fn inside a raw libuv timer callback (a fast event) and returns what it
-- returned, or the error text.
local function in_uv_callback(fn)
  local result
  local timer = vim.uv.new_timer()
  timer:start(0, 0, function()
    local ok, res = pcall(fn)
    result = ok and { ok = true, value = res } or { ok = false, value = tostring(res) }
    timer:close()
  end)
  vim.wait(2000, function()
    return result ~= nil
  end, 10)
  return result
end

local v = vim.version()
out(("Neovim %d.%d.%d%s"):format(v.major, v.minor, v.patch, v.prerelease and "-dev" or ""))

local scratch = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(scratch, 0, -1, false, { "hello world", "second line" })

-- lua-version.md ------------------------------------------------------------

check("lua-version", "_VERSION is Lua 5.1", function()
  return _VERSION == "Lua 5.1"
end)

-- table.pack, table.unpack and rawlen exist only on LuaJIT builds with 5.2
-- compatibility (some distro packages); plugins must not rely on them. Only
-- the 5.3 functions are absent everywhere.
check("lua-version", "5.3 functions are absent", function()
  return string.pack == nil and math.type == nil and utf8 == nil
end)

check("lua-version", "global unpack exists", function()
  return type(unpack) == "function"
end)

check("lua-version", "require('bit') works", function()
  return type(require("bit").band) == "function"
end)

check("lua-version", "LuaJIT extras need require (table.new, string.buffer)", function()
  if not jit then
    return true
  end
  return table.new == nil
    and type(require("table.new")) == "function"
    and type(require("string.buffer").new) == "function"
end)

check("lua-version", "bundled modules exist", function()
  return vim.json ~= nil
    and vim.mpack ~= nil
    and vim.base64 ~= nil
    and vim.lpeg ~= nil
    and vim.regex ~= nil
    and vim.islist ~= nil
    and vim.fs.joinpath ~= nil
end)

check("lua-version", "text diff: vim.text.diff on 0.12+, vim.diff before", function()
  if has("0.12") then
    return type(vim.text.diff) == "function"
  end
  return type(vim.diff) == "function"
end)

check("lua-version", "vim.fs.ext exists exactly from 0.12", function()
  return (vim.fs.ext ~= nil) == has("0.12")
end)

check("lua-version", "vim.validate(name, value, type) form works", function()
  return accepts(vim.validate, "x", 1, "number") and not accepts(vim.validate, "x", 1, "string")
end)

check("api", "vim.fs.root finds a marker directory", function()
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir .. "/sub/deep", "p")
  vim.fn.writefile({}, dir .. "/marker.txt")
  local found = vim.fs.root(dir .. "/sub/deep", { "marker.txt" })
  vim.fn.delete(dir, "rf")
  return found ~= nil and vim.fs.normalize(found) == vim.fs.normalize(dir)
end)

-- api.md --------------------------------------------------------------------

check("api", "nvim_create_buf(false, true) is nofile + bufhidden=hide", function()
  local b = vim.api.nvim_create_buf(false, true)
  local ok = vim.bo[b].buftype == "nofile" and vim.bo[b].bufhidden == "hide" and not vim.bo[b].swapfile
  vim.api.nvim_buf_delete(b, { force = true })
  return ok
end)

check("api", "extmark with end_row/end_col/hl_group", function()
  local ns = vim.api.nvim_create_namespace("verify-extmark")
  local id = vim.api.nvim_buf_set_extmark(scratch, ns, 0, 0, { end_row = 0, end_col = 5, hl_group = "Search" })
  vim.api.nvim_buf_clear_namespace(scratch, ns, 0, -1)
  return type(id) == "number"
end)

check("api", "virt_text_pos = 'inline' accepted", function()
  local ns = vim.api.nvim_create_namespace("verify-inline")
  return accepts(vim.api.nvim_buf_set_extmark, scratch, ns, 0, 0, {
    virt_text = { { "x", "Comment" } },
    virt_text_pos = "inline",
  })
end)

check("api", "ephemeral extmark errors outside a decoration provider", function()
  local ns = vim.api.nvim_create_namespace("verify-ephemeral")
  return fails_with("decoration provider", vim.api.nvim_buf_set_extmark, scratch, ns, 0, 0, { ephemeral = true })
end)

check("api", "autocmd callback returning true deletes the autocmd", function()
  local fired = 0
  vim.api.nvim_create_autocmd("User", {
    pattern = "VerifyOneShot",
    callback = function()
      fired = fired + 1
      return true
    end,
  })
  vim.api.nvim_exec_autocmds("User", { pattern = "VerifyOneShot" })
  vim.api.nvim_exec_autocmds("User", { pattern = "VerifyOneShot" })
  return fired == 1
end)

check("api", "autocmd key 'buffer' accepted on every version", function()
  return accepts(vim.api.nvim_create_autocmd, "BufEnter", { buffer = scratch, callback = function() end })
end)

check("api", "autocmd key 'buf' accepted exactly from 0.12", function()
  local ok = accepts(vim.api.nvim_create_autocmd, "BufEnter", { buf = scratch, callback = function() end })
  return ok == has("0.12")
end)

check("api", "keymap opt 'buffer' accepted and stays buffer-local", function()
  vim.keymap.set("n", "<Plug>(verify-a)", "<Nop>", { buffer = scratch })
  local global = vim.fn.maparg("<Plug>(verify-a)", "n", false, true)
  local is_local = false
  for _, m in ipairs(vim.api.nvim_buf_get_keymap(scratch, "n")) do
    if m.lhs == "<Plug>(verify-a)" then
      is_local = true
    end
  end
  vim.keymap.del("n", "<Plug>(verify-a)", { buffer = scratch })
  return vim.tbl_isempty(global) and is_local
end)

check("api", "keymap opt 'buf' accepted exactly from 0.12", function()
  local ok = accepts(vim.keymap.set, "n", "<Plug>(verify-b)", "<Nop>", { buf = scratch })
  return ok == has("0.12")
end)

check("api", "notify_once returns true, then false", function()
  local shown = 0
  local real = vim.notify
  vim.notify = function()
    shown = shown + 1
  end
  local msg = "verify-notify-once-" .. tostring(vim.uv.hrtime())
  local ok, first, second = pcall(function()
    return vim.notify_once(msg, vim.log.levels.INFO), vim.notify_once(msg, vim.log.levels.INFO)
  end)
  vim.notify = real
  return ok and first == true and second == false and shown == 1
end)

check("api", "file URI: vim.uri.from_fname from 0.13, vim.uri_from_fname still present", function()
  if has("0.13") then
    return type(vim.uri.from_fname) == "function" and type(vim.uri_from_fname) == "function"
  end
  return type(vim.uri_from_fname) == "function"
end)

-- SKILL.md P0 and architecture.md --------------------------------------------

check("P0", "vim.api in a raw vim.uv callback fails with E5560", function()
  local r = in_uv_callback(function()
    return vim.api.nvim_buf_get_name(0)
  end)
  return r ~= nil and r.ok == false and r.value:find("E5560", 1, true) ~= nil
end)

check("P0", "vim.in_fast_event() is true inside a vim.uv callback", function()
  local r = in_uv_callback(function()
    return vim.in_fast_event()
  end)
  return r ~= nil and r.ok and r.value == true
end)

check("P0", "vim.schedule_wrap makes a vim.uv callback safe", function()
  local name
  local timer = vim.uv.new_timer()
  timer:start(
    0,
    0,
    vim.schedule_wrap(function()
      name = vim.api.nvim_buf_get_name(0)
      timer:close()
    end)
  )
  return vim.wait(2000, function()
    return name ~= nil
  end, 10)
end)

check("P0", "vim.system on_exit runs in a fast event", function()
  local result
  vim.system({ "true" }, {}, function()
    local ok, err = pcall(vim.api.nvim_buf_get_name, 0)
    result = ok and "api allowed" or tostring(err)
  end)
  vim.wait(5000, function()
    return result ~= nil
  end, 10)
  return result ~= nil and result:find("E5560", 1, true) ~= nil
end)

check("P0", "jobstart on_exit runs on the main loop", function()
  local result
  vim.fn.jobstart({ "true" }, {
    on_exit = function()
      result = pcall(vim.api.nvim_buf_get_name, 0)
    end,
  })
  vim.wait(5000, function()
    return result ~= nil
  end, 10)
  return result == true
end)

check("architecture", "timer:close() leaves the handle closing", function()
  local timer = vim.uv.new_timer()
  timer:start(10000, 0, function() end)
  timer:stop()
  timer:close()
  return timer:is_closing() == true
end)

check("P0", "vim.uv.random(16) returns 16 bytes", function()
  local bytes = vim.uv.random(16)
  return type(bytes) == "string" and #bytes == 16
end)

check("architecture", "vim.system(...):wait() returns code and text", function()
  local r = vim.system({ "echo", "hi" }, { text = true }):wait()
  return r.code == 0 and r.stdout == "hi\n"
end)

check("architecture", "vim.health reporters exist", function()
  return type(vim.health.start) == "function"
    and type(vim.health.ok) == "function"
    and type(vim.health.warn) == "function"
    and type(vim.health.error) == "function"
end)

check("architecture", "tbl_deep_extend('force') keeps untouched nested defaults", function()
  local merged = vim.tbl_deep_extend("force", { keymaps = { accept = "a", reject = "r" } }, { keymaps = { accept = "x" } })
  return merged.keymaps.accept == "x" and merged.keymaps.reject == "r"
end)

check("architecture", "write with mods.noautocmd skips BufWritePre", function()
  local path = vim.fn.tempname()
  local b = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(b, path)
  vim.api.nvim_buf_set_lines(b, 0, -1, false, { "x" })
  local fired = 0
  local id = vim.api.nvim_create_autocmd("BufWritePre", {
    callback = function()
      fired = fired + 1
    end,
  })
  vim.api.nvim_buf_call(b, function()
    vim.cmd({ cmd = "write", mods = { noautocmd = true, silent = true }, bang = true })
  end)
  local written = vim.fn.readfile(path)[1] == "x"
  vim.api.nvim_buf_call(b, function()
    vim.cmd({ cmd = "write", mods = { silent = true }, bang = true })
  end)
  vim.api.nvim_del_autocmd(id)
  vim.api.nvim_buf_delete(b, { force = true })
  vim.fn.delete(path)
  return written and fired == 1
end)

check("architecture", "tmp + fs_rename atomic write replaces the file", function()
  local path = vim.fn.tempname()
  vim.fn.writefile({ "old" }, path)
  local tmp = path .. ".tmp"
  local fd = assert(vim.uv.fs_open(tmp, "w", 420))
  assert(vim.uv.fs_write(fd, "new\n", 0))
  vim.uv.fs_close(fd)
  assert(vim.uv.fs_rename(tmp, path))
  local ok = vim.fn.readfile(path)[1] == "new" and vim.uv.fs_stat(tmp) == nil
  vim.fn.delete(path)
  return ok
end)

check("architecture", "xpcall(fn, debug.traceback) returns false plus a traceback", function()
  local ok, err = xpcall(function()
    error("boom")
  end, debug.traceback)
  return ok == false and err:find("boom", 1, true) ~= nil and err:find("stack traceback", 1, true) ~= nil
end)

-- testing.md ----------------------------------------------------------------

check("testing", "vim.wait returns true when the predicate holds", function()
  local done = false
  vim.defer_fn(function()
    done = true
  end, 20)
  return vim.wait(2000, function()
    return done
  end, 10) == true
end)

check("testing", "vim.wait returns false on timeout", function()
  return vim.wait(30, function()
    return false
  end, 10) == false
end)

check("testing", "clearing package.loaded re-runs the module", function()
  local loads = 0
  package.preload["verify_fresh_module"] = function()
    loads = loads + 1
    return {}
  end
  require("verify_fresh_module")
  require("verify_fresh_module")
  package.loaded["verify_fresh_module"] = nil
  require("verify_fresh_module")
  return loads == 2
end)

out(("%d passed, %d failed"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
