# Stash cho macOS: Design Brief và Nghiên Cứu Thương Hiệu

Tài liệu quy chuẩn thiết kế thương hiệu, phân tích thị trường và quy định kỹ thuật biểu tượng cho ứng dụng Stash trên hệ điều hành macOS.

---

## 1. Tổng Quan về Ứng Dụng Stash

### 1.1. Tính Năng và Kiến Trúc Ứng Dụng
Stash là một tiện ích hệ thống cao cấp dành cho macOS (menu bar utility app) được tối ưu hóa cho trải nghiệm thao tác không gian điều khiển màn hình rộng và đa màn hình. Các tính năng cốt lõi gồm:
- **Hot Corner Dials (Vòng quay góc màn hình)**: Tận dụng triệt để 4 góc vật lý của màn hình macOS (Top-Left, Top-Right, Bottom-Left, Bottom-Right) để kích hoạt các đồng hồ vòng cung 1/4 hình tròn (quarter-circle radial dials) thông qua cơ chế rê chuột chậm (dwell delay 0.2s) với vùng hit-test tiêu chuẩn 5-8 điểm nhằm triệt tiêu kích hoạt nhầm.
- **Điều chỉnh Độ sáng Đa màn hình (Per-Monitor Brightness)**: Tích hợp sâu với DDC/CI cho màn hình ngoại vi, Apple Native Display Services cho màn hình Retina tích hợp, và cơ chế Software Dimming dự phòng.
- **Bộ đếm Focus Pomodoro**: Bộ đếm tập trung cơ chế đơn điệu (monotonic clock) chia chu kỳ làm việc 25 phút và nghỉ ngắn 5 phút, hiển thị trực quan tiến trình đang chạy trực tiếp trên vành cung radial gauge.
- **Điều khiển Hệ thống Xúc giác**: Điều chỉnh âm lượng tổng kèm bộ chuyển đổi thiết bị âm thanh nhanh, điều chỉnh đèn nền bàn phím (keyboard backlight) và ngăn kéo ứng dụng ẩn (Hidden Dock).
- **Phản hồi Xúc giác và Âm thanh cơ học**: Mô phỏng tiếng click cơ khí và nhịp rung haptic tinh vi khi xoay qua từng nấc thông số.

### 1.2. Tóm Tắt Giá Trị trong Một Câu
> **"Stash mang đến các vành quay điều khiển xúc giác ẩn tại bốn góc màn hình macOS, giúp người dùng điều chỉnh độ sáng đa màn hình, âm lượng và nhịp tập trung Pomodoro tức thì mà không chiếm dụng không gian thị giác hay làm phân tâm công việc."**

### 1.3. Hệ Thống Màu và Phông Chữ hiện tại trong Codebase
- **Hệ màu giao diện**: Sử dụng bảng màu trung tính macOS kết hợp với các dải màu nhấn (accent gradients) mang tính chức năng rõ ràng:
  - Âm lượng (Volume): Xanh dương công nghệ (`#2E9EFF` đến `#0D61F2`).
  - Độ sáng màn hình (Brightness): Hổ phách ấm áp (`#FFC22E` đến `#FF7A00`).
  - Đèn bàn phím (Keyboard): Ngọc lam (Teal/Cyan `#38D9C7` đến `#1A99BF`).
  - Pomodoro Timer: Tím tập trung (Amethyst Violet `#C76BFF` đến `#7A38F2`).
  - Màu thương hiệu trung tâm (Brand Accent): Xanh điện quang Azure (`#0A84FF`) trên nền tối Deep Space Slate (`#16181D`).
- **Phông chữ**: Typography hệ thống Apple San Francisco (SF Pro Display cho tiêu đề và lockup, SF Pro Text cho nội dung, SF Mono cho thông số kỹ thuật và bộ đếm).

---

## 2. Định Vị Thương Hiệu

### 2.1. Tính Cách Thương Hiệu (Brand Personality)
- **Tinh gọn (Lean)**: Không tồn tại bất kỳ chi tiết thừa thãi nào. Không icon màu mè, không giao diện cồng kềnh.
- **Siêu tốc (Instantaneous)**: Thao tác phản hồi dưới 16ms (60-120fps), xuất hiện ngay khi chạm góc màn hình và biến mất êm ái khi rời chuột.
- **Chính xác cơ học (Mechanical Precision)**: Các vạch chia (ticks), kim chỉ, vành chia độ tạo cảm giác như một đồng hồ đo đạc Thụy Sĩ hoặc ống kính máy ảnh Leica.
- **Tinh tế và Không ồn ào (Subtle & Calm)**: Hoạt động như một phần tự nhiên của hệ điều hành macOS, tôn trọng sự tập trung tuyệt đối của người dùng.

