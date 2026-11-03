# Releasing a plugin

## README

Readers decide in about ten seconds. In order:

1. One-sentence pitch, plus a screenshot or GIF if the plugin is visual.
2. **Requirements:** minimum Neovim version and external binaries.
3. **Install:** lazy.nvim first, since most users run it:

```lua
{
  "user/myplugin.nvim",
  opts = {}, -- lazy.nvim calls require("myplugin").setup(opts)
}
```

4. **Configuration:** the full defaults table, copy-pasteable. Incomplete defaults generate issues.
5. **Usage:** commands, `<Plug>` mappings, one realistic workflow.
6. "Run `:checkhealth myplugin` if something is off."

## Vimdoc (doc/myplugin.txt)

`:help myplugin` must work.

```
*myplugin.txt*  One-line description

==============================================================================
CONTENTS                                                    *myplugin-contents*

  1. Introduction ......... |myplugin-introduction|
  2. Configuration ........ |myplugin-configuration|
  3. Commands ............. |myplugin-commands|

==============================================================================
1. INTRODUCTION                                         *myplugin-introduction*
...

 vim:tw=78:ts=8:noet:ft=help:norl:
```

Tags are `*myplugin-topic*`, right-aligned; links are `|myplugin-topic|`; the modeline at the bottom makes it render as help. Keep vimdoc and README in sync. For doc-heavy plugins, generate vimdoc from the README with [panvimdoc](https://github.com/kdheepak/panvimdoc) in CI.

Check tags locally: `nvim --headless -c 'helptags doc/' -c q`. Plugin managers generate `doc/tags` on install, so add it to `.gitignore`.

## CI (GitHub Actions)

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        nvim: [v0.11.6, stable, nightly] # first entry: your declared minimum
    steps:
      - uses: actions/checkout@v7
      - uses: rhysd/action-setup-vim@v1
        with:
          neovim: true
          version: ${{ matrix.nvim }}
      - run: make test

  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: JohnnyMorganz/stylua-action@v5
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          version: latest
          args: --check lua/ plugin/ tests/
      - uses: lunarmodules/luacheck@v1
        with:
          args: lua/ plugin/ tests/
```

Action versions were current when this file was last checked; Dependabot keeps them moving. Test the declared minimum, stable, and nightly: the minimum catches a new API used by accident, and nightly catches deprecations before users hit them.

## Versioning

- Semver tags (`v0.1.0`). lazy.nvim's `version = "*"` resolves to the latest tag; an untagged repo forces everyone onto the default branch.
- Keep a `CHANGELOG.md`, or use conventional commits with release-please.
- Breaking config change: keep reading the old key for one release and `vim.notify_once` a deprecation naming the new one.

## Before tagging

- `make test` green on the minimum version, stable, and nightly.
- `stylua --check` and `luacheck` clean.
- `:checkhealth myplugin` accurate on a clean config.
- The README install snippet works in an empty config.
- `:help myplugin` renders and its links resolve.
- No debug prints or TODOs in user-visible paths.
