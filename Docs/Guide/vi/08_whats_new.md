# Có Gì Mới Trong Phiên Bản 2.8.1

MacStash 2.8.1 khắc phục triệt để sự cố ứng dụng bị thoát đột ngột khi khởi chạy sau khi cập nhật do cơ chế tìm kiếm tài nguyên Bundle.module của Swift Package Manager, đồng thời tăng cường độ nhạy khi nhấp chuột lần đầu vào vòng xoay góc.

## Những Cải Tiến Nổi Bật Trong Bản 2.8.1

- Khắc Phục Sự Cố Thoát Đột Ngột Khi Khởi Động: Chuyển đổi toàn bộ cơ chế nạp tài nguyên giao diện từ Bundle.module của SPM sang Bundle.main chuẩn macOS, giải quyết triệt để lỗi could not load resource bundle làm ứng dụng bị thoát đột ngột sau khi cập nhật.
- Tuân Thủ Kiến Trúc Bundle Chuẩn macOS: Tinh chỉnh cấu hình gói Swift Package để tài nguyên được đặt chuẩn xác trong Contents/Resources mà không gây lỗi chữ ký số hay tìm sai thư mục gốc.
- Phản Hồi Nhấp Chuột Tức Thì Trên Vòng Xoay Góc: Các vành xoay góc phản hồi ngay lập tức ở lần nhấp đầu tiên mà không cần nhấp chuột kích hoạt cửa sổ trước.

# Có Gì Mới Trong Phiên Bản 2.8.0

MacStash 2.8.0 nâng cấp toàn diện trải nghiệm UI/UX chuẩn mực macOS, cơ chế truyền sự kiện chuột hoàn toàn không chặn ứng dụng nền, cử chỉ lắc chuột mở nhanh kệ tệp Stash Shelf, khả năng nhận diện phím gõ tức thì cho bảng ghi chú Scratchpad, phản hồi nhấp chuột tức thì ngay lần chạm đầu tiên, và nút sao chép toàn bộ tệp.

## Những Cải Tiến Nổi Bật Trong Bản 2.8.0

- Cử Chỉ Lắc Chuột Mở Nhanh Khi Kéo Tệp (Shake-to-Summon): Chỉ cần lắc nhẹ con trỏ chuột qua lại khi đang kéo bất kỳ tệp, hình ảnh hoặc đoạn văn bản nào, Kệ Stash Shelf sẽ lập tức xuất hiện ngay tại con trỏ kèm phản hồi rung xúc giác chân thực.
- Cơ Chế Chuột Không Xâm Lấn Ứng Dụng Nền: Các panel nổi ở mép màn hình mặc định kích hoạt ignoresMouseEvents = true khi ở trạng thái nghỉ, đảm bảo mọi cú nhấp chuột vào ứng dụng phía dưới (thanh bên Finder, tab Safari, trình soạn thảo Xcode, Terminal) hoạt động trơn tru 100% không bị che khuất hay nuốt sự kiện.
- Gờ Chạm Tinh Tế Kiểu Dáng Notch Kính Mờ: Thay thế thanh nổi vướng víu cũ bằng một gờ chỉ thị kính mờ thanh mảnh 3.5pt ôm sát viền màn hình, chỉ mở rộng thành thanh điều khiển nhanh khi rê chuột có chủ đích.
- Phản Hồi Nhấp Chuột Tức Thì (First-Mouse Clicks): Tích hợp InteractiveHostingView và MacStashInteractivePanel trên toàn bộ các lớp phủ nổi, đảm bảo tất cả nút bấm (Xóa hết, Sao chép đường dẫn, Mở trong Finder, Xóa mục, Đóng) kích hoạt chuẩn xác ngay lần nhấp đầu tiên mà không bị nuốt sự kiện kích hoạt cửa sổ.
- Nhập Liệu Tức Thì Cho Bảng Ghi Chú Scratchpad: Cửa sổ Scratchpad được cấp quyền nhận sự kiện bàn phím động ngay khi mở, cho phép nhấp vào gõ chữ ngay, chọn khối văn bản và sử dụng đầy đủ các tổ hợp phím tắt chuẩn macOS (Cmd+A, Cmd+C, Cmd+V, Cmd+Z, Esc).
- Sao Chép Toàn Bộ & Thước Đo Kích Thước Tệp: Bổ sung nút bấm một chạm "Sao chép tất cả" và dòng chỉ báo dung lượng tổng định dạng chuẩn (X mục · Y MB) trên thanh tiêu đề Stash Shelf.

# Có Gì Mới Trong Phiên Bản 2.7.0

MacStash 2.7.0 nâng cấp toàn diện trải nghiệm UI/UX chuẩn mực macOS, cơ chế truyền sự kiện chuột hoàn toàn không chặn ứng dụng nền, cử chỉ lắc chuột mở nhanh kệ tệp Stash Shelf, khả năng nhận diện phím gõ tức thì cho bảng ghi chú Scratchpad, phản hồi nhấp chuột tức thì ngay lần chạm đầu tiên, và tích hợp cầu nối MediaRemote cấp hệ thống.

## Những Cải Tiến Nổi Bật Trong Bản 2.7.0

