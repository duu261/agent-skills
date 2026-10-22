# agent-skills

[English](README.md) | Tiếng Việt

> Bản dịch có thể chậm hơn bản tiếng Anh. Nếu hai bản khác nhau, bản tiếng Anh là chuẩn.

Các agent skill từ công việc thật, không phải task đồ chơi.

Mỗi skill bắt đầu từ các phiên làm việc hằng ngày với [Hermes Agent](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills) trong công việc vận hành thật. Hermes [tự viết skill](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills#when-the-agent-creates-skills) khi nó tìm ra một quy trình không đơn giản, rồi tinh chỉnh dần qua vòng tự cải thiện khi các phiên sau gặp tình huống mới, hoặc dựng skill từ một ý tưởng bằng [`/learn`](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills#learning-a-skill-from-sources-learn).

Không có gì ở đây là output AI để nguyên. Trước khi một skill được đưa vào, con người đánh giá, viết lại, bỏ hết những gì chỉ đúng với một setup, và làm cho nó dùng được với mọi harness đọc định dạng [Agent Skills](https://agentskills.io).

## Skills

| Skill | Khắc phục điều gì |
|---|---|
| [production-ops-discipline](skills/production-ops-discipline/) | Agent nhanh tay trên server thật: gộp sửa và restart, nhìn trộm secret, coi câu "want me to...?" của chính nó là lời đồng ý. Do `claude-opus-5-5` viết, cho `claude-opus-5-5`. |
| [pre-build-discovery](skills/pre-build-discovery/) | Agent trả lời câu "có đáng làm không?" bằng cách làm luôn. Kết thúc bằng làm / chờ / không làm và một phép kiểm tra có thể lật kết luận. |
| [claim-check](skills/claim-check/) | Agent bảo vệ một khẳng định bị nghi ngờ bằng cách nói to hơn, hoặc xuôi theo mà không kiểm tra. Chạy một phép kiểm tra phân định và báo Confirmed, Corrected hoặc Blocked. |

Mỗi thư mục skill có README riêng với chi tiết và bằng chứng.

## Cài đặt

Bằng [skills CLI](https://github.com/vercel-labs/skills) (Claude Code, Codex và các agent khác):

```bash
npx skills add duu261/agent-skills --skill production-ops-discipline
# hoặc mọi skill
npx skills add duu261/agent-skills
```

Bằng [Hermes Agent](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills):

```bash
hermes skills install duu261/agent-skills/skills/<name>
# hoặc thêm cả repo làm tap
hermes skills tap add duu261/agent-skills
```

Bằng plugin của [Claude Code](https://code.claude.com/docs/en/plugins/marketplace-reference), mỗi skill là một plugin:

```text
/plugin marketplace add duu261/agent-skills
/plugin install claim-check@duu261
```

Mỗi agent chỉ chọn một cách: dùng cả plugin lẫn skills CLI sẽ cài cùng một skill hai lần.

Thủ công: copy `skills/<name>/` vào thư mục skill của harness (Claude Code `~/.claude/skills/`, Codex `~/.agents/skills/`, Hermes Agent `~/.hermes/skills/`).

## Giấy phép

MIT
