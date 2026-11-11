# Lịch Sử Phiên Bản & Tính Năng Mới

## Phiên bản 2.14.0 (2026-11-11)

### Đại tu toàn diện UI/UX và Logic Nghiệp Vụ

- **Cửa sổ Cài đặt Sidebar chuẩn macOS**: Thiết kế lại toàn bộ Cài đặt từ dạng tab cũ sang bố cục sidebar chia 3 nhóm (8 mục) với chấm trạng thái trực tiếp, công tắc tổng ở đầu sidebar và các thẻ `SettingsCard` sạch đẹp.
- **Tổng quan & Góc nóng trực quan**: Bổ sung bảng trạng thái 6 module bấm nhảy nhanh, tùy chọn thời lượng Giữ máy thức mặc định, Sơ đồ màn hình tương tác (nhấp chọn trực tiếp 4 góc, Thanh trượt cạnh hoặc Ngăn kéo), cùng trình chọn ứng dụng đồ họa (`AppPickerHelper`) khi tạo Hồ sơ ứng dụng và Danh sách loại trừ.
- **Studio Liquid Glass Trực Tiếp**: Cho phép kéo thử trực tiếp trên vòng xoay mẫu ngay trong tab Giao diện với nền Sáng/Tối giả lập, chuyển đổi 4 góc, thử rung xúc giác & âm thanh, và đồng bộ Light/Dark trên toàn bộ cửa sổ và lớp phủ.
- **Menu Bar Control Center**: Nâng cấp menu bar popover `296pt` với thẻ ngữ cảnh, đồng hồ Pomodoro, danh sách màn hình tối ưu bộ nhớ đệm, 6 ô bật/tắt module nhanh và nút mở Hướng dẫn sử dụng (`Command+?`).
- **Màn hình, Pomodoro, Phím tắt & Thông tin**: Bổ sung Ngưỡng sáng tối đa phần cứng và nút Mức nhanh 25/50/75/100%, vòng đếm ngược Pomodoro lớn kèm nút chọn chế độ, Bộ ghi phím tắt Keycap với kiểm tra xung đột tự động (`ShortcutValidator`), trạng thái cập nhật Sparkle 2, Onboarding minh họa vector và trình đọc Hướng dẫn Markdown chuẩn bảng/callout.
- **Thanh Dock thứ hai & Tùy biến Tiện ích**: Thêm bảng cấu hình riêng từng tiện ích (`WidgetConfigSheet` cho Thời tiết theo thành phố, Đồng hồ Kim/Điện tử/Thẻ lật & Múi giờ, Hiệu năng Hệ thống, Lịch/Nhắc nhở tự cập nhật khi hệ thống đổi dữ liệu, Dấu trang), giữ nguyên trạng thái widget không bị reset khi đổi ứng dụng đang mở, kéo cửa sổ Dock nổi mượt 1:1, và đo % CPU delta chuẩn xác (`CPUTickSample`).
- **Khắc phục triệt để đối xứng Cạnh Trái/Phải & Hiệu năng**: Sửa lỗi nhận diện cạnh khi đặt Thanh trượt ở bên trái hoặc Ngăn kéo ở bên phải bằng `CornerGeometry`, đồng bộ hai chiều `AppState.settings`, chỉ chạy bộ dựng sóng nhạc 30fps khi overlay mở, giảm tần suất poll âm thanh lúc nhàn rỗi và áp dụng đồng bộ dải chặn sáng phần cứng.

---

## Phiên bản 2.13.1 (2026-04-17)

### Sửa lỗi & Tinh chỉnh Tương tác

- Khắc phục nhận diện thao tác vuốt ngang trackpad trên vòng xoay góc và tối ưu độ tương phản vật liệu kính.
