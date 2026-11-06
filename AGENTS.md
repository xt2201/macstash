# AGENTS.md

**Chuẩn code**: áp dụng toàn bộ mục 1 của tài liệu này (danh sách cấm, kiến trúc tầng, concurrency, persistence, log bằng `os.Logger`, không emoji, chuỗi UI qua String Catalog, accessibility, hiệu năng).

**Design & Brand Identity**:
- Nguồn sự thật (Single Source of Truth) duy nhất của logo và bộ nhận diện thương hiệu là các file vector SVG đặt tại `Design/Logo/source/`.
- Toàn bộ asset phái sinh (bao gồm `MacStash.icns`, `AppIcon.icns`, ảnh Menu Bar template `@1x/@2x/@3x`, ảnh lockup, ảnh mạng xã hội, favicon, nền DMG) bắt buộc phải được sinh tự động và lặp lại thông qua script `scripts/render_icons.sh` sử dụng công cụ kết xuất Apple AppKit Swift thuần túy (`Scripts/render_svg.swift`).
- Tuyệt đối không chỉnh sửa thủ công hoặc nạp trực tiếp file ảnh nhị phân vào repository mà không qua kịch bản sinh asset.
- Khi có thay đổi về thiết kế, bắt buộc phải cập nhật tài liệu kỹ thuật tại `Design/Logo/`, chạy lại bộ kiểm thử và tái tạo toàn bộ asset catalog.

**Quản lý Phiên bản & Single Source of Truth (Versioning)**:
- Nguồn sự thật duy nhất của phiên bản là file `VERSION` ở thư mục gốc của repository (tuân thủ Semantic Versioning, ví dụ `2.3.5`).
- Khi tăng phiên bản, bắt buộc phải đồng bộ chuẩn xác toàn bộ 6 vị trí:
  1. `VERSION`: Cập nhật số phiên bản mới nhất.
  2. `Scripts/Info.plist`: Cập nhật `CFBundleShortVersionString` (ví dụ `2.3.5`) và `CFBundleVersion` (ví dụ `235`).
  3. `CHANGELOG.md`: Thêm mục mới `## [X.Y.Z] - YYYY-MM-DD` với các tiêu đề Added / Changed / Fixed.
  4. `Docs/Guide/en/08_whats_new.md` và `Docs/Guide/vi/08_whats_new.md`: Cập nhật bài viết phiên bản mới đối xứng cả hai ngôn ngữ (tuyệt đối không chứa emoji).
  5. `appcast.xml`: Tái tạo tự động thông qua `Scripts/build_dmg.sh` kèm chữ ký Ed25519 và kích thước file zip thực tế.
  6. `README.md`: Cập nhật huy hiệu phiên bản và đường dẫn tải DMG.
- **Tuyệt đối cấm hardcode số phiên bản trong UI hoặc String Catalog**:
  - Không bao giờ ghi cứng chuỗi phiên bản (như `"Version 2.1.1"`, `"Phiên bản 2.1.1"`) vào `LocalizationService.swift`, `Localizable.xcstrings`, `AboutTab.swift` hay bất kỳ view SwiftUI nào.
  - Mọi chuỗi hiển thị phiên bản trên giao diện bắt buộc phải lấy động từ `Bundle.main.infoDictionary?["CFBundleShortVersionString"]` (fallback qua `Defaults.appVersion`).
  - Mọi thay đổi phiên bản bắt buộc phải pass bộ kiểm thử tự động `VersionConsistencyTests` trong `make test`.

**Độ ổn định của Kịch bản Build & CI/CD**:
- Các kịch bản đóng gói và dựng tài nguyên (`Scripts/render_icons.sh`, `Scripts/build_dmg.sh`) tuyệt đối không được phụ thuộc cứng vào các công cụ Python/pip tùy chọn bên ngoài (như `weasyprint`). Các tác vụ phụ trợ (như sinh vector PDF) phải có cơ chế bẫy lỗi an toàn (`try/except`) để việc biên dịch ứng dụng và đóng gói DMG trên môi trường máy chủ CI sạch (GitHub Actions runner `macos-latest`) luôn chạy thành công 100%.

