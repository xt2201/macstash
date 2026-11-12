# Lịch Sử Phiên Bản & Tính Năng Mới

## Phiên bản 2.16.3 (2026-11-12)

### Tua Nhạc Vuốt Dọc 2 Ngón, Căn Chuẩn Chấm Tua & Đại Tu Hit-Test

- **Vuốt Dọc 2 Ngón Tua Nhạc Trên Dynamic Island**: Khi đã di chuột qua audio và mở trình tua Dynamic Island, thao tác vuốt dọc 2 ngón lên/xuống sẽ tua nhạc mượt mà tương đồng với thanh trượt cạnh và hoàn toàn không làm thay đổi nhầm âm lượng hệ thống. Âm lượng chỉ thay đổi khi bạn chủ động đưa chuột vào thanh volume thả xuống.
- **Động Cơ Tua Nhạc Chuẩn Xác**: Khắc phục mã lệnh MediaRemote `SeekToPlaybackPosition` (`24` thay vì `48`), định tuyến chuẩn PID trình phát và bổ sung dự phòng AppleScript cho Spotify / Apple Music cùng bộ đệm đồng bộ sau khi tua.
- **Chấm Tròn Tua Khớp Chính Xác 100%**: Sửa thứ tự modifier `.scaleEffect` và `.position` trên thanh tua để chấm tròn và vạch tiến trình luôn khớp tâm từ 0% đến 100% không bị lệch.
- **Đồng Bộ Toàn Hệ Thống**: Chuẩn hóa chuyển đổi toạ độ `hitTest` cho toàn bộ 4 góc nóng, ngăn kéo, thanh cạnh và Second Dock; hỗ trợ phím `Esc` đóng thanh cạnh trái và vòng xoay góc; tách vùng dọc chống đè giữa Ngăn kéo và Thanh cạnh trái; và đồng bộ trực tiếp đèn nền bàn phím phần cứng.

---

## Phiên bản 2.16.2 (2026-11-12)

### Sửa Lỗi Ổn Định Thanh Cạnh

- **Thanh cạnh không còn biến mất khi rê chuột vào ảnh bìa nhạc**: Vùng tương tác của thanh cạnh nay đủ cao để chứa toàn bộ thanh, nên khi mở bảng điều khiển âm thanh kiểu Dynamic Island thanh vẫn hiển thị.
- **Kích thước cửa sổ thanh cạnh ổn định**: Cửa sổ thanh cạnh giữ kích thước cố định để vùng nhận chuột luôn khớp với những gì bạn nhìn thấy.

---

## Phiên bản 2.16.1 (2026-11-12)

### Vuốt 2 Ngón Tua Nhạc, Chuẩn Hóa Cài Đặt & Khắc Phục Trùng Đè

- **Vuốt 2 Ngón Trên Trackpad Tua Nhạc**: Khi di chuột vào khu vực Media Island trên thanh cạnh hoặc góc nóng, người dùng có thể vuốt ngang bằng 2 ngón tay sang trái/phải để tua lùi hoặc tua tiến bài hát. Hỗ trợ tự động đảo chiều theo Natural Scrolling, co giãn bước tua theo độ dài bài hát, phản hồi mượt 120fps và rung xúc giác (haptic detent ticks) mỗi 5 giây tua.
- **Nút Âm Lượng Thả Xuống Sát Mép Dynamic Island**: Thêm nút biểu tượng Âm lượng nằm ở vị trí sát mép viền nhất của đảo âm thanh (bên phải nút Next ở cạnh phải, bên trái nút Previous ở cạnh trái); khi hover sẽ trượt thanh volume xuống bám sát mép màn hình với tông màu kính hòa trộn theo ảnh bìa.
- **Chuẩn Hóa Thẻ Cài Đặt Chống Tràn Viền**: Chuyển đổi toàn bộ các thanh Segmented Picker đa ngữ trong Cài đặt (tab Góc Nóng, Cài Đặt Chung, Giao Diện, Màn Hình) sang bố cục dọc full-width và phân tách hàng cấu hình cạnh Trái/Phải độc lập, xóa bỏ hiện tượng tràn thẻ và cắt chữ.
- **Bảo Đảm Khoảng Cách An Toàn Trên Góc Nóng**: Quy chuẩn lại toạ độ cực và bán kính của Center Badge cùng các nút vệ tinh, bảo đảm khoảng hở an toàn >= 8.0pt ở cỡ chuẩn và >= 3.0pt ở cỡ tối thiểu (110pt), loại bỏ hoàn toàn việc nút Play/Pause bị che lấp bởi viền huy hiệu trung tâm.
- **Đồng Bộ Thời Gian Tua Thực Tế**: Khắc phục lỗi thanh tua bị reset về 0 khi di chuột; định kỳ đối soát vị trí phát thực tế từ Spotify, Music và trình phát hệ thống.

