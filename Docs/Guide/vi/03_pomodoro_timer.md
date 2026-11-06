# Đồng Hồ Tập Trung Pomodoro

Bộ máy Pomodoro trong MacStash được tích hợp trực tiếp vào vòng xoay góc màn hình (Corner Dial) và biểu tượng trên thanh menu bar, mang lại trải nghiệm quản lý thời gian tập trung và nghỉ ngơi mượt mà, chính xác.

## Tính Năng Nổi Bật

1. **Chu Kỳ Pomodoro Toàn Diện**:
   Hệ thống hỗ trợ đầy đủ chu kỳ làm việc tiêu chuẩn: Phiên tập trung (Focus Session), Nghỉ ngắn (Short Break) và Nghỉ dài (Long Break) sau số hiệp quy định. Bạn có thể bật tính năng tự động kích hoạt giờ nghỉ ngay khi phiên tập trung kết thúc.

2. **Chỉ Báo Thời Gian Thực Trên Menu Bar**:
   Khi phiên đếm đang chạy, biểu tượng MacStash trên thanh menu bar tự động chuyển sang trạng thái hoạt động (Active) kèm chuỗi đếm ngược thời gian thực (ví dụ 24:50). Khi tạm dừng hoặc ở trạng thái chờ, menu bar thu gọn về biểu tượng tĩnh tối giản.

3. **Điều Khiển Nhanh Qua Menu Bar Popover**:
   Bấm vào biểu tượng menu bar để mở cửa sổ điều khiển:
   - Nút Bắt đầu / Tạm dừng: Phản hồi tức thì ngay từ trạng thái chờ.
   - Nút Bỏ qua hiệp: Cho phép chuyển nhanh sang phiên nghỉ hoặc phiên làm việc tiếp theo.
   - Nút Đặt lại: Khôi phục phiên về thời lượng ban đầu đã thiết lập.
   - Thanh tiến trình mini hiển thị tỷ lệ thời gian còn lại trực quan.

4. **Tương Tác Thông Minh Với Vòng Xoay & Cụm Nút Phụ**:
   - Khi đang chạy hoặc tạm dừng: Vòng cung thể hiện tỷ lệ tiến trình thu hẹp dần. Chạm vào huy hiệu trung tâm để tạm dừng hoặc tiếp tục. Thao tác kéo rê được bảo vệ an toàn để không vô tình xoá phiên làm việc. Huy hiệu trung tâm hiển thị các chấm tròn chỉ báo hiệp làm việc hiện tại (ví dụ Hiệp 1/4).
   - Khi ở trạng thái chờ: Kéo rê vành ngoài của vòng xoay để điều chỉnh chính xác thời lượng phiên (từ 1 đến 60 phút) kèm phản hồi rung xúc giác mỗi 5 phút. Vành cung thể hiện đúng mốc phút đã chọn mà không bị nhảy. Chạm vào nút Bắt đầu ở giữa để khởi động phiên đúng thời lượng đã kéo mà không bị trả về mặc định.
   - Nút phụ tiện lợi tích hợp: Hai nút bấm mini Đặt lại và Bỏ qua hiệp được bố trí tinh tế ngay trong góc xoay, cho phép thao tác một chạm mà không cần mở menu bar.
   - Màu sắc nhận diện rõ ràng: Màu tím cho phiên làm việc, màu xanh lá cho phiên nghỉ ngơi.

5. **Đồng Hồ Đơn Điệu Và Bền Bỉ Qua Sleep/Wake**:
   Thời gian còn lại được tính toán dựa trên mốc thời gian kết thúc và đồng hồ đơn điệu của hệ thống (monotonic clock). Thao tác kéo cửa sổ hoặc để máy tính ở chế độ ngủ (Sleep) không làm sai lệch hay đóng băng đồng hồ. Khi mở máy, hệ thống lập tức cập nhật lại trạng thái chính xác.

6. **Lưu Trữ Và Khôi Phục Phiên Tự Động**:
   Trạng thái phiên đếm (thời gian còn lại, chế độ, số hiệp đã hoàn thành) được tự động lưu vào bộ nhớ cục bộ. Nếu bạn khởi động lại ứng dụng, phiên làm việc sẽ được khôi phục nguyên vẹn.

7. **Thông Báo Bản Địa Hóa**:
   Phát thông báo biểu ngữ hệ thống bằng ngôn ngữ đã chọn kèm âm thanh cơ học dứt khoát khi hoàn thành phiên tập trung hoặc phiên nghỉ.

## Xử Lý Sự Cố

- **Không nhận được thông báo khi hết giờ**:
  Vào Cài Đặt Hệ Thống (System Settings) > Thông Báo (Notifications) > MacStash và đảm bảo đã cấp quyền "Cho phép thông báo" (Allow Notifications).
- **Muốn thay đổi thời gian phiên mặc định**:
  Mở MacStash Preferences (⌘,), chọn thẻ Pomodoro và điều chỉnh các thanh trượt: Thời gian tập trung, Thời gian nghỉ ngắn, Thời gian nghỉ dài và Số hiệp trước khi nghỉ dài. Thay đổi sẽ có hiệu lực ngay khi đồng hồ ở trạng thái chờ.
