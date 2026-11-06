# AGENTS.md

**Chuẩn code**: áp dụng toàn bộ mục 1 của tài liệu này (danh sách cấm, kiến trúc tầng, concurrency, persistence, log bằng `os.Logger`, không emoji, chuỗi UI qua String Catalog, accessibility, hiệu năng).

**Design & Brand Identity**:
- Nguồn sự thật (Single Source of Truth) duy nhất của logo và bộ nhận diện thương hiệu là các file vector SVG đặt tại `Design/Logo/source/`.
- Toàn bộ asset phái sinh (bao gồm `MacStash.icns`, `AppIcon.icns`, ảnh Menu Bar template `@1x/@2x/@3x`, ảnh lockup, ảnh mạng xã hội, favicon, nền DMG) bắt buộc phải được sinh tự động và lặp lại thông qua script `scripts/render_icons.sh`.
- Tuyệt đối không chỉnh sửa thủ công hoặc nạp trực tiếp file ảnh nhị phân vào repository mà không qua kịch bản sinh asset.
- Khi có thay đổi về thiết kế, bắt buộc phải cập nhật tài liệu kỹ thuật tại `Design/Logo/`, chạy lại bộ kiểm thử và tái tạo toàn bộ asset catalog.

**Quy trình**: đọc code trước khi sửa; commit nhỏ theo Conventional Commits; mỗi commit build được; sửa lỗi thì có test tái hiện.

**Definition of Done**: một thay đổi chỉ hoàn thành khi:
1. Build sạch, test pass, không thêm warning.
2. Tài liệu `Docs/Guide` (cả vi và en) cập nhật nếu thay đổi ảnh hưởng tính năng, Settings, phím tắt, hành vi hoặc quyền. Tính năng mới thêm mục mới; sửa lỗi cập nhật mục liên quan và phần Xử lý sự cố.
3. `CHANGELOG.md` có dòng mới (Added / Changed / Fixed), version tăng đúng semver (sửa lỗi: patch; tính năng tương thích: minor; thay đổi phá vỡ tương thích: major).
4. DMG build lại bằng `scripts/build_dmg.sh` với version mới; báo đường dẫn và SHA-256. Không build được thì nói rõ lý do, không bỏ qua âm thầm.
5. Báo cáo cuối có mục "Docs đã cập nhật" và "DMG đã build".
Với thay đổi nội bộ không ảnh hưởng người dùng cuối (refactor): vẫn rebuild DMG, ghi "không cần đổi docs".

**Auto-Update & Release Pipeline (Sparkle 2)**:
- Cơ chế cập nhật: Tự động ngầm 1 chạm bằng Sparkle 2. Feed cập nhật là `appcast.xml` ở gốc repo.
- Xác thực Ed25519: Mọi bản zip cập nhật phải được ký mã hóa Ed25519 bằng Apple `CryptoKit` (`Scripts/sign_sparkle_update.swift`). Public key lưu tại `SUPublicEDKey` trong `Info.plist`.
- Bảo mật khóa: Private key lưu trên GitHub Secrets (`SPARKLE_PRIVATE_KEY`) và local `Scripts/.sparkle_keys.json` (được đưa vào `.gitignore`). Tuyệt đối không commit khóa bí mật lên repository.
- Tự động hóa CI/CD: Đẩy tag git `v*` kích hoạt GitHub Actions kiểm thử, biên dịch universal binary, ký gói zip, cập nhật `appcast.xml`, và tạo GitHub Release.

**Không được làm**: tự ý thêm dependency lớn; commit bí mật; sửa phần đang chạy tốt ngoài phạm vi; che lỗi bằng `try?` hoặc timeout cứng; báo "xong" khi chưa kiểm chứng.
