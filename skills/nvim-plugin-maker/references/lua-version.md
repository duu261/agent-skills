# Neovim Lua runtime

## Lua 5.1 is the interface

Neovim's rule (`:help lua-compat`): plugins target Lua 5.1. Later Lua versions are different dialects and are not supported, and that includes extensions such as `goto` that LuaJIT happens to accept. `_VERSION` is `"Lua 5.1"` *(verify)*.

Most builds run LuaJIT 2.1, but `:help lua-luajit` says its extras "cannot be assumed to be available". Check the `jit` global before using them.

## Do not rely on these

| Feature | Status |
|---|---|
| `goto` / labels | LuaJIT parses it, but Neovim's policy excludes it. Do not use. |
| `table.pack`, `table.unpack`, `rawlen` | Missing on standard builds. Some distro LuaJIT packages enable 5.2 compatibility and expose them, so a test can pass on your machine and fail for users. Use `select("#", ...)` and the global `unpack`. |
| `string.pack`, `math.type`, `utf8` | 5.3. Missing everywhere *(verify)*. |
| `_ENV` | Not available. Use module tables. |
| `__pairs`, `__ipairs` metamethods | Not honored by standard Lua 5.1. |
| `#t` on tables with holes | Undefined. Use `vim.tbl_count(t)` or check `vim.islist(t)`. |

`math.log(x, base)` works on LuaJIT (it returns `3` for `(8, 2)`), but plain Lua 5.1 ignores the base. Write `math.log(x) / math.log(base)` to be safe.

## LuaJIT extras (check `if jit then`)

| Feature | Access |
|---|---|
| FFI | `require("ffi")` |
| Preallocated tables | `require("table.new")(narr, nrec)`, not `table.new` *(verify)* |
| Fast string building | `require("string.buffer")` *(verify)* |
| Bit operations | `require("bit")`, always available, Neovim bundles a fallback *(verify)* |

## Bundled with Neovim

| Module | Use |
|---|---|
| `vim.uv` | libuv: timers, sockets, fs, processes |
| `vim.json` | JSON encode and decode |
| `vim.mpack` | MessagePack |
| `vim.base64` | Base64 |
| `vim.lpeg`, `vim.re` | Parsing |
| `vim.regex` | Vim regex from Lua |
| `vim.text.diff` (0.12+), `vim.diff` (before) | Text diff *(verify)* |
| `vim.treesitter` | Tree-sitter |

`scripts/verify.lua` checks that `vim.json`, `vim.mpack`, `vim.base64`, `vim.lpeg`, `vim.regex` and the right diff function exist.

## The `vim` namespace

| Module | For |
|---|---|
| `vim.api` | `nvim_*` functions |
| `vim.fn` | Vimscript functions |
| `vim.fs` | Paths and directory search (`joinpath`, `root`, `find`, `dir`) |
| `vim.system` | Subprocesses; prefer it over `io.popen` |
| `vim.iter` | Iterator chains |
| `vim.version` | Parse and compare versions |
| `vim.ui` | `input`, `select`, `open` |
| `vim.health` | `:checkhealth` reporters |
| `vim.keymap` | Mappings |

## Everyday functions

```lua
vim.inspect(obj, { depth = 2 })          -- pretty-print to a string; never write your own
vim.print(...)                           -- inspect and echo
vim.schedule(fn) / vim.schedule_wrap(fn) -- run on the main loop
vim.defer_fn(fn, ms)                     -- one-shot timer on the main loop
vim.wait(ms, predicate, interval)        -- pump the loop until predicate or timeout
vim.deepcopy(t)
vim.tbl_deep_extend("force", a, b)       -- recursive merge, b wins (verify)
vim.tbl_isempty(t), vim.tbl_count(t)
vim.startswith(s, p), vim.endswith(s, p)
vim.split(s, sep, { plain = true }), vim.trim(s)
vim.validate("name", value, "string")    -- 0.11+ form (verify)
```

`:= expr` on the command line inspects a value without writing a `vim.print`.
