# claim-check

[English](README.md) | Tiếng Việt

> Bản dịch có thể chậm hơn bản tiếng Anh. Nếu hai bản khác nhau, bản tiếng Anh là chuẩn.

**Dành cho những ai bảo agent "sai rồi" và nhận về một bài giảng hoặc một lời xin lỗi.**

Khi bạn phản bác một khẳng định, agent thường làm một trong hai việc. Nó bảo vệ khẳng định bằng đúng lập luận cũ, nói to hơn. Hoặc nó xuôi theo và đồng ý với bạn mà không kiểm tra gì. Cả hai đều không cho bạn biết khẳng định đó có đúng hay không.

Skill này khiến agent coi sự nghi ngờ của bạn là tín hiệu để kiểm chứng, không phải bằng chứng cho bên nào. Nó tách ra một khẳng định có thể bác bỏ được, gắn nhãn những gì câu trả lời cũ thực sự dựa vào (quan sát trực tiếp, tool báo cáo, suy luận, nhớ lại, hay tự khai), và chạy một phép kiểm tra có thể cho kết quả khác: tắt fallback, dùng nonce ẩn, hỏi thẳng endpoint đích. Kết quả là đúng một trạng thái: Confirmed, Corrected hoặc Blocked.

## Nguồn gốc

Được `gpt-5.6-sol` dựng bằng [`/learn`](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills#learning-a-skill-from-sources-learn) của Hermes Agent, từ chính yêu cầu của người vận hành, ngay sau khi một model khẳng định đã dùng vision gốc trong khi thực ra không. Từ đó Hermes đã load skill khoảng 140 lần, và vòng review nền của nó đã tinh chỉnh skill một lần. Bản public bỏ tên tool riêng của harness và chi tiết setup.

## Cài đặt

```bash
npx skills add duu261/agent-skills --skill claim-check
# Hermes Agent
hermes skills install duu261/agent-skills/skills/claim-check
```

Hoặc copy `skills/claim-check/` vào thư mục skill của harness.

## Giấy phép

MIT
