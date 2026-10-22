# agent-skills

[English](README.md) | Tiếng Việt

> Bản tiếng Anh là bản chuẩn. Nếu hai bản lệch nhau, theo bản tiếng Anh.

Toàn bộ là skill mình dùng hằng ngày, chiết ra từ các session chạy model frontier: `claude-opus-5-5`, `gpt-6-astra`, `gpt-5.6-sol`, `grok-4.6` và `grok-4.7`. Cách làm đơn giản: model ngu chỗ nào thì ghi lại vào skill để sửa, task nào lặp lại thì agent tự sinh skill cho nó. [Hermes Agent](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills) tự làm cả hai việc này, qua [vòng tự cải thiện](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills#when-the-agent-creates-skills) và [`/learn`](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills#learning-a-skill-from-sources-learn).

Sau đó mình check lại từng cái bằng tay, bỏ hết những gì chỉ đúng với setup của mình, rồi tách ra phần mindset (vì sao) và phần step by step (làm gì), để mấy model yếu hơn cũng áp dụng được. Chạy được trên mọi harness đọc định dạng [Agent Skills](https://agentskills.io).

## Skills

**[production-ops-discipline](skills/production-ops-discipline/)**: cho agent làm việc trên server thật. Nó thôi gộp sửa với restart vào một lệnh, thôi mò `.env`, và thôi coi câu "want me to...?" của chính nó là được phép. Nó chỉ hỏi trước khi sửa, đọc với chạy test thì không hỏi. Mình làm riêng cho `claude-opus-5-5` để nó cẩn thận như `gpt-5.6-sol` và `gpt-6-astra`. Qua khoảng 12.000 tool call, tỉ lệ `cd` gộp vào lệnh giảm từ 35,5% xuống 0,6% (ghi chép thực tế, không phải thử nghiệm có đối chứng; số liệu trong README của skill).

**[pre-build-discovery](skills/pre-build-discovery/)**: dùng trước khi vibe một idea hay feat. Hỏi nó "có đáng làm không, có ai làm sẵn chưa" thì nó đi soi các dự án có sẵn và source thật, rồi phán làm, chờ, hoặc bỏ. Nó không viết code, không lên plan. Non-tech cũng dùng ngon.

**[claim-check](skills/claim-check/)**: đọc một hai dòng thấy con model xàm thì nói thẳng "sai rồi, show log đi". Nó không cãi cố, cũng không xuôi theo, mà quay lại kiểm bằng chứng thật rồi báo đúng một kết quả: Confirmed, Corrected hoặc Blocked. Mẹo: tự gọi skill này từ đầu session thì nó thành công tắc "try harder", model phải làm nhiều hơn để mình đọc ít xàm hơn. Trong một cặp A/B cùng model `deepseek-v4-flash`, session có skill đọc source và trả lời đúng; session không có skill đọc README rồi trả lời sai. Đã được load khoảng 140 lần.

**[repo-state-authority](skills/repo-state-authority/)**: cho anh em lười check Git. Nó không phán một branch đã merge là "mất code" chỉ vì diff to, không tin file trạng thái hơn Git, và chỉ xóa branch sau khi đã lưu SHA. Đã dùng khoảng 240 lần.

Mỗi thư mục skill có README riêng kèm bằng chứng.

## Cài đặt

Dễ nhất: quăng link repo này cho app agent anh em đang dùng, kêu nó tự cài hết, hoặc chỉ cài skill nào anh em muốn.

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
