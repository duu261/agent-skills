# nvim-plugin-maker

[English](README.md) | Tiếng Việt

> Bản dịch có thể chậm hơn bản tiếng Anh. Nếu hai bản khác nhau, bản tiếng Anh là chuẩn.

**Dành cho những ai làm plugin Neovim với một agent cứ viết API của năm ngoái.**

Model học Neovim từ code viết trước ngày cutoff của nó. Neovim thì liên tục đổi tên: 0.12 đổi key `buffer` thành `buf` và `vim.diff` thành `vim.text.diff`, còn 0.13 chuyển các hàm `vim.uri_*` vào `vim.uri`. Agent còn hay gọi `vim.api` bên trong callback của `vim.uv`, bị lỗi `E5560`, và để timer mở đến mức `make test` treo.

Skill này cho agent một layout plugin, một bộ test plenary chạy headless, các quy tắc để plugin không làm crash hay treo editor, và một bản tham chiếu API. Mỗi khẳng định về API đều ghi rõ phiên bản Neovim mà nó đúng. `scripts/verify.lua` chạy các khẳng định đó trên Neovim thật (37 phép kiểm tra), và CI chạy nó hằng tuần trên 0.11.6, stable và nightly. Khi Neovim thay đổi, build sẽ fail thay vì tài liệu âm thầm sai.

## Nguồn gốc

Người duy trì dựng skill này trong Claude Code và tinh chỉnh bằng các eval của skill-creator ở đó: năm task plugin gồm scaffold, theo dõi file bất đồng bộ, chuẩn bị release, extmark kèm keymap theo buffer, và luồng đổi tên bằng `vim.ui.input`. Sau đó `gpt-5.6-sol` dùng nó trong Codex CLI qua 17 session để làm [duke.nvim](https://github.com/duu261/duke.nvim), một công cụ quản lý project Maven và Gradle cho Neovim. [Project story](https://github.com/duu261/duke.nvim/blob/main/PROJECT-STORY.md) của duke.nvim mô tả quy trình này.

Người duy trì và `claude-opus-5-5` làm mới skill vào tháng 11 năm 2026. Hai bên chạy mọi khẳng định API trên Neovim 0.11.6, 0.12.6 và 0.13-dev, rồi sửa những chỗ đã lỗi thời:

- đổi tên `buffer` thành `buf`, và đổi tên `vim.diff`
- extmark `ephemeral`, vốn báo lỗi khi dùng ngoài decoration provider
- một quy tắc test cấm `--noplugin`, trong khi bộ test đang chạy tốt của duke.nvim lại dùng nó
- phiên bản Neovim bị ghim cứng, và phiên bản các action trong CI

Hai bên cũng cắt bớt phần thủ tục mà các session thật cho thấy là lãng phí: bắt viết test trước cho mọi lần sửa, đọc hết mọi file tham chiếu ở đầu mỗi session, và một phần mô tả rộng tới mức skill bị load cả khi sửa config cá nhân.

Không có lần chạy đối chứng có và không có skill nào đứng sau nó. Đây là tài liệu tham chiếu, không phải một tuyên bố benchmark.

## Cài đặt

```bash
npx skills add duu261/agent-skills --skill nvim-plugin-maker
# Hermes Agent
hermes skills install duu261/agent-skills/skills/nvim-plugin-maker
```

Hoặc copy `skills/nvim-plugin-maker/` vào thư mục skill của harness.

Kiểm tra tài liệu tham chiếu trên Neovim của bạn:

```bash
nvim --clean --headless -l skills/nvim-plugin-maker/scripts/verify.lua
```

## Giấy phép

MIT
