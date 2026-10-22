# production-ops-discipline

[English](README.md) | Tiếng Việt

> Bản dịch có thể chậm hơn bản tiếng Anh. Nếu hai bản khác nhau, bản tiếng Anh là chuẩn.

**Dành cho người vận hành cho phép coding agent làm việc trên server thật.**

**Do `claude-opus-5-5` viết, cho `claude-opus-5-5`.** Qua khoảng 12.000 lần gọi tool trên một server production thật, các thói quen hỏng việc của nó lộ ra trong log và qua những lần người vận hành sửa lại. Nó viết skill này để sửa chúng, và tiếp tục viết lại mỗi khi phiên làm việc mới lộ ra lỗ hổng mới. Số liệu trước/sau do script đếm từ log phiên làm việc, không phải model tự chấm. `gpt-5.6-sol` soạn bản public đầu tiên, các reviewer `gpt-5.6-sol` và `grok-4.6` kiểm tra; phần còn lại đều do `claude-opus-5-5`.

Agent nhanh tay thường hỏng việc trên production theo một kiểu dễ đoán: gộp đọc, sửa và restart vào một lệnh, mở `.env` để tìm một setting, và coi câu "want me to...?" của chính nó như một lời đồng ý. Nếu bạn quen dùng các model GPT, bạn sẽ thấy thiếu vài thứ: GPT hỏi trước khi thay đổi, không để secret lọt ra output, mỗi lần chỉ làm một thay đổi, và xin ý kiến thứ hai trước khi deploy.

Skill này đóng gói sự kỹ tính đó thành một [Agent Skill](https://agentskills.io): một tư duy cộng với các mặc định an toàn. Chặt chẽ khi thay đổi, nhanh khi đọc. Skill cũng liệt kê những thói quen của model quá kỹ tính cần tránh, để bạn có kỷ luật mà không bị thủ tục rườm rà.

Skill tên là `production-ops-discipline`. Skill này ra mắt lần đầu ở `duu261/claude-wannabe-gpt`, repo đó giờ trỏ về đây. Đặc tả Agent Skills không cho dùng chữ "claude" trong tên skill, nên chỉ tên repo cũ mang câu đùa này.

## Skill dạy gì

- **Phân loại tin nhắn mới nhất trước khi làm.** Một câu hỏi không phải là sự đồng ý. Lời đề nghị của chính bạn không phải là lệnh "go".
- **Viết một dòng mô tả thay đổi (change line)** trước mỗi thay đổi: mục tiêu, thay đổi cụ thể, ảnh hưởng, cách rollback.
- **Mỗi lần gọi chỉ một thay đổi**, có `set -euo pipefail`, một bản backup và một bước kiểm tra.
- **Giữ vệ sinh secret:** không bao giờ đọc `.env` hay file credential; chỉ in ra những trường được phép (allowlist) thay vì lọc bỏ những gì đoán là nhạy cảm.
- **Review độc lập theo danh sách trigger cố định** (config production, release, migration, xóa dữ liệu), không phải mỗi tin nhắn.
- **Bị chặn tức là đã có câu trả lời:** dừng lại và báo cáo, không bao giờ đi đường vòng qua guardrail.
- **Đừng sửa quá tay:** không xin phép để đọc, không hỏi lại lần hai, không viết README nhỏ bằng giọng văn SLA.

Được xây dựng và tinh chỉnh trên `claude-opus-5-5`. Các mặc định cơ học (backup, mỗi lần gọi một thay đổi, vệ sinh secret, trigger review cố định) là những pattern đơn giản, có lẽ dùng được với model khác, nhưng chưa được kiểm chứng. Các phần cần phán đoán giả định một model mạnh; với model yếu hơn, hãy dùng thêm deny rule hoặc hook của harness.

## Cài đặt

### Dễ nhất: nhờ agent cài giúp

Dán đoạn này vào Claude Code, Codex, Hermes Agent hoặc agent lập trình nào hỗ trợ Agent Skills:

```text
Install the Agent Skill "production-ops-discipline" from https://github.com/duu261/agent-skills.
1. Clone the repo into a temporary directory.
2. Copy the folder skills/production-ops-discipline into the user-level skills directory of the agent you are running in (Claude Code: ~/.claude/skills/, Codex: ~/.agents/skills/, Hermes Agent: ~/.hermes/skills/). If you are not sure which one applies, ask me.
3. If a folder with that name already exists, stop and ask me before replacing it.
4. Do not install the optional delegation hook unless I ask for it.
5. Confirm the installed path and that SKILL.md is there, then delete the temporary clone.
```

Giữ nguyên prompt tiếng Anh để agent đọc đúng; agent vẫn trả lời bạn bằng ngôn ngữ bạn đang dùng.

### Cài thủ công

Copy `skills/production-ops-discipline/` vào thư mục skill của harness bạn dùng:

| Harness | Vị trí |
|---|---|
| Claude Code | `~/.claude/skills/` hoặc `.claude/skills/` |
| Codex | `~/.agents/skills/` hoặc `<repo>/.agents/skills/` |
| Hermes Agent | `~/.hermes/skills/` |

```bash
git clone https://github.com/duu261/agent-skills
cp -r agent-skills/skills/production-ops-discipline ~/.claude/skills/
```

Skill tự load khi task đụng tới production. Trong Claude Code, gọi trực tiếp bằng `/production-ops-discipline`.

Về hook delegation cho `claude-opus-5-5` (vì sao model cần một lời nhắc phía người dùng ở mỗi lượt mới chịu dùng subagent) và bảng ánh xạ tool theo từng harness, xem [references/harnesses.md](references/harnesses.md) (tiếng Anh).

## Số liệu

Ghi chép thực tế từ một người vận hành chạy `claude-opus-5-5` trên một server production, khoảng 12.000 lần gọi tool. Đây là số liệu quan sát, không phải thử nghiệm có đối chứng.

| % số lần gọi shell | `claude-opus-5-5` trước | `claude-opus-5-5` sau | `gpt-5.6-sol` | `gpt-6-astra` |
|---|---|---|---|---|
| Chỉ định thư mục làm việc rõ ràng | 60,8 | 99,4 | 81,4 | 94,2 |
| `cd` gộp vào lệnh | 35,5 | 0,6 | 2,4 | 0,7 |
| Đọc file bằng shell (`cat`, `sed -n`, `head`, `tail`) | 11,7 | 5,9 | 0,7 | 0,5 |
| `grep` đệ quy | 6,0 | 0,1 | 0,3 | 0,6 |
| `sed -i` sửa tại chỗ | 2,6 | 0,2 | 0,1 | 0,0 |

Sau khi có skill, `claude-opus-5-5` bằng hoặc hơn cả hai model GPT ở thư mục làm việc, `cd` và `grep` đệ quy. Đọc file bằng shell vẫn là khoảng cách rõ nhất, còn `sed -i` thì gần bằng nhưng vẫn cao hơn cả hai. Các cột GPT lấy trên cùng server trước khi có skill, khác giai đoạn và loại task, nên chỉ nên xem là định hướng.

"Sau" nghĩa là skill cộng với các quy tắc thường trực tương ứng được thêm vào cùng tối hôm đó, nên bảng này không thể quy công cho riêng skill. Việc giao review cho subagent gần như không đổi cho tới khi thêm một hook nhắc một dòng ở mỗi lượt. Các yếu tố gây nhiễu và số liệu đầy đủ nằm ở [references/evidence.md](references/evidence.md) (tiếng Anh). Một thử nghiệm A/B có đối chứng trong Claude Code đang được lên kế hoạch.

## Giấy phép

MIT