---

## Phiên bản 2.16.0 (2026-11-11)

### Dynamic Island Âm Thanh, Thanh Trượt Cạnh Kép & Tua Nhạc Độc Lập

- **Mở Rộng Âm Thanh Kiểu Dynamic Island Trên Thanh Cạnh**: Khi rê chuột qua ảnh bìa nhạc nhỏ gọn ở cuối thanh trượt, widget sẽ chuyển động mở rộng ngang mượt mà kiểu Dynamic Island hiển thị tên bài hát, nghệ sĩ, sóng nhạc, thanh tua nhạc tương tác và 5 nút điều khiển (Bài trước, Lùi 10s, Phát/Dừng, Tiến 10s, Bài tiếp), giữ cho thanh trượt dọc luôn gọn gàng.
- **Thanh Trượt Cạnh Kép (Hỗ Trợ Đồng Thời Cả Hai Bên Trái & Phải)**: Người dùng có thể tùy chọn kích hoạt cả hai bên mép màn hình cùng lúc (mặc định), với cấu hình tác vụ độc lập cho từng bên (ví dụ Cạnh trái cho Độ sáng / Tua nhạc, Cạnh phải cho Âm lượng).
- **Tác Vụ Tua & Điều Khiển Đa Phương Tiện Độc Lập (`mediaPlayback`)**: Bổ sung tính năng điều khiển âm thanh độc lập có thể gán riêng cho bất kỳ góc nóng hoặc thanh trượt cạnh nào, biến góc nóng thành đĩa xoay tua nhạc chuyên nghiệp và thanh cạnh thành thanh tua tiến độ bài hát.
- **Khắc Phục Trùng Lặp Nút Vệ Tinh Góc Nóng**: Định vị lại các nút vệ tinh âm thanh (Lùi 10s, Phát/Dừng, Tiến 10s) vào quỹ đạo bên trong với khoảng cách rộng rãi, loại bỏ hoàn toàn hiện tượng nút bấm đè lên viền cung đo âm lượng.

---

## Phiên bản 2.15.0 (2026-11-11)

### Đồng Bộ Phần Cứng Trực Tiếp, Tua Nhạc & Tối Ưu Góc Tiện Ích

- **Đồng bộ Phần cứng Tức thì**: Truy vấn trực tiếp độ sáng màn hình vật lý và âm lượng CoreAudio từ hệ thống macOS. Mọi thao tác bấm phím vật lý trên bàn phím Mac (F1/F2 hoặc phím âm lượng) lập tức cập nhật chuẩn xác lên núm xoay góc nóng và thanh trượt cạnh màn hình, loại bỏ hoàn toàn hiện tượng lệch trạng thái.
- **Tính năng Tua Nhạc & Điều khiển Đa phương tiện**: Bổ sung thanh tua nhạc tương tác trực tiếp trên cả Thanh trượt cạnh và Vòng xoay góc nóng. Hỗ trợ kéo tua đến vị trí mong muốn, nút Tua tới 10 giây (`goforward.10`), Tua lùi 10 giây (`gobackward.10`) cùng nhãn thời gian thực (`1:24 / 3:45`) cho Apple Music, Spotify và trình phát hệ thống.
- **Thả Tệp Trực Tiếp Vào Góc Nóng & Phím Vệ Tinh**: Cho phép kéo thả trực tiếp tệp tin vào góc nóng được gán cho Kệ thả tệp Stash Shelf. Vành xoay của góc tiện ích bổ sung các nút vệ tinh một chạm để mở ngăn kéo, sao chép ghi chú nhanh, kích hoạt giữ máy thức vô hạn hoặc dọn sạch tệp.
- **Thẻ Tiện Ích Trên Thanh Trượt Cạnh**: Thanh cạnh màn hình khi gán cho Ghi chú, Kệ thả tệp hoặc Giữ máy thức (Caffeine) chuyển sang giao diện thẻ chuyên dụng với xem trước nội dung và các mốc đặt sẵn (Tắt, 15p, 30p, 1h, 2h, Vô hạn) thay vì thanh trượt 0-100% chung chung.
- **Tự Động Kích Hoạt Ngăn Kéo**: Thiết lập bất kỳ góc nóng hoặc thanh cạnh nào sang Ghi chú hoặc Kệ thả tệp sẽ tự động dựng và cấp quyền hiển thị cho lớp phủ ngăn kéo mà không cần bật thủ công trong Cài đặt.

---

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
