# Stash cho macOS: Danh Mục Giấy Phép và Nguồn Tài Nguyên

Tài liệu ghi nhận nguồn gốc, bản quyền và giấy phép sử dụng của toàn bộ tài nguyên được sử dụng trong quá trình thiết kế logo và bộ nhận diện Stash.

---

## 1. Typography và Wordmark
- **Phông chữ gốc**: Apple San Francisco (SF Pro Display, SF Pro Text, SF Mono).
  - **Nhà cung cấp**: Apple Inc.
  - **Giấy phép sử dụng**: Apple System Font License (cho phép sử dụng để thiết kế giao diện, biểu tượng và trải nghiệm cho các sản phẩm hoạt động trên hệ sinh thái macOS/iOS/iPadOS).
  - **Quy trình xử lý kỹ thuật**: Toàn bộ các chữ cái trong wordmark ("Stash") và các tài liệu vector đều được chuyển đổi trực tiếp thành đường cong Bézier độc lập (Vector Outlines / Paths). Không có tệp phông chữ nhân bản `.ttf` hay `.otf` bên ngoài nào được nhúng trái phép vào bộ cài đặt.

---

## 2. Hệ Lưới và Thông Số Mẫu (Templates & Grid Specifications)
- **Hệ thống lưới macOS App Icon Grid**:
  - **Nguồn tham chiếu**: Apple Design Resources (macOS Human Interface Guidelines).
  - **Thông số áp dụng**: Canvas 1024x1024 pixel, vùng an toàn trung tâm bán kính 412pt (đường kính 824pt), hệ trục tọa độ cân bằng thị giác trên macOS Sequoia / Sonoma.
  - **Kiến trúc Liquid Glass & Icon Composer**: Tuân thủ tài liệu kỹ thuật WWDC20 và WWDC24 của Apple Developer về cấu trúc layered `.icon`.

---

## 3. Tài Nguyên Vector và Đồ Họa (Graphic Assets)
- **Tính nguyên bản (Originality)**:
  - 100% các tệp vector SVG (gồm 6 hướng phác thảo, 2 hướng tinh chỉnh và bộ layer thành phẩm) được dựng hình học từ đầu bằng các phép toán vector chính xác (cung tròn, đoạn thẳng, tọa độ số thực).
  - Không sử dụng bất kỳ clip-art, hình ảnh stock, vector thư viện từ bên thứ ba (như Freepik, Shutterstock, The Noun Project, Iconfinder).
  - Không sử dụng emoji trong bất kỳ tệp thiết kế, đoạn mã nguồn hay tài liệu hướng dẫn nào.

---

## 4. Công Cụ Phần Mềm và Script Tự Động Hóa
- **Engine sinh asset**:
  - `sips` (macOS built-in Scriptable Image Processing System).
  - `qlmanage` (macOS built-in QuickLook Server thumbnail rendering engine).
  - `iconutil` (macOS Developer Tools CLI cho việc tạo tệp `.icns`).
  - Python 3 (các thư viện hệ thống tiêu chuẩn dùng để kiểm tra và xử lý dữ liệu).