**Quy trình**: đọc code trước khi sửa; commit nhỏ theo Conventional Commits; mỗi commit build được; sửa lỗi thì có test tái hiện.

**Definition of Done**: một thay đổi chỉ hoàn thành khi:
1. Build sạch, test pass, không thêm warning (`make test`). Bộ kiểm thử `VersionConsistencyTests` và `DocumentationIntegrityTests` phải pass 100%.
2. Tài liệu `Docs/Guide` (cả vi và en) cập nhật nếu thay đổi ảnh hưởng tính năng, Settings, phím tắt, hành vi hoặc quyền. Tính năng mới thêm mục mới; sửa lỗi cập nhật mục liên quan và phần Xử lý sự cố.
3. `CHANGELOG.md` có dòng mới (Added / Changed / Fixed), version tăng đúng semver (sửa lỗi: patch; tính năng tương thích: minor; thay đổi phá vỡ tương thích: major).
4. DMG và update ZIP build lại bằng `scripts/build_dmg.sh` với version mới; báo đường dẫn và SHA-256. Không build được thì nói rõ lý do, không bỏ qua âm thầm.
5. Commit code theo chuẩn Conventional Commits.
6. Luôn tạo git tag phiên bản tương ứng (ví dụ `git tag v<version>`) và đẩy cả branch cùng tag lên remote repository (`git push origin <branch> && git push origin v<version>`). Tuyệt đối không bao giờ để lại commit hoặc tag dở dang chỉ ở local mà không push lên remote.
7. **Kiểm tra phát hành & CI sau khi Push**: Sau khi push tag, bắt buộc phải kiểm tra trạng thái của GitHub Actions workflow (`gh run list --limit 1` hoặc `gh run view`) và đảm bảo GitHub Release tồn tại (`gh release view v<version>`), file ZIP cập nhật có thể tải được (HTTP 200/302, không 404). Nếu CI runner bị lỗi, phải khắc phục ngay lập tức.
8. Báo cáo cuối có mục "Docs đã cập nhật", "DMG đã build", và "Git tag/commit đã push".
Với thay đổi nội bộ không ảnh hưởng người dùng cuối (refactor): vẫn rebuild DMG, tạo tag và push đầy đủ, ghi "không cần đổi docs".

**Auto-Update & Release Pipeline (Sparkle 2)**:
- Cơ chế cập nhật: Tự động ngầm 1 chạm bằng Sparkle 2. Feed cập nhật là `appcast.xml` ở gốc repo.
- Xác thực Ed25519: Mọi bản zip cập nhật phải được ký mã hóa Ed25519 bằng Apple `CryptoKit` (`Scripts/sign_sparkle_update.swift`). Public key lưu tại `SUPublicEDKey` trong `Info.plist`.
- Bảo mật khóa: Private key lưu trên GitHub Secrets (`SPARKLE_PRIVATE_KEY`) và local `Scripts/.sparkle_keys.json` (được đưa vào `.gitignore`). Tuyệt đối không commit khóa bí mật lên repository.
- Tự động hóa CI/CD & Bắt buộc Push Tag: Mỗi khi hoàn thành phiên bản hoặc sửa đổi tính năng, agent bắt buộc phải commit, tạo git tag `v<version>` và push lên remote (`git push origin <branch> && git push origin v<version>`). Hành động này sẽ kích hoạt GitHub Actions kiểm thử, biên dịch universal binary, ký gói zip, cập nhật `appcast.xml`, và tạo GitHub Release tự động.

**Không được làm**: tự ý thêm dependency lớn; commit bí mật; sửa phần đang chạy tốt ngoài phạm vi; che lỗi bằng `try?` hoặc timeout cứng; báo "xong" khi chưa kiểm chứng; hardcode số phiên bản trong chuỗi giao diện.
