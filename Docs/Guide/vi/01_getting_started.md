# Hướng Dẫn Bắt Đầu MacStash

MacStash cung cấp các vòng xoay điều khiển hình góc phần tư xuất hiện tinh tế tại bốn góc vật lý của màn hình macOS.

## Khái Niệm Cốt Lõi

MacStash được thiết kế để duy trì trạng thái ẩn hoàn toàn và không tiêu tốn tài nguyên cho đến khi người dùng cần thao tác. Khi di chuột vào góc kích hoạt và dừng lại trong giây lát, vòng xoay tương ứng sẽ xuất hiện mượt mà.

### Bốn Góc Vật Lý
1. **Góc Trên - Trái**: Mặc định điều chỉnh đèn bàn phím (Keyboard Backlight).
2. **Góc Trên - Phải**: Mặc định điều chỉnh độ sáng màn hình (Display Brightness).
3. **Góc Dưới - Trái**: Mặc định đồng hồ tập trung Pomodoro.
4. **Góc Dưới - Phải**: Mặc định âm lượng loa tổng (Master Volume).

### Phân Biệt Góc Ngoài Biên và Điểm Tiếp Giáp Màn Hình
Trên cấu hình nhiều màn hình, MacStash sử dụng thuật toán hình học để chỉ nhận diện góc ngoài biên thực sự của toàn bộ không gian desktop. Khi con trỏ chuột di chuyển qua lại giữa các màn hình tại các đường biên tiếp giáp bên trong, MacStash sẽ không chặn chuột và không kích hoạt nhầm.

### Thanh Trượt Cạnh Màn Hình (Edge Sliders)
Bên cạnh bốn góc xoay, MacStash cung cấp thanh trượt tiện ích tại mép ngoài cùng bên phải của màn hình. Khi rê chuột vào mép phải, một thanh trượt thanh lịch sẽ trượt ra nhẹ nhàng, cho phép tinh chỉnh nhanh âm lượng hoặc độ sáng mà không cần di chuyển chuột xuống góc.

## Biểu Tượng Nhận Diện và Menu Bar

MacStash sử dụng bộ nhận diện thương hiệu **Radial Corner Bloom (Góc Nở Vành Cung)**: gồm một hạt nhân tọa độ neo tại góc màn hình vật lý kết hợp cùng vành quay quang học 1/4 hình tròn.

### Tiện Ích Nhanh Trên Menu Bar
- **Điều khiển âm thanh**: Nhấp vào biểu tượng loa để bật hoặc tắt tiếng tức thì (Mute/Unmute), hoặc chọn thiết bị đầu ra từ danh sách thả xuống.
- **Độ sáng đa màn hình**: Hiển thị thanh trượt độ sáng độc lập cho từng màn hình kèm tên và biểu tượng thiết bị khi kết nối nhiều màn hình.
- **Đồng hồ Pomodoro**: Huy hiệu đếm ngược thời gian thực trên thanh trạng thái kèm các nút Bắt đầu, Tạm dừng, Bỏ qua và Đặt lại trong menu popover.

### Các Trạng Thái Trên Menu Bar
- **Trạng thái Nghỉ (Idle)**: Vành cung 1/4 hình tròn đơn sắc thanh lịch với chấm neo góc, ăn khớp hoàn hảo với độ dày của các biểu tượng hệ thống Apple.
- **Trạng thái Hoạt động (Active / Pomodoro)**: Vành cung tự động chuyển sang dạng hình quạt đặc, giúp người dùng nhận biết ngay lập tức phiên tập trung đang chạy mà không cần mở popover.
- **Tự động Thích ứng Giao diện**: Biểu tượng sử dụng cơ chế template image, tự động chuyển đổi giữa màu trắng và đen theo chế độ Light Mode, Dark Mode hoặc màn hình hình nền trong suốt.