- Cử Chỉ Lắc Chuột Mở Nhanh Khi Kéo Tệp (Shake-to-Summon): Chỉ cần lắc nhẹ con trỏ chuột qua lại khi đang kéo bất kỳ tệp, hình ảnh hoặc đoạn văn bản nào, Kệ Stash Shelf sẽ lập tức xuất hiện ngay tại con trỏ kèm phản hồi rung xúc giác chân thực.
- Cơ Chế Chuột Không Xâm Lấn Ứng Dụng Nền: Các panel nổi ở mép màn hình mặc định kích hoạt `ignoresMouseEvents = true` khi ở trạng thái nghỉ, đảm bảo mọi cú nhấp chuột vào ứng dụng phía dưới (thanh bên Finder, tab Safari, trình soạn thảo Xcode, Terminal) hoạt động trơn tru 100% không bị che khuất hay nuốt sự kiện.
- Gờ Chạm Tinh Tế Kiểu Dáng Notch Kính Mờ: Thay thế thanh nổi vướng víu cũ bằng một gờ chỉ thị kính mờ thanh mảnh 3.5pt ôm sát viền màn hình, chỉ mở rộng thành thanh điều khiển nhanh khi rê chuột có chủ đích.
- Phản Hồi Nhấp Chuột Tức Thì (First-Mouse Clicks): Tích hợp `InteractiveHostingView` và `MacStashInteractivePanel` trên toàn bộ các lớp phủ nổi, đảm bảo tất cả nút bấm (Xóa hết, Sao chép đường dẫn, Mở trong Finder, Xóa mục, Đóng) kích hoạt chuẩn xác ngay lần nhấp đầu tiên mà không bị nuốt sự kiện kích hoạt cửa sổ.
- Nhập Liệu Tức Thì Cho Bảng Ghi Chú Scratchpad: Cửa sổ Scratchpad được cấp quyền nhận sự kiện bàn phím động ngay khi mở, cho phép nhấp vào gõ chữ ngay, chọn khối văn bản và sử dụng đầy đủ các tổ hợp phím tắt chuẩn macOS (Cmd+A, Cmd+C, Cmd+V, Cmd+Z, Esc).
- Sao Chép Toàn Bộ & Thước Đo Kích Thước Tệp: Bổ sung nút bấm một chạm "Sao chép tất cả" và dòng chỉ báo dung lượng tổng định dạng chuẩn (X mục · Y MB) trên thanh tiêu đề Stash Shelf.
- Bắt Nhạc & Ảnh Bìa Đa Trình Duyệt Trên macOS 15.4+: Sử dụng cầu nối `now-playing.pl` và `libMacStashNowPlaying.dylib` thông qua `MRPlayerPath`, giúp bắt chính xác tên bài hát, nghệ sĩ, trạng thái phát và ảnh bìa album từ mọi trình duyệt (bao gồm trình duyệt Crest đang phát SoundCloud, Safari, Chrome, Arc) cũng như Spotify, Apple Music và VLC.
- Hiệu Ứng Sóng Nhạc Đổi Màu Theo Ảnh Bìa: Tự động phân tích phổ màu từ ảnh bìa của bài hát đang phát để nhuộm màu đồng bộ cho 5 thanh sóng nhạc equalizer, viền phát sáng quanh ảnh bìa và nút Phát/Tạm dừng.
- Nhịp Điệu Sóng Nhạc Thời Gian Thực 30fps: Bộ tạo nhịp đa băng tần mô phỏng độ nảy âm trầm và âm cao sống động theo bài hát đang phát và tự động hạ nhịp êm ái khi tạm dừng.
- Thanh Trượt EdgeBar Mượt Mà 120Hz: Tách biệt luồng ghi phần cứng CoreAudio bất đồng bộ, triệt tiêu xung đột đọc ngược khi đang kéo, lưu đệm cấu hình màn hình và trì hoãn ghi đĩa giúp thao tác kéo chuột lên xuống hoặc cuộn 2 ngón tay mượt mà tức thì.

# Có Gì Mới Trong Phiên Bản 2.6.0

MacStash 2.6.0 mang đến tính năng đinh Kệ thả tệp Stash Shelf, núm xoay chống tắt máy Keep-Awake (Caffeine), bảng ghi chú nhanh Scratchpad và vòng xoay điều khiển tại con trỏ chuột Cursor Radial Palette.

## Những Cải Tiến Nổi Bật Trong Bản 2.6.0

- Kệ thả tệp Stash Drop Shelf: Hiện thực hóa trọn vẹn định danh MacStash. Một kệ kính mờ trượt êm ái từ mép trái màn hình để cất giữ tệp tin, hình ảnh, liên kết web và đoạn văn bản khi kéo thả qua lại giữa các không gian Spaces, màn hình phụ hoặc ứng dụng.
- Núm xoay chống tắt máy Keep-Awake (Caffeine): Động cơ quản lý điện năng I/O Kit ngăn màn hình và hệ thống chuyển sang chế độ ngủ khi xuất video, biên dịch mã nguồn hoặc thuyết trình, tích hợp sẵn các nấc xoay định trước (15 phút, 30 phút, 1 giờ, 2 giờ, và Vô hạn), phản hồi rung xúc giác cơ học và chỉ báo trạng thái trên thanh Menu Bar.
- Bảng ghi chú nhanh Scratchpad: Ngăn kéo ghi chú kính mờ thanh lịch ở cạnh trái màn hình với bộ đếm từ và ký tự thời gian thực, tự động lưu trữ cục bộ an toàn, thao tác sao chép hoặc xóa sạch trong một lần chạm.
- Vòng xoay tại con trỏ chuột (Cursor Radial Palette): Triệu hồi các núm xoay điều khiển âm lượng, độ sáng, chống ngủ và đếm giờ Pomodoro ngay tại tâm con trỏ chuột thông qua phím tắt toàn cục (Option + Space), đặc biệt tối ưu cho người dùng màn hình siêu rộng Ultrawide hoặc thiết lập nhiều màn hình.
- Phím tắt toàn cục tùy biến: Cho phép gán phím tắt nhanh cho Vòng xoay tại trỏ chuột (Option+Space), Kệ Stash Shelf (Control+Option+S), và Bảng ghi chú Scratchpad (Control+Option+N).

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
