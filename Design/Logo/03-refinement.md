# Stash cho macOS: Tinh Chỉnh và Kiểm Thử (Refinement & Testing)

Tài liệu ghi nhận quá trình tinh chỉnh hình học trên hệ lưới chuẩn, kết quả chạy bộ kiểm thử đa chiều và lý do lựa chọn biểu tượng cuối cùng cho Stash.

---

## 1. Hệ Lưới Hình Học và Kiến Trúc Vector Chuẩn (Geometric Grid System)

Hai hướng phác thảo vào chung kết đã được dựng lại hoàn toàn bằng các phương trình hình học vector với độ chính xác tọa độ tuyệt đối trên canvas 1024x1024 pixel.

### 1.1. Thông Số Lưới Quy Chuẩn (MacStash Modular Grid)
- **Kích thước Canvas gốc**: 1024 x 1024 px.
- **Vùng an toàn (HIG Safe Zone)**: Vòng tròn đường kính 824px tâm tại `(512, 512)`. Các phần tử hình học chính nằm trọn vẹn bên trong ranh giới từ tọa độ 100px đến 924px trên cả hai trục X và Y.
- **Điểm neo góc (Origin Corner Anchor)**: Tọa độ `(160, 864)` tại góc dưới-trái của vùng an toàn (đồng bộ với vị trí vật lý của Hot Corner màn hình macOS).
- **Kiến trúc Phân tầng (Liquid Glass Layer Architecture)**:
  - `layer-background`: Hình chữ nhật 1024x1024 với gradient chuyển tiếp từ Obsidian Slate `#191D26` đến Deep Charcoal `#0D0F14`. Tuyệt đối không có mask bo góc sẵn để hệ thống macOS tự động cắt squircle.
  - `layer-midground`: Vành rãnh trượt 90 độ bán kính ngoài 560px, độ dày 40px cùng các vạch chia độ (detents) cơ học 0, 30, 45, 60, 90 độ.
  - `layer-foreground`: Vành quạt đặc (Solid Radial Sector) bán kính ngoài 560px, bán kính trong 360px, quét góc 60 độ rực rỡ với gradient Cyan/Azure; hạt nhân chốt góc (origin pin) hai tầng tại điểm neo.

---

## 2. Kết Quả Bộ Kiểm Thử Bắt Buộc (Multi-Dimensional Test Suite)

Bộ kiểm thử được thực thi tự động bằng script `scripts/test_icons.py` và ghi nhận toàn bộ kết quả hình ảnh tại thư mục `Design/Logo/exports/tests/`.

### 2.1. Kiểm Thử Kích Thước Đa Tầng (Multi-Scale Pyramid)
Kiểm tra khả năng đọc được của biểu tượng tại các kích thước: 1024, 512, 256, 128, 64, 32, 16 px.

| Kích thước | Hướng 1 (Radial Bloom) | Hướng 2 (Aperture Sector) | Đánh Giá Chuyên Môn |
|---|:---:|:---:|---|
| **1024 px** | Đạt tuyệt đối | Đạt tuyệt đối | Độ sắc nét vector hoàn hảo, gradient mượt mà, chi tiết cơ học rõ nét. |
| **512 px** | Đạt tuyệt đối | Đạt tuyệt đối | Hiển thị chuẩn xác trên màn hình Retina Finder và App Store. |
| **256 px** | Đạt tuyệt đối | Đạt tuyệt đối | Vành cung và vạch detent 45 độ giữ nguyên tính xúc giác. |
| **128 px** | Đạt tuyệt đối | Đạt tuyệt đối | Kích thước mặc định trên Dock macOS; tỷ trọng thị giác cân bằng. |
| **64 px** | Đạt tuyệt đối | Đạt | Vành quạt của Hướng 1 vẫn nổi bật; Hướng 2 bắt đầu hơi mảnh khảnh. |
| **32 px** | Đạt | Đạt (ranh giới) | Hướng 1 giữ được khối đặc hình quạt và hạt nhân gốc rõ ràng. |
| **16 px** | **Đạt xuất sắc** | Không đạt (mờ nhạt) | **Hướng 1 nhận ra được trong 1 giây**: hạt nhân gốc sáng và cung tròn 60 độ tạo thành biểu tượng vành quay độc đáo. Hướng 2 bị đứt quãng và giống vòng xoay buffering bị lỗi. |

