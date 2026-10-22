# behavior-repro-fixture

[English](README.md) | Tiếng Việt

> Bản dịch có thể chậm hơn bản tiếng Anh. Nếu hai bản khác nhau, bản tiếng Anh là chuẩn.

**Dành cho những ai muốn kiểm tra "model từ chối X" mà không để chính bài test gây ra lời từ chối.**

Hỏi lại trong cùng phiên không chứng minh được gì: phiên đó đã biết lời phàn nàn, và chính system prompt hoặc bộ nhớ của nó có thể là nguyên nhân. Agent được nhờ tái hiện một hành vi thường làm hỏng bài test. Nó tự chạy probe, để đáp án mong đợi ở chỗ model đọc được, hoặc dựng một runtime nhiều agent giả che mất đúng thứ bạn muốn thấy.

Skill này dựng một fixture riêng nhỏ gọn: một workspace dùng xong bỏ, một đoạn hội thoại nhiều lượt dán được ngay và không bao giờ nói "đây là bài test", cùng một bảng chấm điểm tách lần chặn do harness ép ra khỏi lần chặn do model tự nghĩ ra. Nó cô lập phiên probe khỏi các quy tắc sẵn có của môi trường chạy agent, bộ nhớ và cơ chế gợi nhớ, và giữ đáp án mong đợi ngoài tầm với của model. Bạn chạy probe trong một phiên mới và tự chấm. Có thêm một tài liệu tham khảo về eval A/B cho skill: các nhánh, yếu tố gây nhiễu, và các chỉ số dùng được trên nhiều harness.

## Nguồn gốc

Do [review skill chạy nền](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills#when-the-agent-creates-skills) của Hermes Agent tạo ra, sau một phiên chạy `grok-4.6` về một báo cáo model từ chối quá mức việc copy một file biến môi trường không chứa bí mật. Được tinh chỉnh qua các phiên sau chạy `claude-opus-5-5`, nơi các fixture như vậy được dựng và chạy, và bổ sung phần thiết kế A/B cho skill hai ngày sau đó. Bản public bỏ các chi tiết riêng của harness về profile, bộ nhớ và kho phiên.

## Cài đặt

```bash
npx skills add duu261/agent-skills --skill behavior-repro-fixture
# Hermes Agent
hermes skills install duu261/agent-skills/skills/behavior-repro-fixture
```

Hoặc copy `skills/behavior-repro-fixture/` vào thư mục skill của harness.

## Giấy phép

MIT
