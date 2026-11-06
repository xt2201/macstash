# Stash cho macOS: Khám Phá Khái Niệm (Concept Exploration)

Tài liệu mô tả chi tiết 6 hướng khái niệm biểu tượng, phân tích ưu nhược điểm, bảng chấm điểm định lượng và lý do chọn lựa 2 hướng vào vòng tinh chỉnh.

---

## 1. Danh Sách 6 Hướng Khái Niệm

### 1.1. Khái niệm 1: The Radial Corner Bloom (Góc Nở Vành Cung)
- **Ý tưởng chủ đạo**: Một vành cung tròn xúc giác 1/4 hình tròn nở ra từ đỉnh góc vật lý của màn hình, gồm các rãnh trượt đồng tâm và một phân đoạn độ sáng đang hoạt động rực rỡ.
- **Ẩn dụ thị giác**: Đại diện trực tiếp cho trải nghiệm hot corner của Stash: con trỏ chuột rê chậm tại điểm cực biên góc, mở ra vành quay điều khiển êm ái và mạnh mẽ.
- **Vì sao phù hợp với Stash**:
  - Khớp tuyệt đối với bản chất tính năng chủ đạo: 4 góc màn hình và giao diện quarter-circle dial.
  - Hình thể đơn giản, phân khối đặc-rỗng rõ ràng giúp đọc được ngay lập tức ở mọi cự ly.
- **Rủi ro thị giác**: Nếu vẽ quá nhiều vạch chia nhỏ (ticks), chúng sẽ bị tiêu biến hoặc gây nhiễu ở độ phân giải 16px.
- **Tệp nguồn vector**: `Design/Logo/source/concept_01_radial_bloom.svg`

### 1.2. Khái niệm 2: The Stash Fold / Corner Pocket (Nếp Gấp Cất Góc)
- **Ý tưởng chủ đạo**: Nếp gấp vật lý chéo góc kiểu origami tạo nên một "chiếc túi cất giữ" (stash pocket), hé lộ một vành quay quang học phát sáng bên dưới nếp gấp.
- **Ẩn dụ thị giác**: Hành động "cất giữ và lấy ra nhanh" - giấu các công cụ mạnh mẽ vào góc màn hình để không gian làm việc luôn tinh sạch.
- **Vì sao phù hợp với Stash**:
  - Khai thác triệt để ngữ nghĩa của từ "Stash" (ngăn chứa ẩn, chỗ cất giấu).
  - Tạo cảm giác chiều sâu kiến trúc vật lý độc đáo.
- **Rủi ro thị giác**:
  - Ở kích thước nhỏ (32px và 16px), nếp gấp dễ bị hiểu lầm thành góc trang giấy bị gấp (file/document folding) hoặc một app ghi chú thay vì tiện ích hệ thống.
  - Đường crease cắt chéo làm chia đôi icon gây rối mắt.
- **Tệp nguồn vector**: `Design/Logo/source/concept_02_stash_fold.svg`

### 1.3. Khái niệm 3: The Tri-Arc Monolith (Bộ Ba Cung Hợp Nhất)
- **Ý tưởng chủ đạo**: Ba cung tròn đồng tâm lồng vào nhau với bán kính tăng dần theo tỷ lệ quang học, hợp nhất 3 chức năng cốt lõi: Độ sáng màn hình (cung ngoài), Pomodoro (cung giữa) và Âm lượng (cung lõi).
- **Ẩn dụ thị giác**: Sự hòa hợp của ba dòng chảy công việc trong một nhịp điệu hình học duy nhất.
- **Vì sao phù hợp với Stash**:
  - Tổng hợp đầy đủ ba tính năng lớn của ứng dụng mà không cần vẽ ba icon rời rạc.
- **Rủi ro thị giác**:
  - Sử dụng 3 dải màu khác nhau (Vàng ấm, Tím Pomodoro, Xanh dương) vi phạm nguyên tắc bảng màu tối giản của HIG và yêu cầu chỉ 1 màu nhấn chủ đạo.
  - Ở 16px, 3 đường cong mỏng dễ bị bết dính vào nhau và rất dễ bị nhầm lẫn với biểu tượng sóng Wi-Fi / sóng phát thanh.