### 2.2. Đối Tượng Người Dùng Mục Tiêu (Target Audience)
- Các chuyên gia sáng tạo, kỹ sư phần mềm, nhà thiết kế giao diện, quản lý dự án và người dùng macOS làm việc chuyên sâu từ 8 đến 14 giờ mỗi ngày.
- Người dùng sử dụng thiết lập đa màn hình (MacBook kết hợp từ 1 đến 3 màn hình 4K/5K Studio Display hoặc màn hình chuyên đồ họa ngoại vi).
- Người dùng đề cao chủ nghĩa tối giản, thích sự gọn gàng của Menu Bar, ưu tiên phím tắt và cử chỉ thay vì phải mở từng cửa sổ cài đặt phức tạp.

### 2.3. Điểm Khác Biệt Cốt Lõi (Key Differentiators)
- **Khai thác không gian góc vật lý (Zero-Pixel Invisibility)**: Thay vì chen chúc thêm biểu tượng vào thanh Menu Bar vốn đã quá tải, Stash đặt điểm chạm trực tiếp tại các rìa ngoài màn hình - nơi chuột có thể vung tới mà không cần ngắm bắn tọa độ (Định luật Fitts).
- **Giao diện Cung tròn Radial Dial**: Thay thế thanh trượt (slider) tuyến tính đơn điệu bằng vành tròn xúc giác đồng tâm phát xuất từ đỉnh góc màn hình.

---

## 3. Phân Tích Đối Thủ và Bối Cảnh Trực Quan

Nghiên cứu 8 ứng dụng tiện ích phổ biến nhất trên macOS trong phân khúc Menu Bar, Hot Corner, Quản lý Màn hình và Năng suất:

| STT | Tên Ứng Dụng | Hình khối chủ đạo | Bảng màu chủ đạo | Điểm mạnh | Điểm yếu / Điểm nhàm (Cliché) |
|---|---|---|---|---|---|
| 1 | **MonitorControl** | Màn hình phẳng LCD với mặt trời / loa ở giữa | Trắng, Xám, Xanh dương macOS cổ điển | Biểu đạt trực diện chức năng điều khiển màn hình ngoại vi. | Quá cổ điển, mô tả phần cứng màn hình thô sơ, thiếu tính cao cấp của một phần mềm hiện đại. |
| 2 | **BetterDisplay** | Màn hình cách điệu kèm ma trận điểm ảnh / khung chia độ | Xanh neon đậm trên nền tối carbon | Tạo cảm giác kỹ thuật chuyên nghiệp, phù hợp cho chuyên gia hiển thị. | Ranh giới nhiều chi tiết nhỏ; thu nhỏ ở 16px bị nhòe thành một khối chữ nhật đặc. |
| 3 | **Lunar** | Mặt trăng đa chiều (Moon phases) với bề mặt gồ ghề | Xanh đêm cực quang, Vàng trăng, Bạc | Hình tượng mặt trăng rất đẹp, mang tính thơ và gắn liền với tên gọi. | Không gợi mở bất kỳ liên hệ nào tới góc màn hình, độ sáng hay phần cứng khi nhìn thoáng qua. |
| 4 | **Bartender** | Cốc cocktail với miếng chanh / bình lắc rượu | Màu cam amber, Thủy tinh trong suốt, Vàng | Nhận diện mạnh mẽ, chơi chữ xuất sắc từ cái tên "Bartender". | Phép ẩn dụ đồ uống không liên quan đến hệ thống; không thể mở rộng cho tiện ích chuyên sâu về phần cứng. |
| 5 | **Raycast** | Chữ R góc cạnh / tia sáng góc chéo động học | Đỏ sơn trà (Crimson Red) trên nền đen xám | Nhận diện cực mạnh, đơn giản, tạo cảm giác tốc độ vượt trội. | Thiên hướng launcher / terminal; mang tính gay gắt và nặng về góc nhọn, không gợi sự êm ái của dial. |
| 6 | **Dropover** | Chiếc hộp / khay giấy mở nắp với mũi tên rơi | Xanh lá sáng (Cyan/Lime), Xám ngọc | Thể hiện xuất sắc hành động thả và lưu trữ tạm thời (drop & stash). | Quá thiên về hành động file-drop; dễ gây hiểu lầm rằng app chỉ là nơi lưu file tạm. |
| 7 | **Rectangle** | Khung cửa sổ chữ nhật chia đôi / chia tư | Xanh lam nhạt trên nền trắng ngọc | Đơn giản, rõ ràng cho tính năng chia khung cửa sổ. | Quá đơn điệu, thiếu chiều sâu và không thể hiện được tính chất dynamic của công cụ xúc giác. |
| 8 | **DisplayBuddy** | Biểu tượng mặt trời cách điệu bên trong màn hình | Xanh dương sapphire và Vàng cam | Màu sắc tươi sáng, đồng bộ với phong cách Apple macOS Sonoma. | Biểu tượng mặt trời lồng trong màn hình là lối mòn thiết kế của hầu hết các app monitor trên App Store. |

