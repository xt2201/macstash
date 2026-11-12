# Lịch Sử Phiên Bản & Tính Năng Mới

## Phiên bản 2.18.0 (2026-11-12)

### Tích Hợp Toàn Diện `SideDockEngine` (Docky) & 18 Tiện Ích Hợp Nhất

- **Kiến Trúc `SideDockEngine` Đầy Đủ**: Nâng cấp Second Dock lên trọn bộ động cơ cửa sổ, sóng phóng đại, kính thực thời (`LiveGlassBackdrop`), Start Menu (`MenuCatalog`), bộ giao diện tích hợp (`BundledThemes`), Launchpad (`Control+Option+L`), Live Window Switcher (`Option+Tab`), chừa không gian hệ thống và trình chỉnh sửa Dock trực quan.
- **9 Tiện Ích Độc Quyền Của Stash Trong Thư Viện Docky**: Đưa `Clock`, `Pomodoro`, `File Shelf`, `Clipboard History`, `Quick Note`, `Screenshot`, `Color Picker`, `Unit Converter` và `Bookmarks` thành tiện ích chuẩn `WidgetKind` ngay trong bộ chọn Widget, Smart Stack, thẻ mở rộng khi rê chuột và cài đặt từng tiện ích.
- **Đồng Bộ Now Playing & Cài Đặt Thống Nhất**: Kết nối `NowPlayingManager` hai chiều với widget Now Playing của Docky và nhúng trực tiếp toàn bộ trình cấu hình đa ngăn của Docky vào tab **Settings > Second Dock**.

---

## Phiên bản 2.17.0 (2026-11-12)

### Nâng Cấp Toàn Diện Second Dock Chuẩn Docky

- **Hiệu Ứng Phóng Đại Gợn Sóng, Nhãn Nổi & Kéo Thả Trực Tiếp**: Rê chuột qua các ứng dụng ghim và đang chạy tạo sóng phóng đại cosin mượt mà 120Hz trên cả 4 cạnh màn hình, nhãn nổi Liquid Glass tức thì, hiệu ứng nảy khi mở app, ô Thùng rác kéo thả để xóa tệp, ô khôi phục cửa sổ thu nhỏ và kéo thả sắp xếp/ghim trực tiếp từ Finder.
- **Smart Stack, Nhóm Ứng Dụng & Mặt Tiện Ích Trực Tiếp**: Gộp nhiều tiện ích vào một ô duy nhất với cuộn hai ngón để chuyển trang (`SmartStackItem`), tạo nhóm ứng dụng 2x2 kèm tổng huy hiệu thông báo, và chuyển đổi biểu tượng Calendar, Weather, Music, Spotify, Clock, Reminders, Activity Monitor sang mặt tiện ích sống.
- **Xem Trước Cửa Sổ Trực Tiếp & Trình Chuyển Cửa Sổ (`Option+Tab`)**: Rê chuột vào app đang chạy để xem ảnh thu nhỏ trực tiếp qua `ScreenCaptureKit` kèm khung viền sáng cửa sổ thật trên màn hình và nút Tập trung/Thu nhỏ/Đóng, hoặc nhấn `Option+Tab` (tùy chọn thay `Cmd+Tab`) để chuyển cửa sổ toàn cục khi thả phím bổ trợ.
- **Launchpad Toàn Màn Hình (`Control+Option+L`)**: Trình mở ứng dụng có tìm kiếm tức thì, lọc theo danh mục, tạo thư mục tùy chỉnh, điều hướng bàn phím và chỉnh số cột/kích thước ngay trong giao diện.
- **18 Tiện Ích Cục Bộ, Mở Rộng Popover, Menu Ngữ Cảnh & Biểu Tượng Tùy Chỉnh**: Bổ sung tiện ích **Batteries** (pin Mac + thiết bị Bluetooth) và **Photo Frame**, thẻ mở rộng hỗ trợ nhập phím, menu hành động nhanh theo từng app (New Window/Tab/Xcode Run & Test), tác vụ AppleScript/Shell/Menu-Click, tùy chỉnh icon riêng và tự động chuyển hồ sơ theo ứng dụng đang dùng.

---

## Phiên bản 2.16.12 (2026-11-12)

### Khắc Phục Lưu Ảnh Bìa Cũ Trên Thanh Cạnh Khi Phát Bài Không Có Ảnh

- **Xóa Ảnh Bìa Cũ Tức Thì Khi Đổi Bài Không Có Ảnh**: Khắc phục lỗi khi phát nhạc trên Music hoặc các trình phát khác, nếu chuyển từ bài có ảnh bìa sang bài không có ảnh bìa, thanh cạnh âm lượng (Edge Bar) và Dynamic Island vẫn giữ lại ảnh bìa và màu sắc của bài cũ. Nay giao diện lập tức chuyển về biểu tượng nốt nhạc mặc định cùng tông màu chuẩn.
- **Ảnh Bìa Audio Gọn Sạch Hơn**: Bỏ dấu chấm màu hiển thị đè trên góc ảnh bìa audio của thanh cạnh Edge Bar để phần hiển thị ảnh bìa gọn gàng hơn.

