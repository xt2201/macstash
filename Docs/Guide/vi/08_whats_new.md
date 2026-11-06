# Có Gì Mới Trong Phiên Bản 2.5.0

MacStash 2.5.0 mang đến khả năng tùy biến tác vụ EdgeBar trong Cài đặt và bộ điều khiển nhạc Now Playing dọc đa ứng dụng dưới thanh âm lượng, tích hợp ảnh bìa album thực tế, hiệu ứng sóng nhạc nhảy theo điệu và phím điều khiển dọc.

## Những Cải Tiến Nổi Bật Trong Bản 2.5.0

- Tùy chọn tác vụ EdgeBar trong Cài đặt: Dễ dàng cấu hình tính năng cho thanh trượt cạnh màn hình (Âm lượng, Độ sáng màn hình, Đèn bàn phím, Đồng hồ Pomodoro, hoặc Tắt).
- Bộ điều khiển nhạc Now Playing đa nguồn: Khi gán EdgeBar cho Âm lượng, một module điều khiển nhạc dọc sẽ xuất hiện ngay dưới thanh trượt, tự động nhận diện nhạc đang phát từ bất kỳ ứng dụng nào trên macOS (Apple Music, Spotify, YouTube trên Safari/Chrome, Podcasts, VLC).
- Ảnh bìa album thực tế: Hiển thị ảnh bìa bài hát chất lượng cao với góc bo tròn mềm mại phong cách Liquid Glass và hiệu ứng đổ bóng tinh tế.
- Sóng nhạc nhảy theo điệu: 5 thanh equalizer màu cam hổ phách nhảy múa sống động theo nhịp bài hát và mức âm lượng, tự động hạ về mức nghỉ khi tạm dừng nhạc.
- Phím điều khiển bố cục dọc: Sắp xếp các phím bấm theo chiều dọc tối ưu cho mép màn hình: Lùi bài ở trên, Phát/Tạm dừng ở giữa, và Chuyển bài ở dưới.
- Thẻ xem trước thông tin bài hát: Rê chuột vào ảnh album để mở thẻ xem trước trượt sang trái hiển thị đầy đủ tên bài hát, nghệ sĩ và album.
- Tùy chỉnh linh hoạt: Tùy chọn trong Cài đặt > Góc Màn Hình cho phép bật/tắt bộ điều khiển nhạc Now Playing và hiệu ứng sóng nhạc theo ý muốn.

# Có Gì Mới Trong Phiên Bản 2.4.0

MacStash 2.4.0 mang đến tính năng cuộn hai ngón tay trên trackpad, nâng cấp toàn diện khả năng hỗ trợ hệ thống đa màn hình, cơ chế kích hoạt tức thì khi nhấp chuột tại các góc và sửa lỗi mở rộng bảng điều khiển Menu Bar trên màn hình rời.

## Những Cải Tiến Nổi Bật Trong Bản 2.4.0

- Cuộn 2 ngón tay trên trackpad để điều chỉnh: Người dùng chỉ cần rê chuột vào vòng quay góc hoặc thanh trượt cạnh phải và lướt 2 ngón tay lên hoặc xuống để tăng giảm âm lượng, độ sáng, đèn bàn phím hoặc thời gian Pomodoro mà không cần nhấn giữ chuột.
- Hỗ trợ đa màn hình hoàn chỉnh: Khắc phục hiện tượng các góc màn hình và thanh trượt cạnh phải trên màn hình phụ bị vô hiệu hóa do thuật toán biên ngoài. Tất cả 4 góc của mọi màn hình giờ đây đều hoạt động độc lập và mượt mà.
- Kích hoạt góc bằng nhấp chuột (Click-to-Activate): Ngoài việc dừng chuột theo thời gian trễ (Dwell), người dùng có thể nhấp chuột trực tiếp vào góc màn hình để mở ngay vòng quay mà không cần chờ đợi.
- Tùy chọn lọc góc biên ngoài: Thêm công tắc trong Cài đặt > Góc Màn Hình cho phép người dùng tùy ý bật/tắt tính năng chỉ nhận góc biên ngoài hoặc nhận toàn bộ các góc tiếp giáp giữa các màn hình.
- Bảng điều khiển Menu Bar thông minh: Nhấp vào biểu tượng ứng dụng ở thanh Menu Bar trên bất kỳ màn hình nào (kể cả màn hình ngoài) đều sẽ mở rộng cửa sổ popover chuẩn xác ngay tại vị trí con trỏ chuột trên màn hình đó.
- Điều khiển độ sáng độc lập: Thanh trượt cạnh phải truyền đúng mã định danh màn hình để điều chỉnh mức sáng riêng biệt cho từng màn hình rời.
- Cơ chế chặn quán tính thông minh: Tự động loại bỏ các sự kiện trượt quán tính sau khi nhấc ngón tay, đảm bảo giá trị dừng lại chính xác tại vị trí mong muốn.

# Có Gì Mới Trong Phiên Bản 2.3.5

MacStash 2.3.5 mang đến cơ chế đồng bộ số hiệu phiên bản động trên giao diện, bộ kiểm thử toàn vẹn phiên bản tự động và tối ưu hóa độ ổn định của quy trình phát hành CI/CD.

## Những Cải Tiến Nổi Bật Trong Bản 2.3.5

- Hiển thị số phiên bản động: Thay thế toàn bộ chuỗi phiên bản cố định trong cài đặt và danh mục bản địa hóa bằng cơ chế truy xuất động từ App Bundle, đảm bảo tab Giới thiệu luôn phản ánh chuẩn xác phiên bản đang chạy.
- Bộ kiểm thử toàn vẹn phiên bản tự động: Bổ sung kiểm thử tự động xác minh tính đồng nhất giữa thẻ phát hành, siêu dữ liệu Info.plist, tài liệu hướng dẫn và luồng cập nhật Sparkle.
- Quy trình phát hành CI/CD chống lỗi: Xử lý an toàn các thư viện Python tùy chọn trong kịch bản kết xuất tài nguyên, ngăn chặn gián đoạn luồng tự động hóa trên máy chủ từ xa.

# Có Gì Mới Trong Phiên Bản 2.3.4

MacStash 2.3.4 đảm bảo thông báo hoàn thành Pomodoro trên macOS với cơ chế hiển thị tiền cảnh, chuông báo âm thanh và hiệu ứng nhảy icon Dock.

## Những Cải Tiến Nổi Bật Trong Bản 2.3.4

- Hiển thị biểu ngữ thông báo tiền cảnh: Tích hợp `UNUserNotificationCenterDelegate` kèm tùy chọn `.banner, .sound, .badge, .list`, chấm dứt hiện tượng macOS tự động nuốt/bỏ qua biểu ngữ khi ứng dụng đang chạy.
- Chuông báo âm thanh tức thì: Phát âm thanh thông báo macOS rõ ràng (`Glass`) và rung xúc giác khi kết thúc phiên, đảm bảo bạn luôn nghe thấy ngay cả khi biểu ngữ bị ẩn.
- Hiệu ứng nhảy icon Dock: Gọi `NSApp.requestUserAttention` khiến icon ứng dụng nhảy trên Dock để báo hiệu phiên tập trung hoặc phiên nghỉ đã hoàn thành.
- Đồng bộ thông điệp chính xác: Khắc phục thông điệp thông báo bị ngược, thông báo chính xác "Hoàn thành phiên Pomodoro" khi hết giờ làm việc và "Kết thúc giờ nghỉ" khi hết giờ nghỉ.
