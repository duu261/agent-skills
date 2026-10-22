# claim-check

[English](README.md) | Tiếng Việt

> Bản dịch có thể chậm hơn bản tiếng Anh. Nếu hai bản khác nhau, bản tiếng Anh là chuẩn.

**Dành cho những ai bảo agent "sai rồi" và nhận về một bài giảng hoặc một lần xuôi theo.**

Khi bạn phản bác một khẳng định, agent thường làm một trong hai việc. Nó bảo vệ khẳng định bằng đúng lập luận cũ, nói to hơn. Hoặc nó xuôi theo và đồng ý với bạn mà không kiểm tra gì. Cả hai đều không cho bạn biết khẳng định đó có đúng hay không.

Skill này khiến agent coi sự nghi ngờ của bạn là tín hiệu để kiểm chứng, không phải bằng chứng cho bên nào. Nó tách ra một khẳng định có thể bác bỏ được, gắn nhãn những gì câu trả lời cũ thực sự dựa vào (quan sát trực tiếp, tool báo cáo, suy luận, nhớ lại, hay tự khai), và chạy một phép kiểm tra có thể cho kết quả khác: tắt fallback, dùng nonce ẩn, hỏi thẳng endpoint đích. Kết quả là đúng một trạng thái: Confirmed, Corrected hoặc Blocked.

## Nguồn gốc

Được `gpt-5.6-sol` dựng bằng [`/learn`](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills#learning-a-skill-from-sources-learn) của Hermes Agent, từ chính yêu cầu của người vận hành, ngay sau khi một model khẳng định đã dùng vision gốc trong khi thực ra không. Từ đó Hermes đã load skill khoảng 140 lần, và vòng review nền của nó đã tinh chỉnh skill một lần. Bản public bỏ tên tool riêng của harness và chi tiết setup.

## Bonus: A/B cùng một model

Hai session mới trên cùng model `deepseek-v4-flash`, cách nhau một phút. Cả hai cùng hỏi một câu: giải thích một plugin coding-style hoạt động thế nào. Plugin đó đã được cài trên máy nhưng đang tắt.

- **Có load skill:** agent đọc source của plugin, phần đăng ký hook, và danh sách plugin của chính harness. Trả lời: đã cài, chưa bật, không inject gì. Đúng.
- **Cấm load skill:** agent tìm thấy bản copy của plugin trong thư mục của các agent khác và đọc README. Kết luận: "Your setup already uses it." Sai. Nó chỉ tự sửa sau khi được cho xem session thứ nhất và chạy các bước kiểm tra đã bỏ qua.

Khác biệt nằm ở một bước: kiểm tra nguồn có thẩm quyền, không phải file khớp dễ tìm nhất. Đây là một cặp, không phải benchmark. Skill cũng được gọi ngay từ đầu, trước khi có khẳng định nào bị phản bác, tức là ngoài trigger chính của nó. Hãy xem đây là minh họa cơ chế, không phải điểm số.

## Cài đặt

```bash
npx skills add duu261/agent-skills --skill claim-check
# Hermes Agent
hermes skills install duu261/agent-skills/skills/claim-check
```

Hoặc copy `skills/claim-check/` vào thư mục skill của harness.

## Giấy phép

MIT
