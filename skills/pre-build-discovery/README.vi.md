# pre-build-discovery

[English](README.md) | Tiếng Việt

> Bản dịch có thể chậm hơn bản tiếng Anh. Nếu hai bản khác nhau, bản tiếng Anh là chuẩn.

**Dành cho những ai hỏi agent "có đáng làm không?" và nhận về code.**

Agent thường trả lời câu hỏi khả thi bằng cách bắt tay vào làm luôn. Nó thiết kế từ danh từ đầu tiên nghe được, bỏ qua bước tìm xem đã có công cụ nào chưa, tin vào API nó nhớ thay vì API trong source, và coi mọi giới hạn là chặn hẳn, hoặc chẳng coi cái nào là chặn.

Skill này giữ agent ở giai đoạn bàn bạc cho tới khi có kết luận. Nó chốt thuật ngữ trước, quét những gì đã có (trong máy, catalog của dự án, issue upstream, hệ sinh thái lân cận), đọc ràng buộc thật từ source kèm trích dẫn, và gắn nhãn từng giới hạn là chặn hẳn, đánh đổi độ trung thực, hay chỉ khác hình thức. Chỉ giới hạn chặn hẳn mới đổi kết luận. Cuối cùng là làm / chờ / không làm, cộng một phép kiểm tra có thể lật kết luận, và suốt quá trình chỉ đọc, không thay đổi gì.

## Nguồn gốc

Được `claude-opus-5-5` dựng bằng [`/learn`](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills#learning-a-skill-from-sources-learn) của Hermes Agent, từ một phiên thiết kế thật về việc có nên làm một provider plugin hay không. Sau đó skill được tinh chỉnh qua các phiên discovery tiếp theo (bố cục repo, xuất bản, chờ upstream) khi gặp tình huống mới. Bản public bỏ tên tool riêng của harness và chi tiết setup.

## Cài đặt

```bash
npx skills add duu261/agent-skills --skill pre-build-discovery
# Hermes Agent
hermes skills install duu261/agent-skills/skills/pre-build-discovery
```

Hoặc copy `skills/pre-build-discovery/` vào thư mục skill của harness.

## Giấy phép

MIT
