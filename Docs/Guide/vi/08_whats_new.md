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

# Có Gì Mới Trong Phiên Bản 2.3.3

MacStash 2.3.3 ra mắt hệ thống kết xuất vector AppKit không suy hao, tích hợp bộ nhận diện tương thích giao diện kép Light/Dark trên GitHub và nâng cấp toàn diện tài liệu trực quan.

## Những Cải Tiến Nổi Bật Trong Bản 2.3.3

- Kết xuất vector AppKit thuần túy: Thay thế hoàn toàn cơ chế QuickLook bằng script Swift AppKit chuyên dụng, đảm bảo toàn bộ asset giữ chuẩn tỷ lệ khung hình, khử răng cưa Retina và có độ trong suốt alpha tuyệt đối không bị viền trắng.
- Logo Lockup tương thích giao diện kép: Tinh chỉnh lockup sáng và tối sang dạng nền trong suốt giúp hiển thị liền mạch trên cả hai chế độ Light mode và Dark mode của GitHub.
- Sơ đồ kiến trúc 4 góc màn hình: Bổ sung sơ đồ trực quan độ phân giải cao minh họa chi tiết 4 góc điều khiển xúc giác và thanh trượt Dock ẩn ở cạnh màn hình.
- Nâng cấp toàn diện README: Tái cấu trúc tài liệu giới thiệu với bảng huy hiệu phẳng, nút tải trực tiếp DMG, bảng minh bạch quyền bảo mật và phân tích nguyên lý Định luật Fitts.

# Có Gì Mới Trong Phiên Bản 2.3.2

MacStash 2.3.2 tối ưu hóa độ mượt mà của thanh trượt đèn nền bàn phím trên thanh điều khiển Menu Bar, đồng bộ tức thì với phần cứng và hỗ trợ bật/tắt nhanh bằng một chạm.

## Những Cải Tiến Nổi Bật Trong Bản 2.3.2

- Thanh trượt đèn bàn phím mượt mà: Loại bỏ độ trễ và hiện tượng giật rung khi kéo thanh trượt trên menu bar, đồng bộ vị trí con trỏ và nhãn phần trăm với tốc độ khung hình cao.
- Cô lập giao diện thanh trượt: Tách riêng thanh trượt đèn nền và âm lượng thành các thành phần giao diện chuyên biệt, loại bỏ thao tác truy vấn màn hình thừa thãi khi đang kéo chuột.
- Đồng bộ phần cứng khi mở bảng điều khiển: Tự động cập nhật mức sáng đèn nền bàn phím và âm lượng thực tế của hệ thống ngay khi mở menu bar popover.
- Chạm nhanh để bật/tắt đèn nền: Nhấp chuột vào biểu tượng bàn phím ở đầu thanh trượt để bật hoặc tắt nhanh đèn nền.
- Cải tiến thanh trượt âm lượng: Chuẩn hóa cập nhật âm lượng đồng bộ trên luồng chính giúp thao tác kéo thả êm ái và chính xác hơn.

# Có Gì Mới Trong Phiên Bản 2.3.1

MacStash 2.3.1 khắc phục triệt để lỗi nhảy thời gian Pomodoro, cải tiến trải nghiệm góc xoay với cụm nút phụ tiện ích và ẩn hoàn toàn thanh trượt cạnh phải khi ở trạng thái nghỉ.

## Những Cải Tiến Nổi Bật Trong Bản 2.3.1

- Khắc phục lỗi nhảy thời gian Pomodoro: Loại bỏ xung đột cử chỉ khiến thao tác chạm nút giữa bị tính nhầm thành kéo vòng xoay, chấm dứt hiện tượng thời gian bị nhảy về 24 hoặc 23 phút.
- Hiển thị vành cung chuẩn xác: Vành xoay ở trạng thái chờ thể hiện chính xác mốc phút đã chọn theo mặt đồng hồ 60 phút mà không bị nhảy vọt lên 100% khi thả chuột.
- Tích hợp nút phụ mini tiện ích: Bổ sung hai nút bấm Đặt lại và Bỏ qua hiệp trực tiếp bên trong góc xoay, thao tác nhanh mà không cần mở menu bar.
- Chỉ báo hiệp làm việc trực quan: Huy hiệu trung tâm hiển thị các chấm tròn tiến trình cho biết số hiệp đã hoàn thành trong chu kỳ.
- Ẩn hoàn toàn thanh trượt cạnh phải: Thanh trượt cạnh phải được ẩn 100% khi nghỉ, chỉ trượt ra khi con trỏ chạm sát mép ngoài màn hình.
- Giữ hiển thị khi tạm dừng: Menu bar tiếp tục hiển thị thời gian còn lại khi phiên đếm đang tạm dừng.

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
