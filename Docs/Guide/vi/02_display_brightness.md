# Điều Chỉnh Độ Sáng Đa Màn Hình

MacStash hỗ trợ điều chỉnh độ sáng độc lập cho từng màn hình, bao gồm màn hình tích hợp trên MacBook và tất cả các màn hình ngoài.

## Các Phương Thức Điều Khiển

### Dịch Vụ Mặc Định (DisplayServices)
Áp dụng cho màn hình Retina tích hợp của Apple. Tương tác trực tiếp qua DisplayServices của hệ điều hành.

### Điều Khiển Phần Cứng DDC/CI
Dành cho các màn hình ngoài tương thích kết nối qua cổng DisplayPort, HDMI hoặc USB-C. Tiêu chuẩn VESA DDC/CI được chạy trên hàng đợi nền bất đồng bộ có cơ chế giới hạn thời gian chờ (timeout) để không làm đơ giao diện.

### Giảm Sáng Bằng Phần Mềm (Software Dimming)
Tự động sử dụng khi màn hình ngoài không phản hồi DDC/CI. Cơ chế điều chỉnh bằng bảng màu gamma giúp hạ thấp độ sáng xuống đến 0% một cách mượt mà.
Khi thoát ứng dụng hoặc trong trường hợp gặp lỗi bất thường, MacStash tự động khôi phục lại bảng màu hệ thống về trạng thái gốc.
