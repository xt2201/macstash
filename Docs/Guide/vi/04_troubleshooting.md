# Xử Lý Sự Cố và Phân Quyền

## Thiết Lập Quyền Hệ Thống

1. **Accessibility (Trợ Năng)**:
   Bắt buộc để theo dõi vị trí con trỏ chuột toàn cục và quản lý lớp overlay không kích hoạt cửa sổ.
   Cấp quyền tại: System Settings > Privacy & Security > Accessibility.

2. **Input Monitoring (Theo Dõi Đầu Vào)**:
   Bắt buộc để nhận diện phím bổ trợ và thao tác cuộn khi tinh chỉnh thông số.
   Cấp quyền tại: System Settings > Privacy & Security > Input Monitoring.

3. **Notifications (Thông Báo)**:
   Dùng để gửi thông báo khi đồng hồ Pomodoro hoàn thành. Cấp quyền tại: System Settings > Notifications > MacStash. MacStash tích hợp thông báo tiền cảnh (`UNUserNotificationCenterDelegate`), chuông báo âm thanh (`Glass`) cùng hiệu ứng nhảy icon Dock (`requestUserAttention`) để bạn không bỏ lỡ thông báo kết thúc phiên.

## Tránh Chạm Nhầm Các Góc

Nếu vòng xoay xuất hiện quá nhạy hoặc ảnh hưởng đến ứng dụng khác:
- Giảm bán kính vùng kích hoạt (Hit-Zone Sensitivity) xuống 3-5 điểm trong Settings > Hot Corners.
- Tăng thời gian dừng chờ (Dwell Activation Delay) lên 200-300 ms.
- Bật tính năng chặn khi đang kéo chuột hoặc khi ứng dụng khác chạy full screen.
- Thêm các ứng dụng chuyên dụng vào Danh sách ứng dụng loại trừ.

## Thay Đổi Ngôn Ngữ Giao Diện

Người dùng có thể chuyển đổi linh hoạt giữa Tiếng Việt và English bất kỳ lúc nào:
- Mở Settings (`Command+,`) > Tab **General (Tổng quan)** > mục **Ngôn ngữ giao diện (Interface Language)**.
- Chọn **Tiếng Việt** hoặc **English**. Toàn bộ các tab cài đặt, thanh công cụ, menu bar và cẩm nang hướng dẫn sẽ tự động cập nhật ngôn ngữ ngay lập tức mà không cần khởi động lại ứng dụng.

## Hiển Thị Biểu Tượng Trên Menu Bar

- Người dùng có thể giữ phím `Command` và kéo chuột trái để sắp xếp lại vị trí của icon MacStash trên thanh Menu Bar.
- Biểu tượng status bar sử dụng kênh alpha đơn sắc tự nhiên, tự động thích ứng với độ trong suốt và chủ đề nền sáng / tối của hệ điều hành macOS.

## Kéo Chỉnh Thời Gian Pomodoro & Thao Tác Góc Xoay

- Để chỉnh thời lượng khi đồng hồ ở trạng thái chờ, hãy kéo rê ở vành ngoài vòng xoay (phần rãnh cong bên ngoài nút tròn ở giữa). Vành xoay nhận diện chính xác từ 1 đến 60 phút kèm rung xúc giác nhẹ.
- Nhấp chuột trực tiếp vào nút tròn ở giữa để Bắt đầu hoặc Tạm dừng mà không lo bị ghi đè thời lượng đã chọn.
- Sử dụng hai nút phụ mini bên trong góc xoay để Đặt lại hoặc Chuyển nhanh sang hiệp nghỉ/làm việc kế tiếp.

## Cơ Chế Ẩn Của Thanh Trượt Cạnh Màn Hình (Edge Slider)

- Thanh trượt cạnh phải được ẩn hoàn toàn khi ở trạng thái nghỉ nhằm giữ cho màn hình thoáng đãng và không che khuất nội dung của các ứng dụng khác.
- Để gọi thanh trượt, chỉ cần di chuyển con trỏ chuột chạm vào sát mép ngoài cùng bên phải của màn hình. Thanh trượt sẽ trượt ra mượt mà để bạn điều chỉnh nhanh âm lượng hoặc độ sáng.

## Tinh Chỉnh Đèn Nền Bàn Phím Trên Menu Bar

- Thanh trượt điều chỉnh đèn bàn phím phản hồi mượt mà theo thời gian thực và đồng bộ ngay lập tức với cảm biến phần cứng của MacBook.
- Khi mở bảng điều khiển Menu Bar, ứng dụng sẽ tự động đọc mức sáng hiện tại từ hệ thống để đảm bảo giá trị luôn chính xác ngay cả khi bạn vừa chỉnh bằng phím vật lý hoặc Control Center.
- Bạn có thể nhấp chuột trực tiếp vào biểu tượng bàn phím ở đầu thanh trượt để bật hoặc tắt nhanh đèn nền.

## Hoạt Động Trên Hệ Thống Đa Màn Hình

- MacStash hỗ trợ đầy đủ 4 góc xoay và thanh trượt cạnh phải trên mọi màn hình được kết nối (bao gồm cả màn hình MacBook và màn hình rời bên ngoài).
- Bạn có thể kích hoạt nhanh vòng xoay tại góc bằng cách nhấp chuột trực tiếp (Click-to-Activate) hoặc rê chuột và dừng trong giây lát (Dwell Activation).
- Nếu không muốn kích hoạt vòng xoay ở các vị trí tiếp giáp giữa các màn hình, hãy vào Cài đặt > Góc Màn Hình (Hot Corners) và bật tùy chọn "Chỉ kích hoạt góc biên ngoài (tắt góc tiếp giáp giữa các màn hình)".
- Bảng điều khiển từ biểu tượng Menu Bar tự động phát hiện màn hình bạn đang thao tác để hiển thị cửa sổ mở rộng chuẩn xác ngay dưới vị trí con trỏ chuột trên màn hình đó.

## Điều Khiển Bằng Cử Chỉ Cuộn Hai Ngón Tay

- Nếu thao tác cuộn 2 ngón tay không làm thay đổi giá trị, hãy kiểm tra xem tùy chọn "Cuộn hai ngón để điều chỉnh" trong Cài đặt > Góc nóng > Cử chỉ tương tác đã được bật hay chưa.
- Giá trị chỉ thay đổi trong lúc ngón tay tiếp xúc và di chuyển trên trackpad. Quán tính trượt sau khi nhấc ngón tay được tự động lọc bỏ nhằm đảm bảo âm lượng hoặc độ sáng không bị tăng giảm quá mức.