### Khoảng Trống Nhận Diện (Visual Whitespace) cho Stash
- **Tránh tuyệt đối**: Không vẽ hình màn hình LCD, không vẽ mặt trời/bóng đèn truyền thống, không vẽ cốc nước/hộp lưu trữ kiểu cũ, không dùng dải gradient tím-hồng của phong trào AI phong trào.
- **Khoảng trống độc bản**: Biểu tượng của Stash cần thể hiện được **sự giao thoa giữa "Góc vuông màn hình" (The Corner Anchor) và "Cung tròn vành quay mở rộng" (The Radial Expansion Arc)**. Đây là một hình thể học thuần khiết, có thể đọc được trong 1 giây, đại diện cho cả thao tác chạm góc (hot corner), hành động cất/gợi mở (stash) và vành đo chính xác (radial dial).

---

## 4. Xu Hướng Thiết Kế Icon Apple và Yêu Cầu Kỹ Thuật

Nghiên cứu đối chiếu với tài liệu Apple Developer (Human Interface Guidelines > App Icons; phiên WWDC20 và WWDC24 về Icon Composer và hệ thống Liquid Glass trên macOS Sequoia / macOS 15+):

### 4.1. Nguyên Tắc HIG đang có Hiệu Lực trên macOS
- **Hệ khung hình Squircle (Superellipse)**: Canvas tiêu chuẩn là 1024x1024 pixel. Apple sử dụng đường cong liên tục bậc cao không đứt đoạn góc (continuous curvature).
- **Quy tắc Quan trọng về Masking**: Designer tuyệt đối **không tự vẽ viền bo góc, không xuất canvas mask** vào tệp asset. Hệ thống macOS sẽ tự động cắt mặt nạ squircle và áp dụng độ bóng drop shadow phù hợp với từng bối cảnh (Dock, Finder, App Switcher).
- **Tỷ trọng Thị giác (Visual Weight)**: Vùng an toàn (Safe Zone) nằm trong hình tròn đường kính ~824px hoặc hình vuông bo góc 824x824px tâm giữa canvas 1024px. Dấu hiệu không được tràn ra sát mép 1024px để tránh bị mặt nạ của hệ điều hành cắt phạm.

### 4.2. Hệ Thống Liquid Glass và Icon Composer (WWDC24 / macOS 15+)
- **Kiến trúc phân tầng (Layered Architecture)**: Icon hiện đại không còn là một ảnh bitmap PNG phẳng. Tệp `.icon` bao gồm các tầng độc lập:
  1. `Background Layer`: Màu nền hoặc gradient đồng nhất.
  2. `Midground / Foreground Groups`: Các hình khối vector chính.
  3. `Monochrome / Silhouette Representation`: Bản hình học đơn sắc (chỉ dùng alpha) để hệ thống tính toán độ phản xạ ánh sáng và áp dụng các chế độ hiển thị.
- **Xử lý Hiệu ứng theo thời gian thực (Real-time System Rendering)**:
  - Độ sâu (Depth), phản chiếu (Specular Highlights), khúc xạ (Refraction) và bóng đổ (Dynamic Shadows) đều do nhân đồ họa của macOS tự động sinh ra.
  - **Cấm chỉ định sẵn hiệu ứng**: Không được tự vẽ highlight giả, không vẽ viền sáng nhân tạo (fake glow), không đổ bóng cứng trực tiếp trên vector.
- **4 Chế độ Biến thể Hệ thống Bắt buộc**:
  - `Default (Light)`: Hiển thị đầy đủ màu sắc tiêu chuẩn với chất liệu kính phản xạ tự nhiên.
  - `Dark`: Màu nền hạ tông trầm, chất liệu kính hấp thụ ánh sáng xung quanh.
  - `Clear (Kính trong)`: Nền trở nên trong suốt hoặc bán trong, các khối nổi làm cong mặt ảnh nền phía sau.
  - `Tinted`: Hệ thống phủ một lớp màu đơn sắc tùy chọn của người dùng lên toàn bộ icon; các khối hình học phải giữ được độ tương phản và hình khối rõ ràng.

---

## 5. Chốt Ràng Buộc Thiết Kế cho Stash

1. **Hình học chủ đạo**: Một dấu hiệu hình học có thể nhận diện tức thì ở mọi kích thước từ 1024px xuống 16px.
2. **Kiến trúc Layer chuẩn Apple**: Tách riêng `background.svg`, `foreground.svg`, và `mono.svg`.
3. **Bảng màu kiểm tỏa**:
   - Màu nền: Deep Space Graphite `#14171F` đến Obsidian Navy `#0E1017`.
   - Màu nhấn chủ đạo: Precision Cyan / Azure `#0A84FF` kết hợp phiên bản phản quang Electric Cyan `#00D2FF`.
   - Màu vạch số: Pure Platinum `#FFFFFF` (opacity phân tầng từ 15% đến 90%).
4. **Khả năng mở rộng**:
   - Biểu tượng Menu Bar phải là template image đơn sắc 16x18pt hoạt động hoàn hảo trên cả nền sáng, tối và trong suốt.
   - Lockup logo ngang kết hợp phông chữ SF Pro được vector hóa hoàn toàn.
5. **Quy tắc nghiêm ngặt**:
   - Không emoji.
   - Không chi tiết clip-art hoặc hiệu ứng kính giả.
   - Giấy phép minh bạch cho mọi tài nguyên được sử dụng.