---

## Phiên bản 2.16.11 (2026-11-12)

### Cân Đối Hình Học Nút Tròn Góc Màn Hình & Đối Xứng Bán Kính

- **Định Vị Cân Đối Nút Tròn Trung Tâm (Center Action Hub)**: Khắc phục triệt để lỗi mất cân đối thẩm mỹ khi hình tròn trung tâm nằm quá xa góc máy và bị dí sát đường kẻ cung tròn bên ngoài. Tinh chỉnh khoảng cách lề góc theo tỷ lệ chuẩn 4.0pt - 8.0pt, đưa nút tròn về vị trí ôm sát góc máy tự nhiên và gọn gàng.
- **Đối Xứng Bán Kính Tuyệt Đối Giữa Góc Máy Và Đường Kẻ Màu**: Đồng bộ bán kính đường kẻ cung tròn bao ngoài (`hubHaloArcRadius`) luôn cách đều mép ngoài nút tròn một khoảng đúng bằng khoảng cách từ đỉnh góc máy tới mép trong nút tròn (`badgeCornerInnerMargin`), tạo tỷ lệ đối xứng 1:1 hoàn hảo và thoáng đãng trên mọi kích thước (100pt - 250pt).

---

## Phiên bản 2.16.10 (2026-11-12)

### Triệt Tiêu Nhảy Nháy Icon Âm Lượng & Tự Ẩn Sát Viền Thanh Cạnh

- **Triệt Tiêu Lỗi Nhảy Nháy Icon Âm Lượng Trên Đảo Nhạc**: Khắc phục triệt để xung đột vùng nhận chuột làm thanh dọc âm lượng nhảy nháy liên tục khi rê chuột vào icon loa sau khi mở phần tua audio. Rê chuột vào ảnh audio mở đảo tua nhạc sạch sẽ; rê vào icon loa sẽ hiện cột âm lượng ổn định; rời khỏi icon loa sang các nút khác sẽ ẩn cột âm lượng; di chuột thẳng lên cột âm lượng sẽ thu gọn phần tua và quay lại giao diện âm lượng ban đầu (Mode A).
- **Thu Hẹp Vùng Tự Ẩn Sát Thanh Cạnh & Trả Click Nền Tức Thì**: Co vùng nhận diện thanh cạnh Mode A từ `340pt` về khớp sát chiều rộng thực `56pt` của thanh trượt (`~74pt` cả lề). Chỉ cần đưa chuột ra khỏi phần diện tích thanh trượt một khoảng nhỏ theo chiều ngang, thanh cạnh lập tức nhường quyền click lại cho ứng dụng nền và tự ẩn mượt sau `0.12s`.

---

## Phiên bản 2.16.9 (2026-11-12)

### Ẩn Thanh Âm Lượng Khi Rời Icon & Tự Động Quay Lại Chỉnh Âm Lượng Ban Đầu

- **Ẩn Thanh Âm Lượng Khi Rời Icon Loa**: Khi di chuyển trỏ chuột ra khỏi biểu tượng loa sang các phần khác trên đảo nhạc, thanh dọc chỉnh âm lượng sẽ tự động ẩn đi gọn gàng, trả lại không gian thoáng đãng cho phần tua nhạc.
- **Tự Động Quay Lại Cột Chỉnh Âm Lượng Khi Di Lên**: Khi đang rê chuột ở icon loa mà di chuột lên phía thanh dọc chỉnh âm lượng, phần tua nhạc sẽ tự động thu gọn lại và đưa bạn quay trở về giao diện cột chỉnh âm lượng nguyên bản ban đầu (Mode A) ngay dưới đầu ngón tay.

---

## Phiên bản 2.16.8 (2026-11-12)

### Khắc Phục Cắt Viền Thanh Cạnh Âm Thanh & Chống Nhảy Rung Icon Volume

- **Triệt Tiêu Hoàn Toàn Lỗi Cắt Phần Trên Cột Âm Thanh**: Tinh giản cụm điều khiển phát nhạc trên thanh cạnh Mode A về 3 nút chuẩn (Lùi bài, Phát/Tạm dừng, Chuyển bài) kèm khoảng cách 6pt đồng nhất, tiết kiệm 54pt chiều cao. Kết hợp lề đáy 60pt mới, nút tác vụ trên đỉnh luôn nằm an toàn bên trong khung hiển thị với hơn 70pt khoảng trống phía trên.
- **Giữ Cố Định Thanh Âm Lượng & Triệt Tiêu Hiệu Ứng Nhảy Rung**: Khi mở thanh trượt âm lượng từ Dynamic Island, thanh trượt được giữ cố định mượt mà trong suốt thời gian rê chuột trên đảo nhạc hoặc cột âm lượng. Thay thế chuyển động bắn từ đáy lên bằng hiệu ứng phóng to mờ dần gắn chặt tại chỗ, đồng thời cô lập animation giúp đảo nhạc không bị rung giật mỗi khi rê chuột qua lại icon loa.
- **Đồng Bộ Tọa Độ Tương Tác**: Cập nhật vùng nhận chuột cho cử chỉ vuốt 2 ngón tua nhạc và nhận diện nút volume khớp chuẩn với lề 60pt mới.

