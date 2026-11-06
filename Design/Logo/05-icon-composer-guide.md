# Stash cho macOS: Hướng Dẫn Dựng Tệp .icon bằng Apple Icon Composer

Tài liệu hướng dẫn từng bước quy trình lắp ráp và cấu hình tệp `.icon` chuẩn Apple Liquid Glass bằng ứng dụng Apple Icon Composer (macOS 15 Sequoia / Xcode 16+).

---

## 1. Các Tệp Layer Sẵn Sàng (Prepared Layer Assets)
Các tệp SVG nguồn nằm tại `Design/Logo/source/`:
1. `stash_icon_background.svg`: Tầng nền không cắt mask (1024x1024), gradient Obsidian Slate đến Deep Charcoal.
2. `stash_icon_foreground.svg`: Tầng vành quạt quang học (Cyan/Azure), hạt nhân gốc và các vạch detent cơ học.
3. `stash_icon_mono.svg`: Bản hình học đơn sắc (Monochrome Silhouette) với các mức alpha tương ứng cho độ phản xạ quang học và chế độ Tinted.

---

## 2. Quy Trình Từng Bước trong Icon Composer

### Bước 1: Tạo Dự Án Icon Mới (New Icon Document)
1. Mở **Icon Composer** trên macOS.
2. Chọn **File > New** (hoặc bấm `Command + N`).
3. Chọn template **macOS App Icon** (Canvas 1024 x 1024).

### Bước 2: Thiết Lập Tầng Nền (Background Layer)
1. Kéo thả tệp `Design/Logo/source/stash_icon_background.svg` vào ô **Background** trong ngăn Layer Stack bên trái.
2. Hoặc chọn tùy chọn **Native Solid / Gradient** trong Inspector panel bên phải:
   - Type: `Linear Gradient` (góc 135 độ).
   - Start Color: `#191D26` (Obsidian Slate).
   - End Color: `#0D0F14` (Deep Charcoal).

### Bước 3: Thiết Lập Nhóm Tiền Cảnh (Foreground Group)
1. Kéo thả tệp `Design/Logo/source/stash_icon_foreground.svg` vào ô **Foreground**.
2. Trong Inspector panel:
   - **Blend Mode**: Chọn `Normal`.
   - **Material Type**: Chọn `Liquid Glass / Specular Glass`.
   - **Refraction Index**: Chọn `1.15` (tạo độ cong uốn quang học nhẹ quanh mép vành dial).
   - **Specular Highlights**: Chọn `Automatic` (hệ thống tự động phản chiếu vạch sáng theo chiều chiếu sáng dọc của macOS).

### Bước 4: Gắn Bản Hình Học Đơn Sắc (Monochrome Representation)
1. Chọn slot **Monochrome / Tint Representation**.
2. Kéo thả tệp `Design/Logo/source/stash_icon_mono.svg`.
3. Icon Composer sẽ sử dụng các mức độ alpha của tệp này để áp dụng màu sắc khi người dùng bật chế độ **Tinted Mode** trong phần cài đặt hiển thị macOS.

### Bước 5: Kiểm Tra Trực Quan 4 Chế Độ Hiển Thị (Variants Inspection)
Trong thanh Preview toolbar của Icon Composer, lần lượt chuyển đổi giữa:
- **Default**: Kiểm tra độ phản xạ ánh sáng trên mặt kính vành dial.
- **Dark**: Kiểm tra độ sâu của bề mặt Obsidian và tính phát quang của hạt nhân Cyan.
- **Clear**: Xác nhận rằng hình ảnh hình nền bên dưới được khúc xạ tự nhiên qua khối kính.
- **Tinted**: Kiểm tra với các màu mẫu (vàng, xanh lá, đỏ) xem khối hình học có bị mất tương phản hay không.

### Bước 6: Xuất Asset (Export)
1. Chọn **File > Export...**.
2. Định dạng xuất: `.icon` hoặc kéo thả trực tiếp vào Xcode Asset Catalog (`Assets.xcassets/AppIcon.icon`).

---

## 3. Ghi Chú về Môi Trường Thực Thi
- Trong môi trường máy chủ dòng lệnh (CLI headless runner), ứng dụng đồ họa Icon Composer không được cài đặt sẵn trong `/Applications`.
- Dự án sử dụng pipeline tự động hóa độc lập `scripts/render_icons.sh` để sinh bộ `AppIcon.appiconset` và `MacStash.icns` dự phòng chuẩn mực, đảm bảo ứng dụng luôn hiển thị đầy đủ icon trên mọi phiên bản macOS từ macOS 13 trở lên.