- **Tệp nguồn vector**: `Design/Logo/source/concept_03_tri_arc.svg`

### 1.4. Khái niệm 4: The Minimalist Aperture Sector (Vành Cung Khẩu Độ)
- **Ý tưởng chủ đạo**: Một vòng tròn cơ khí tinh xảo kiểu khẩu độ ống kính Leica, trong đó ba phần tư là vành đo titan tĩnh lặng, còn riêng góc một phần tư (góc trên-phải) tách khỏi và phát sáng rực rỡ hướng về góc màn hình.
- **Ẩn dụ thị giác**: Thiết bị quang học đo lường chuẩn xác với một góc hoạt động (active corner sector) sẵn sàng nhận lệnh.
- **Vì sao phù hợp với Stash**:
  - Tinh thần cơ học chính xác (mechanical precision), cao cấp và tinh tế.
  - Hình thể vòng tròn trung tâm giữ cân bằng thị giác trên Dock macOS rất tốt, đồng thời điểm nhấn tách góc thể hiện rõ tính năng corner.
- **Rủi ro thị giác**: Cần căn chỉnh tỷ lệ độ dày của vành tách để đảm bảo không bị coi như một hình "Pac-man" hoặc biểu tượng pie chart phần trăm thông thường.
- **Tệp nguồn vector**: `Design/Logo/source/concept_04_aperture.svg`

### 1.5. Khái niệm 5: The Corner Caliper / L-Gate (Thước Kẹp Góc Vuông)
- **Ý tưởng chủ đạo**: Thước kẹp chữ L vuông góc ôm trọn đỉnh tọa độ (0,0), được cắt ngang bởi một kim chỉ vành quay 45 độ và các nấc thông số cơ khí.
- **Ẩn dụ thị giác**: Thước đo tọa độ và đo đạc phần cứng tỉ mỉ của các kỹ sư phòng thí nghiệm.
- **Vì sao phù hợp với Stash**:
  - Nhấn mạnh tính toán học và tọa độ góc màn hình tuyệt đối.
- **Rủi ro thị giác**:
  - Quá nhiều đường thẳng và vạch chia tỉ mỉ; khi thu nhỏ xuống 32px và 16px thì kim đo và vạch thước bị biến mất hoàn toàn.
  - Tạo cảm giác giống phần mềm CAD hoặc đồ họa kỹ thuật hơn là tiện ích macOS cao cấp.
- **Tệp nguồn vector**: `Design/Logo/source/concept_05_corner_caliper.svg`

### 1.6. Khái niệm 6: The Pulse Dot / Corner Ripple (Sóng Lan Góc Màn Hình)
- **Ý tưởng chủ đạo**: Một hạt nhân phát sáng tại gốc tọa độ phát ra các gợn sóng vành cung tròn lan tỏa êm ái trên toàn bộ bề mặt màn hình.
- **Ẩn dụ thị giác**: Cú chạm nhẹ của chuột tại góc màn hình kích hoạt làn sóng kiểm soát toàn bộ các màn hình kết nối.
- **Vì sao phù hợp với Stash**:
  - Động tác chạm góc và phản hồi haptic lan tỏa.
- **Rủi ro thị giác**:
  - Rất dễ bị nhầm lẫn với sóng radar quân sự, thiết bị dò âm dưới nước (sonar) hoặc cột sóng Bluetooth/Wi-Fi.
  - Thiếu tính biểu trưng cho vành quay (dial) và hành động xoay điều chỉnh.
- **Tệp nguồn vector**: `Design/Logo/source/concept_06_pulse_ripple.svg`

---

## 2. Bảng Chấm Điểm và So Sánh Định Lượng