---

## Phiên bản 2.16.7 (2026-11-12)

### Mở Rộng Tua Nhạc Ngay Tại Chỗ & Triệt Tiêu Nhảy Vị Trí

- **Mở Rộng Tua Nhạc Sang Bên Ngay Tại Chỗ**: Khi rê chuột vào ảnh bìa bài hát để tua nhạc, thanh Dynamic Island mở rộng sang ngang mượt mà ngay tại đúng vị trí của ảnh bìa. Giao diện hoàn toàn không còn bị nhảy dịch lên giữa màn hình, giữ trỏ chuột nằm trọn vẹn trong thanh điều khiển.
- **Thanh Volume Thả Xuống Cố Định Vững Chắc**: Khi di chuột sang biểu tượng loa, cột chỉnh âm lượng trượt ra phía trên đảo nhạc một cách tự nhiên trong khi đảo nhạc vẫn giữ nguyên vị trí cố định, không rung lắc.
- **Khớp Vùng Nhận Chuột Vuốt Tua 2 Ngón**: Đồng bộ tọa độ nhận tương tác và kiểm tra nút âm lượng với vị trí đảo nhạc mới, giúp thao tác vuốt 2 ngón tua nhạc nhạy bén và không bị mất hover.

---

## Phiên bản 2.16.6 (2026-11-12)

### Căn Giữa Hoàn Hảo & Đồng Bộ Vị Trí Thanh Trượt Cạnh Màn Hình

- **Căn Giữa Trục Dọc Cho Cả Hai Thanh Cạnh**: Cả Thanh trượt cạnh trái và cạnh phải nay được đặt tại chính giữa màn hình theo phương thẳng đứng. Nội dung thanh trượt bên trong cửa sổ hiển thị được căn giữa thay vì bị kéo xuống đáy, giúp thanh trượt xuất hiện ngay tại vị trí trỏ chuột thay vì bị lệch xuống dưới.
- **Phối Hợp Tương Tác Nhịp Nhàng Giữa Thanh Cạnh & Ngăn Kéo**: Giải quyết triệt để tình trạng cạnh tranh kích hoạt rê chuột giữa Thanh cạnh và Ngăn kéo Stash Shelf khi nằm cùng một mép màn hình. Thao tác rê chuột thông thường mở thanh trượt cạnh tại vị trí giữa, kéo thả tệp từ Finder sẽ mở Stash Shelf để nhận file, và thanh trượt cạnh tạm ẩn khi ngăn kéo đang mở.
- **Đồng Bộ Vùng Nhận Chuột Dynamic Island**: Cập nhật vùng nhận chuột cho Dynamic Island và thanh volume thả xuống khớp hoàn hảo với bố cục căn giữa mới.

---

## Phiên bản 2.16.5 (2026-11-12)

### Sửa Lỗi Vuốt 2 Ngón Tua Nhạc & Chuyển Chế Độ Icon Âm Lượng

- **Sửa Chiều Vuốt Ngang 2 Ngón Khi Tua Nhạc**: Chuẩn hóa hướng cuộn theo đúng quy ước trục `NSEvent` của macOS, khắc phục tình trạng vuốt 2 ngón sang phải bị tua lùi trên Dynamic Island thanh cạnh (cũng như Góc nóng và Vòng xoay con trỏ) ở cả hai chế độ bật/tắt Natural Scrolling.
- **Chuyển Sang Chỉnh Âm Lượng Khi Rê Chuột Vào Icon Loa**: Khi đưa con trỏ lên biểu tượng Âm lượng ở mép ngoài Dynamic Island, thao tác vuốt 2 ngón (cả lên/xuống lẫn phải/trái) lập tức chuyển từ tua nhạc sang tăng/giảm âm lượng hệ thống và tự động quay lại tua nhạc ngay khi bạn rời chuột khỏi icon loa.

---

## Phiên bản 2.16.4 (2026-11-12)

### Bản Vá Khẩn Cấp Khắc Phục Treo Ứng Dụng Sau Khi Cập Nhật

- **Sửa lỗi không mở được app sau khi cập nhật v2.16.3**: Loại bỏ vòng lặp dựng lại giao diện SwiftUI vô hạn gây treo app và chiếm 100% CPU ngay lúc khởi động do cập nhật thuộc tính `@Published` của đèn nền bàn phím bên trong chu trình vẽ `CornerDialView.body`. Ứng dụng nay mở tức thì và hoạt động ổn định.
- **Tách Bạch Cơ Chế Đọc Phần Cứng Thuần Túy**: Tách hàm đọc trực tiếp trạng thái phần cứng không gây đột biến `@Published` (`currentHardwareBrightness()`, `readBrightnessLevel(for:)`) cho giao diện, đồng thời lọc bỏ các thông báo `objectWillChange` dư thừa khi âm lượng hoặc độ sáng chưa thay đổi.

---

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
