# Có Gì Mới Trong Phiên Bản 2.3.0

MacStash 2.3.0 mang đến các cải tiến toàn diện về trải nghiệm âm thanh, điều khiển độ sáng đa màn hình, hồ sơ ứng dụng tùy biến và thanh trượt cạnh màn hình.

## Những Cải Tiến Nổi Bật Trong Bản 2.3.0

- Cập nhật 1 chạm tự động (Sparkle 2): Tích hợp framework cập nhật chuẩn công nghiệp của macOS với cơ chế xác minh chữ ký mã hóa Ed25519 (CryptoKit). Nâng cấp trực tiếp không cần tải hay kéo thả file thủ công.
- Nâng cấp Audio Engine hiện đại: Chuyển dịch toàn bộ sang chuẩn AudioObject APIs mới nhất của Apple, tích hợp nút tắt tiếng nhanh trên biểu tượng loa menu bar và danh sách chọn thiết bị đầu ra tức thì.
- Độ sáng đa màn hình: Thanh trượt độ sáng độc lập cho từng màn hình trên menu bar popover kèm tên thiết bị, biểu tượng và tự động lưu cấu hình theo mã UUID màn hình.
- Hồ sơ ứng dụng (App Profiles): Trình quản lý hồ sơ trong Cài đặt cho phép gán hành động góc và thanh trượt riêng biệt theo từng ứng dụng.
- Thanh trượt cạnh màn hình (Edge Sliders): Thao tác trượt nhanh ở cạnh phải màn hình với cơ chế nhận diện biên ngoài và xuyên click (pass-through) thông minh.
- Phím tắt toàn cục động: Bộ phân tích phím tắt tùy chỉnh kèm tính năng phát hiện xung đột thời gian thực với các phím tắt hệ thống macOS.
- An toàn đồng thời Swift 6: Chuẩn hóa Swift 6 Strict Concurrency cho các dịch vụ cập nhật tự động, giao diện và quyền hệ thống.
- Sao lưu toàn diện: Tệp sao lưu và phục hồi JSON bao gồm đầy đủ cấu hình hệ thống và toàn bộ hồ sơ ứng dụng.

# Có Gì Mới Trong Phiên Bản 2.0.0

MacStash 2.0.0 là bản cập nhật lớn tập trung vào ổn định, nâng cao trải nghiệm và bổ sung tính năng cao cấp.

## Những Cải Tiến Nổi Bật

- Nhận diện hình học góc ngoài biên cho hệ thống đa màn hình.
- Máy trạng thái formal state machine quản lý hiện/ẩn với bộ đếm generation.
- Hỗ trợ Universal Binary cho cả Apple Silicon (arm64) và Intel (x86_64).
- Điều khiển độ sáng đa màn hình tích hợp DisplayServices, DDC/CI và giảm sáng bằng phần mềm.
- Đồng hồ tập trung Pomodoro theo thời gian đơn điệu không bao giờ bị đơ khi kéo chuột và tồn tại qua chế độ ngủ.
- Cửa sổ Settings chuẩn 7 tab với deep link cấp quyền và sao lưu cấu hình qua tệp JSON.
- Hướng dẫn sử dụng offline tích hợp tìm kiếm và chương trình Onboarding chào mừng người dùng.