Thang điểm từ 1 (rất kém) đến 5 (xuất sắc) trên 7 tiêu chí chặt chẽ:
1. **Độc đáo (Uniqueness)**: Tính nguyên bản, không trùng lặp với các app tiện ích khác.
2. **Nhận diện 16px (16px Recognition)**: Còn đọc và nhận ra được ở kích thước nhỏ nhất.
3. **Đơn giản (Simplicity)**: Tối giản hình thể, không chi tiết thừa.
4. **Thích ứng (Adaptability)**: Hoạt động tốt trên Default, Dark, Clear, Tinted và Monochrome.
5. **Ngôn ngữ macOS (macOS HIG)**: Ăn khớp với chiều sâu Liquid Glass và tỷ trọng Dock.
6. **Mở rộng (Scalability)**: Dễ dàng thu hẹp thành Menu Bar template icon và phóng to trên DMG/README.
7. **Khả năng nhớ (Memorability)**: Tạo ấn tượng mạnh mẽ, dễ ghi nhớ trong tâm trí.

| Tiêu chí đánh giá (Thang 1-5) | C1: Radial Bloom | C2: Stash Fold | C3: Tri-Arc | C4: Aperture Sector | C5: Caliper | C6: Pulse Ripple |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| 1. Độc đáo (Uniqueness) | **5** | 4 | 4 | **5** | 3 | 2 |
| 2. Nhận diện ở 16px | **5** | 2 | 3 | **4** | 2 | 4 |
| 3. Độ đơn giản | **4** | 3 | 3 | **5** | 2 | 4 |
| 4. Khả năng thích ứng Liquid Glass | **5** | 3 | 2 | **5** | 3 | 3 |
| 5. Ăn khớp macOS Design | **5** | 3 | 3 | **4** | 3 | 3 |
| 6. Mở rộng Menu Bar & DMG | **5** | 3 | 3 | **5** | 2 | 3 |
| 7. Khả năng nhớ (Memorability) | **5** | 3 | 4 | **4** | 3 | 3 |
| **Tổng điểm (Trên 35)** | **34** | 21 | 22 | **32** | 18 | 22 |

---

## 3. Kết Luận Vòng Lọc và Chọn Hướng Tinh Chỉnh

### 3.1. Hai Hướng được Chọn vào Vòng Tinh Chỉnh (Giai đoạn C)
1. **Hướng 1: Concept 01 - The Radial Corner Bloom (34/35 điểm)**
   - *Lý do*: Điểm số cao nhất toàn diện. Biểu đạt trực diện, thuần khiết và mạnh mẽ nhất bản chất của ứng dụng: góc màn hình và vành quay radial gauge. Ở 16px, khối vành cung đặc và hạt nhân gốc vẫn đọc rõ nét. Khớp hoàn hảo với kiến trúc layer Liquid Glass.
2. **Hướng 2: Concept 04 - The Minimalist Aperture Sector (32/35 điểm)**
   - *Lý do*: Tinh thần dụng cụ cơ học chính xác cực kỳ cao cấp. Sự kết hợp giữa hình thể tròn cổ điển với góc vuông tách rời giúp cân bằng thị giác trên Dock macOS, đồng thời tạo dấu ấn riêng biệt nhờ khối visor phát quang hướng góc.

### 3.2. Bốn Hướng bị Loại và Lý Do Cụ Thể
- **Loại Concept 05 (Caliper - 18 điểm)**: Các đường kim và vạch thước bị nhòe thành một vệt mờ đục ở 16px và 32px. Mang nặng tính CAD kỹ thuật, không phù hợp với sản phẩm người dùng macOS cao cấp.
- **Loại Concept 02 (Stash Fold - 21 điểm)**: Hình ảnh nếp gấp dễ bị hiểu nhầm thành app ghi chú, quản lý tệp tin (Dropover/Finder) hoặc editor thay vì tiện ích vành quay xúc giác.
- **Loại Concept 03 (Tri-Arc - 22 điểm)**: Sử dụng quá nhiều màu sắc gây rối loạn hệ thống Liquid Glass Tinted mode; ba đường cong mỏng dễ bị lầm tưởng là biểu tượng Wi-Fi.
- **Loại Concept 06 (Pulse Ripple - 22 điểm)**: Thiếu tính biểu trưng cho vành quay điều chỉnh; dễ bị nhầm với app radar, sonar hoặc audio spectrum.
