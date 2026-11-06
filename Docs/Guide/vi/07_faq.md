# Câu Hỏi Thường Gặp (FAQ)

## Câu Hỏi Chung

### MacStash có gây tốn CPU khi chạy ngầm không?
Không. Khi các vòng xoay ở trạng thái ẩn, MacStash không tiêu thụ CPU. Ứng dụng không sử dụng timer quét lặp hoặc tiến trình chạy nền vô ích.

### Tôi có thể bấm các nút nằm ở góc của app khác không?
Có. Khi vòng xoay đang ẩn, hit-testing luôn trả về nil, cho phép con trỏ và thao tác click xuyên qua trực tiếp xuống cửa sổ bên dưới.

### Cơ chế nhận diện góc ngoài trên nhiều màn hình hoạt động như thế nào?
MacStash tính toán hình học không gian desktop theo thời gian thực. Khi hai màn hình tiếp giáp nhau tại một đường biên chung, ứng dụng sẽ bỏ qua và chỉ kích hoạt tại các góc ngoài biên vật lý thật sự.

### Chuyện gì xảy ra nếu màn hình ngoài không hỗ trợ DDC/CI?
MacStash sẽ tự động chuyển sang cơ chế Giảm Sáng Bằng Phần Mềm (Software Dimming) thông qua bảng màu gamma. Khi thoát ứng dụng, bảng màu sẽ được phục hồi về trạng thái ban đầu.
