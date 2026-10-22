# repo-state-authority

[English](README.md) | Tiếng Việt

> Bản dịch có thể chậm hơn bản tiếng Anh. Nếu hai bản khác nhau, bản tiếng Anh là chuẩn.

**Dành cho những ai từng thấy agent xóa một branch vì diff trông quá lớn, hoặc tin một file trạng thái hơn `git log`.**

Agent đọc trạng thái repo từ tín hiệu dễ thấy nhất. Nó coi một branch là việc bị mất vì `git diff main <branch>` dài hàng nghìn dòng, trong khi branch đó đã merge hết và chỉ là `main` đã đi xa hơn. Nó tin file trạng thái hoặc ghi chú bàn giao hơn Git, và kết luận một file đã mất vì `git diff` trống, trong khi file đó chỉ là chưa được track hoặc bị ignore.

Skill này bắt agent chọn đúng nguồn có thẩm quyền cho từng câu hỏi trước: Git cho source, đọc lại runtime cho thứ đang deploy, đường public cho thứ người ngoài thấy, và lời của chính chủ repo cho ý định. Nó phân loại branch theo quan hệ tổ tiên và danh tính patch (`rev-list --left-right`, `git cherry`), tách bạch commit đang deploy, commit source và commit chuẩn, không đụng vào việc của con người, và chỉ xóa branch sau khi đã ghi file SHA để khôi phục.

## Nguồn gốc

Do agent tạo ra trong [vòng tự cải thiện](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills#when-the-agent-creates-skills) của Hermes Agent, trong các lần dọn repo thật vào tháng 8 năm 2026. Sau đó skill được dùng khoảng 240 lần và sửa khoảng 90 lần, phần lớn do review chạy nền sau các phiên dùng `claude-opus-5-5`, `gpt-5.6-sol` và `gpt-6-astra`. Bản public giữ quy trình xác định thẩm quyền trong Git và bỏ các phần chỉ đúng với một setup (overlay của fork, gom máy chủ, fork firmware).

## Cài đặt

```bash
npx skills add duu261/agent-skills --skill repo-state-authority
# Hermes Agent
hermes skills install duu261/agent-skills/skills/repo-state-authority
```

Hoặc copy `skills/repo-state-authority/` vào thư mục skill của harness.

## Giấy phép

MIT
