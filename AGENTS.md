# AGENTS.md

**Chuẩn code**: áp dụng toàn bộ mục 1 của tài liệu này (danh sách cấm, kiến trúc tầng, concurrency, persistence, log bằng `os.Logger`, không emoji, chuỗi UI qua String Catalog, accessibility, hiệu năng).

**Quy trình**: đọc code trước khi sửa; commit nhỏ theo Conventional Commits; mỗi commit build được; sửa lỗi thì có test tái hiện.

**Definition of Done**: một thay đổi chỉ hoàn thành khi:
1. Build sạch, test pass, không thêm warning.
2. Tài liệu `Docs/Guide` (cả vi và en) cập nhật nếu thay đổi ảnh hưởng tính năng, Settings, phím tắt, hành vi hoặc quyền. Tính năng mới thêm mục mới; sửa lỗi cập nhật mục liên quan và phần Xử lý sự cố.
3. `CHANGELOG.md` có dòng mới (Added / Changed / Fixed), version tăng đúng semver (sửa lỗi: patch; tính năng tương thích: minor; thay đổi phá vỡ tương thích: major).
4. DMG build lại bằng `scripts/build_dmg.sh` với version mới; báo đường dẫn và SHA-256. Không build được thì nói rõ lý do, không bỏ qua âm thầm.
5. Báo cáo cuối có mục "Docs đã cập nhật" và "DMG đã build".
Với thay đổi nội bộ không ảnh hưởng người dùng cuối (refactor): vẫn rebuild DMG, ghi "không cần đổi docs".

**Không được làm**: tự ý thêm dependency lớn; commit bí mật; sửa phần đang chạy tốt ngoài phạm vi; che lỗi bằng `try?` hoặc timeout cứng; báo "xong" khi chưa kiểm chứng.
