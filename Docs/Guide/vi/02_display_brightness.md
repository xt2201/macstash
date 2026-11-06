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

## Điều Khiển Độ Sáng Trực Tiếp Trên Menu Bar

Khi làm việc với nhiều màn hình, menu popover của MacStash hiển thị riêng từng thanh trượt độ sáng cho từng màn hình đang hoạt động. Mỗi thanh trượt đều hiển thị rõ tên thiết bị và biểu tượng phân loại (màn hình tích hợp MacBook hoặc màn hình rời bên ngoài).

## Lưu Trữ Cấu Hình Màn Hình Tự Động

Mọi tùy chỉnh độ sáng và phương thức điều khiển được tự động lưu theo mã định danh UUID của từng màn hình trong cấu hình người dùng. Khi bạn rút dây cắm và kết nối lại màn hình ngoài, MacStash sẽ tự động khôi phục mức sáng và hồ sơ điều khiển trước đó.
