# Stash cho macOS: Cơ Sở Thiết Kế và Quy Chuẩn Thương Hiệu (Brand Rationale)

Tài liệu thiết lập cơ sở ý tưởng, hệ thống hình học quy chuẩn, bảng màu chức năng và quy tắc sử dụng biểu tượng Stash.

---

## 1. Ý Tưởng Cốt Lõi và Triết Lý Thiết Kế

Biểu tượng Stash được xây dựng dựa trên triết lý: **"Thao tác Vòng quay Xúc giác tại Góc Tọa độ Vật lý" (Tactile Corner Kinematics)**.

### Ba Yếu Tố Cấu Thành Biểu Tượng:
1. **Điểm neo Gốc (Origin Anchor Pin)**: Tọa độ `(0,0)` tại góc màn hình - nơi theo Định luật Fitts có diện tích chạm vô hạn bởi vì con trỏ chuột không thể vượt ra ngoài rìa màn hình vật lý. Đây là chốt định vị duy nhất giúp người dùng rê chuột không cần ngắm bắn.
2. **Vành Cung Xúc Giác (Radial Dial Sector)**: Khối hình quạt 60 độ phát xuất từ điểm neo góc, mô phỏng chính xác chuyển động xoay nhẹ của cổ tay khi người dùng điều chỉnh độ sáng màn hình, âm lượng hoặc thời gian Pomodoro.
3. **Nấc Cơ Học (Mechanical Detents)**: Các vạch chia độ tại các góc đặc biệt (0, 30, 45, 60, 90 độ) gợi cảm giác về những chiếc đồng hồ tính giờ hoặc ống kính máy ảnh Leica cao cấp.

---

## 2. Hệ Lưới và Hình Học Xây Dựng (Construction Geometry)

Toàn bộ biểu tượng được dựng dựa trên hệ trục tọa độ góc vuông và phương trình hình học cung tròn:

### 2.1. Thông Số Tọa Độ Chuẩn trên Canvas 1024x1024
- **Điểm tâm góc (Anchor Center)**: `P0 = (160, 864)` (góc dưới-trái của vùng an toàn macOS).
- **Bán kính Vành quạt Chính (Active Sector)**:
  - Bán kính ngoài: `R_outer = 560 px` (tương đương 54.7% kích thước canvas).
  - Bán kính trong: `R_inner = 360 px` (tương đương 35.1% kích thước canvas).
  - Độ dày thanh quạt: `Delta_R = 200 px`.
  - Góc quét: 60 độ từ trục thẳng đứng (từ góc 90 độ đến góc 30 độ trên hệ trục tọa độ cực).
- **Vành Rãnh Trượt Inactive (Track Channel)**:
  - Bán kính tâm: `560 px`, độ dày nét stroke: `40 px`.
  - Quét trọn vẹn 90 độ từ trục thẳng đứng `(160, 304)` đến trục nằm ngang `(720, 864)`.
- **Hạt Nhân Gốc (Anchor Node)**:
  - Vành ngoài: Bán kính `120 px`, viền stroke `16 px`.
  - Vành lõi quang: Bán kính `56 px`.
  - Điểm sáng tâm: Bán kính `24 px`.
- **Điểm chỉ 45 độ (Focal Detent Pip)**:
  - Tọa độ tâm: `(485, 539)`.
  - Bán kính ngoài: `28 px` (Platinum White).
  - Bán kính lõi: `14 px` (Azure Core).

---

## 3. Bảng Màu Chức Năng và Giá Trị Quy Chuẩn

Bảng màu được kiểm tỏa chặt chẽ, sử dụng không gian màu tiêu chuẩn Display P3 và sRGB:

| Màu sắc | Mã Hex | RGB (sRGB) | Tỷ Lệ Sử Dụng | Vai Trò và Ý Nghĩa |
|---|---|---|:---:|---|
| **Obsidian Slate** | `#191D26` | `(25, 29, 38)` | 55% | Màu nền trên của gradient hộp chứa (container); tạo chiều sâu không gian tối macOS. |
| **Deep Charcoal** | `#0D0F14` | `(13, 15, 20)` | 30% | Màu nền dưới của gradient hộp chứa; tạo cảm giác bề mặt kim loại anot hóa (anodized metal). |
| **Precision Cyan** | `#00D2FF` | `(0, 210, 255)` | 8% | Màu phản quang phía trước của vành quay active; độ tương phản cao nhất (9.95:1) đảm bảo nhận diện ở 16px. |
| **Electric Azure** | `#0A84FF` | `(10, 132, 255)` | 5% | Màu nhấn hệ thống Apple macOS; kết nối tự nhiên với hệ sinh thái giao diện gốc. |
| **Platinum White** | `#FFFFFF` | `(255, 255, 255)` | 2% | Màu các vạch chia độ cơ học và điểm sáng lõi; độ tương phản tối đa (17.92:1). |

---

## 4. Quy Tắc Sử Dụng Biểu Tượng (Brand Usage Guidelines)

### 4.1. Khoảng Trống An Toàn (Clear Space)
- **Quy tắc `X`**: Khoảng trống an toàn xung quanh biểu tượng hoặc logo lockup được xác định bằng chiều rộng của hạt nhân gốc (Anchor Pin diameter = `X = 112 px` trên canvas 1024, tương đương khoảng 12% tổng chiều rộng).
- Không được để bất kỳ văn bản, thành phần đồ họa hay ranh giới khung cửa sổ nào xâm phạm vào vùng an toàn `X` này.

### 4.2. Kích Thước Tối Thiểu (Minimum Sizing)
- **Dấu hiệu độc lập (Standalone Mark)**: Kích thước hiển thị tối thiểu là **16 x 16 px** (hoặc 16 x 16 pt trên màn hình Retina). Ở kích thước này, các vạch chia độ siêu nhỏ tự động ẩn đi, chỉ giữ lại vành quạt đặc và hạt nhân gốc.
- **Lockup Logo Ngang (Mark + Wordmark "Stash")**: Kích thước hiển thị tối thiểu là **24 pt** về chiều cao (chiều dài tương ứng khoảng 96 pt) để đảm bảo chữ "Stash" luôn đọc rõ.

### 4.3. Các Điều Tuyệt Đối Cấm (Do-Nots)
1. **Cấm xoay hướng biểu tượng**: Không được xoay góc biểu tượng sang các hướng khác trong logo chính thức. Điểm neo phải luôn nằm ở góc phù hợp với quy chuẩn đã được phê duyệt.
2. **Cấm bóp méo tỷ lệ (No Distort / Stretch)**: Phải luôn phóng to / thu nhỏ đồng tỷ lệ 1:1.
3. **Cấm tự vẽ thêm bóng đổ hoặc viền kính giả**: Hệ thống macOS Liquid Glass và Icon Composer sẽ tự động sinh bóng đổ quang học. Không thêm drop shadow thủ công vào tệp SVG.
4. **Cấm đổi màu tùy tiện**: Không sử dụng các dải gradient cầu vồng hoặc gradient tím-hồng ngoài quy chuẩn bảng màu đã nêu tại Mục 3.
5. **Cấm đặt biểu tượng trên nền khó đọc**: Không đặt biểu tượng không hộp chứa trực tiếp trên các hình nền có họa tiết phức tạp hoặc nền có độ tương phản dưới 4.5:1.