### 2.2. Kiểm Thử Nền Bối Cảnh (Background Contrast Matrix)
Kiểm tra hiển thị icon trên 4 bối cảnh giao diện tiêu biểu:
- **Nền Sáng (#F5F5F7)**: Nền tối của icon có viền tự nhiên tách biệt hoàn hảo khỏi nền trắng hệ thống.
- **Nền Tối (#121212)**: Vành nhấn Precision Cyan và chấm pin phát sáng nổi bật trên bối cảnh Dark Mode sâu thẳm.
- **Nền Hình Nền Nhiều Màu (Sonoma Sunset Gradient)**: Khối Obsidian Slate đóng vai trò khay đỡ (container) bảo vệ chi tiết vành quay không bị loạn màu với hình nền desktop.
- **Nền Thang Xám Trung Tính (#808080)**: Tương phản vẫn duy trì ở mức trên 4.5:1.

*Tệp kết quả kiểm thử*: `Design/Logo/exports/tests/refined_01_radial_bloom_test_backgrounds.png`

### 2.3. Kiểm Thử Các Chế Độ Hiển Thị macOS (Appearance Modes)
- **Default Mode**: Màu sắc đầy đủ (Obsidian Slate + Electric Cyan `#00D2FF` + Azure `#0A84FF` + Platinum White `#FFFFFF`).
- **Dark Mode**: Tăng độ sâu, giảm 15% độ chói nền, nhấn mạnh các viền quang học của vành dial.
- **Clear Mode (Kính trong suốt)**: Thử nghiệm với lớp nền kính mờ (frosted glass) và khúc xạ ảnh nền. Các viền vector đường cong tạo ra hiệu ứng uốn cong ánh sáng thực sự ấn tượng.
- **Tinted Mode (Thử nghiệm 4 tông màu bắt buộc)**:
  - *Electric Cyan*: Đồng bộ với màu thương hiệu nguyên bản.
  - *Forest Emerald (#34C759)*: Sử dụng thang xám chuyển đổi (grayscale mapping); hình thể giữ nguyên 100% tính nhận diện.
  - *Amber Gold (#FF9500)*: Tông màu sáng đặc trưng; độ tương phản giữa vùng đặc và vùng rãnh trượt vẫn duy trì trên 7:1.
  - *Coral Crimson (#FF3B30)*: Mạnh mẽ và sắc sảo, thể hiện tốt ở các trạng thái cảnh báo hệ thống.

*Tệp kết quả kiểm thử*: `Design/Logo/exports/tests/refined_01_radial_bloom_test_modes.png`

### 2.4. Mô Phỏng Mù Màu và Độ Tương Phản WCAG 2.1
Sử dụng ma trận biến đổi quang học Brettel/Viénot:
- **Deuteranopia (Mù màu xanh lá / green-weak)**: Màu Cyan chuyển sang tông xanh lam bạc, vẫn tương phản rất mạnh so với nền tối.
- **Protanopia (Mù màu đỏ / red-weak)**: Màu Cyan giữ nguyên tính chất phản quang xanh dương điện tử.
- **Độ Tương Phản Đo Lường Cụ Thể (Contrast Ratio)**:
  - Cyan phản quang (`#00D2FF`) trên nền Obsidian Slate (`#14171F`): **9.95 : 1** (Vượt xa chuẩn WCAG 2.1 AAA là 7.0:1).
  - Azure chủ đạo (`#0A84FF`) trên nền Obsidian Slate (`#14171F`): **4.91 : 1** (Vượt chuẩn WCAG 2.1 AA là 4.5:1).
  - Vạch số Platinum (`#FFFFFF`) trên nền Obsidian Slate (`#14171F`): **17.92 : 1** (Vượt xa chuẩn WCAG 2.1 AAA là 7.0:1).

*Tệp kết quả kiểm thử*: `Design/Logo/exports/tests/refined_01_radial_bloom_test_colorblind.png`

### 2.5. Kiểm Tra Tỷ Trọng Thị Giác trên Dock Mô Phỏng (Dock Simulation)
Thử nghiệm đặt cạnh các ứng dụng hàng ngày trên thanh Dock macOS: **Finder, Safari, Terminal, Raycast, và Stash**:
- **Kết quả**: Biểu tượng Stash không bị quá to (không bị tràn ra khỏi ranh giới 824pt như các app thiết kế lỗi), không bị quá nhỏ (nhờ khối hình quạt đặc có diện tích bề mặt quang học cân đối với mặt cười của Finder và chiếc la bàn của Safari).
- Dấu hiệu gốc không bị lấn át bởi các gradient chói lòa của bên thứ ba, mang lại cảm giác một công cụ tiện ích hệ thống đi kèm macOS chuyên nghiệp và đáng tin cậy.

*Tệp kết quả kiểm thử*: `Design/Logo/exports/tests/dock_simulation_comparison.png`

---

## 3. Quyết Định Cuối Cùng và Chọn Lựa Biểu Tượng Chính Thức

### 3.1. Phương Án Được Chọn làm Biểu Tượng Chính Thức
**Hướng 1: The Radial Corner Bloom (Góc Nở Vành Cung)** được quyết định làm nhận diện thương hiệu và app icon chính thức của Stash.

### 3.2. Lý Do Chọn
1. **Nhận diện 16px vượt trội**: Hình thể khối hình quạt 60 độ và hạt nhân gốc vẫn đọc rõ ngay lập tức ở độ phân giải cực nhỏ 16x16 px, trong khi hướng 2 bị suy hao thành những hạt điểm rời rạc.
2. **Khớp tuyệt đối với Tính năng Sản phẩm**: Không có hình ảnh nào đại diện cho "Hot Corner Dials" và "Stash" trung thực hơn một vành quay mở ra từ góc màn hình.
3. **Khả năng chiết xuất sang Menu Bar Icon**: Vành cung 1/4 hình tròn kèm hạt nhân gốc dễ dàng chuyển đổi thành biểu tượng template đơn sắc 16pt trên Menu Bar với độ nhận diện nhất quán 100%.

### 3.3. Những Gì Đã Bỏ và Lý Do
- **Bỏ Hướng 2 (Aperture Sector)**: Hình thể tròn trung tâm tuy cân xứng nhưng thiếu sự độc bản về mặt vị trí (không gợi được vị trí góc màn hình). Ở 16px và 32px, phần quạt tách rời khiến người dùng liên tưởng tới một vòng quay loading bị đứt đoạn hơn là một dial điều khiển.
- **Loại bỏ các vạch chia độ phụ trên Hướng 1**: Trong bản phác thảo ban đầu có 12 vạch chia nhỏ dọc theo vành; qua kiểm thử thực tế chúng gây nhiễu ở 32px. Bản tinh chỉnh cuối đã lược bỏ các vạch phụ, chỉ giữ lại 5 vạch detent cơ học chính tại 0, 30, 45, 60 và 90 độ.
