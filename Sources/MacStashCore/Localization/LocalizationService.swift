import Foundation

public enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case system = "system"
    case vietnamese = "vi"
    case english = "en"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .system: return "System Default"
        case .vietnamese: return "Tiếng Việt"
        case .english: return "English"
        }
    }

    public static func resolveEffectiveLanguage(from languageCode: String, preferredLanguages: [String] = Locale.preferredLanguages) -> String {
        if languageCode == "vi" {
            return "vi"
        } else if languageCode == "en" {
            return "en"
        } else {
            let preferred = preferredLanguages.first?.lowercased() ?? "en"
            return preferred.starts(with: "vi") ? "vi" : "en"
        }
    }
}

public final class LocalizationService: @unchecked Sendable {
    public static let shared = LocalizationService()

    private let lock = NSLock()
    private var _currentLanguage: AppLanguage = .system
    private var _effectiveLanguage: String = "en"

    public init() {
        self._effectiveLanguage = AppLanguage.resolveEffectiveLanguage(from: "system")
    }

    public var currentLanguage: AppLanguage {
        lock.lock()
        defer { lock.unlock() }
        return _currentLanguage
    }

    public var effectiveLanguage: String {
        lock.lock()
        defer { lock.unlock() }
        return _effectiveLanguage
    }

    public func setLanguage(_ language: AppLanguage) {
        lock.lock()
        _currentLanguage = language
        _effectiveLanguage = AppLanguage.resolveEffectiveLanguage(from: language.rawValue)
        lock.unlock()

        UserDefaults.standard.set([_effectiveLanguage], forKey: "AppleLanguages")
    }

    public func localized(_ key: String, language: String? = nil) -> String {
        let lang = language ?? effectiveLanguage
        if let translation = Self.catalog[lang]?[key] {
            return translation
        }
        if let fallback = Self.catalog["en"]?[key] {
            return fallback
        }
        return key
    }

    public static var allKeys: [String] {
        return Array((catalog["en"] ?? [:]).keys).sorted()
    }

    public static let catalog: [String: [String: String]] = [
        "en": [
            // Tabs
            "tab.general": "General",
            "tab.hotCorners": "Hot Corners",
            "tab.appearance": "Appearance",
            "tab.displays": "Displays",
            "tab.pomodoro": "Pomodoro",
            "tab.shortcuts": "Shortcuts",
            "tab.about": "About / Advanced",

            // General Tab
            "general.masterControls": "Master Controls",
            "general.enableMacStash": "Enable MacStash Controls",
            "general.showMenuBarIcon": "Show Icon in Menu Bar",
            "general.launchAtLogin": "Launch at Login",
            "general.languageLocale": "Language & Locale",
            "general.interfaceLanguage": "Interface Language",
            "general.systemDefault": "System Default",
            "general.vietnamese": "Tiếng Việt",
            "general.english": "English",
            "general.languageHint": "Changes apply dynamically to all labels and guides.",
            "general.systemPermissions": "System Permissions",
            "general.accessibility": "Accessibility",
            "general.accessibilityDesc": "Required to track cursor and trigger hot corners",
            "general.inputMonitoring": "Input Monitoring",
            "general.inputMonitoringDesc": "Required to detect scroll and modifier keys during adjustments",
            "general.notifications": "Notifications",
            "general.notificationsDesc": "Required to post banner alerts when Pomodoro completes",
            "general.granted": "Granted",
            "general.notGranted": "Not Granted",
            "general.grantPermission": "Grant Permission",
            "general.openSettings": "Open Settings",
            "general.factoryReset": "Reset to Factory Defaults",
            "general.resetDesc": "Restores all settings, profiles, and corner assignments to default values.",
            "general.resetButton": "Reset All Settings...",
            "general.resetAlertTitle": "Reset All Settings?",
            "general.resetAlertMessage": "This will restore all corner assignments, sensitivity thresholds, and display profiles to original defaults. This action cannot be undone.",
            "general.resetConfirm": "Reset All",
            "general.cancel": "Cancel",

            // Hot Corners Tab
            "corners.cornerAssignment": "Corner Assignment",
            "corners.topLeft": "Top-Left Corner",
            "corners.topRight": "Top-Right Corner",
            "corners.bottomLeft": "Bottom-Left Corner",
            "corners.bottomRight": "Bottom-Right Corner",
            "corners.triggerPrecision": "Trigger Precision & Timing",
            "corners.hitZoneSensitivity": "Hit-Zone Sensitivity:",
            "corners.hitZoneHint": "Smaller values require moving closer to the extreme edge, preventing accidental triggers.",
            "corners.dwellDelay": "Dwell Activation Delay:",
            "corners.dwellDelayHint": "Cursor must remain within hit zone for this duration before the dial blooms.",
            "corners.autoDismissDelay": "Auto-Dismiss Grace Delay:",
            "corners.autoDismissHint": "Time allowed after exiting dial perimeter before the overlay disappears.",
            "corners.suppressionRules": "Suppression Rules",
            "corners.suppressDragging": "Suppress dials while dragging files or windows",
            "corners.suppressFullScreen": "Suppress dials when frontmost app is in Full Screen",
            "corners.excludedApps": "Excluded Applications",
            "corners.excludedAppsDesc": "Corner dials will never activate while these applications are frontmost:",
            "corners.bundleIDPlaceholder": "com.example.app (Bundle ID)",
            "corners.add": "Add",
            "corners.noExcludedApps": "No excluded applications configured.",
            "corners.action.volume": "Volume",
            "corners.action.brightness": "Brightness",
            "corners.action.backlight": "Keyboard Backlight",
            "corners.action.pomodoro": "Pomodoro Timer",
            "corners.action.none": "None (Disabled)",

            // Appearance Tab
            "appearance.geometryStyling": "Dial Geometry & Styling",
            "appearance.dialRadius": "Dial Arc Radius:",
            "appearance.glassOpacity": "Background Glass Opacity:",
            "appearance.theme": "Appearance Theme:",
            "appearance.themeMatchSystem": "Match System",
            "appearance.themeLight": "Light",
            "appearance.themeDark": "Dark",
            "appearance.animationMotion": "Animation & Motion",
            "appearance.animationSpeed": "Animation Duration:",
            "appearance.reduceMotion": "Respect System Reduce Motion",
            "appearance.reduceMotionHint": "Eliminates scaling transitions for users sensitive to motion.",
            "appearance.tactileAudio": "Tactile & Audio Feedback",
            "appearance.soundFx": "Mechanical Sound Effects",
            "appearance.soundVolume": "Sound Volume:",
            "appearance.trackpadHaptics": "Trackpad Haptic Detents",
            "appearance.hapticIntensity": "Haptic Intensity:",
            "appearance.hapticLight": "Light",
            "appearance.hapticMedium": "Medium",
            "appearance.hapticStrong": "Strong",

            // Displays Tab
            "displays.connectedDisplays": "Connected Displays",
            "displays.scanning": "Scanning for connected displays...",
            "displays.precision": "Brightness Adjustment Precision",
            "displays.stepSize": "Adjustment Step Size:",
            "displays.stepUltraFine": "1% (Ultra Fine)",
            "displays.stepBalanced": "5% (Balanced)",
            "displays.stepCoarse": "10% (Coarse)",
            "displays.minClamp": "Minimum Hardware Clamp:",
            "displays.minClampHint": "Prevents backlight turning completely black when dialing to minimum.",
            "displays.method": "Method:",
            "displays.methodAuto": "Auto Detect",
            "displays.methodDDC": "Hardware DDC/CI",
            "displays.methodSoftware": "Software Dimming",
            "displays.methodBuiltIn": "Native DisplayServices",
            "displays.builtInDisplay": "Built-in Retina Display",
            "displays.externalDisplay": "External Monitor",
            "displays.brightnessTest": "Brightness Test:",

            // Pomodoro Tab
            "pomodoro.intervalDurations": "Interval Durations",
            "pomodoro.focusDuration": "Focus Session Duration:",
            "pomodoro.shortBreakDuration": "Short Break Duration:",
            "pomodoro.longBreakDuration": "Long Break Duration:",
            "pomodoro.roundsBeforeLong": "Rounds Before Long Break:",
            "pomodoro.rounds": "rounds",
            "pomodoro.automationAlerts": "Automation & Alerts",
            "pomodoro.autoStartBreak": "Automatically start break when focus ends",
            "pomodoro.playChime": "Play chime alert when timer completes",
            "pomodoro.currentState": "Current Pomodoro State",
            "pomodoro.timeRemaining": "Time Remaining:",
            "pomodoro.statusRunning": "Active Focus Session",
            "pomodoro.statusPaused": "Paused / Idle",
            "pomodoro.btnPause": "Pause Timer",
            "pomodoro.btnStart": "Start Timer",
            "pomodoro.btnReset": "Reset Timer",
            "pomodoro.btnSkip": "Skip",
            "pomodoro.modeFocus": "Focus",
            "pomodoro.modeShortBreak": "Short Break",
            "pomodoro.modeLongBreak": "Long Break",
            "pomodoro.roundIndicator": "Round %d of %d",
            "pomodoro.minutesUnit": "min",
            "pomodoro.notifyBreakTitle": "Pomodoro Completed",
            "pomodoro.notifyBreakBody": "Time for a well-deserved break!",
            "pomodoro.notifyFocusTitle": "Break Finished",
            "pomodoro.notifyFocusBody": "Ready to focus on your next session?",

            // Shortcuts Tab
            "shortcuts.globalHotkeys": "Global Hotkeys",
            "shortcuts.toggleDials": "Toggle Corner Dials",
            "shortcuts.toggleDialsDesc": "Quickly reveal or hide active corner dial controls",
            "shortcuts.toggleDock": "Toggle Hidden Dock",
            "shortcuts.toggleDockDesc": "Slide out or dismiss the hidden application shelf",
            "shortcuts.conflictAnalysis": "Shortcut Conflict Analysis",
            "shortcuts.noConflicts": "No conflicting system shortcuts detected.",
            "shortcuts.conflictHint": "MacStash automatically audits against macOS reserved shortcuts (⌘Space Spotlight, ⌘Tab Application Switcher, ⌘⌥Esc Force Quit).",

            // About Tab
            "about.title": "About MacStash",
            "about.version": "Version 2.1.1 (Universal arm64 / x86_64)",
            "about.subtitle": "Tactile Hot Corner Dials & Display Controls for macOS",
            "about.diagnostics": "Diagnostics & Logging",
            "about.debugLogging": "Enable Detailed Debug Logging",
            "about.debugHint": "Logs subsystem output to macOS Unified Logging System (com.macstash.app).",
            "about.openConsole": "Open Logs in Console",
            "about.openGuide": "Open User Guide",
            "about.backupRestore": "Configuration Backup & Restore",
            "about.exportJSON": "Export Settings (JSON)...",
            "about.importJSON": "Import Settings (JSON)...",
            "about.importSuccess": "Settings imported successfully!",
            "about.factoryReset": "Factory Reset",
            "about.resetAllButton": "Reset All Preferences...",

            // Menu Bar Extra
            "menubar.activeContext": "ACTIVE CONTEXT",
            "menubar.focusTimer": "Focus Timer:",
            "menubar.pause": "Pause",
            "menubar.start": "Start",
            "menubar.reset": "Reset",
            "menubar.skip": "Skip",
            "menubar.volume": "Master Volume",
            "menubar.brightness": "Brightness",
            "menubar.keyboard": "Keyboard Backlight",
            "menubar.quickSettings": "Preferences...",
            "menubar.userGuide": "User Guide",
            "menubar.quit": "Quit MacStash",

            // Window Titles & Help
            "guide.windowTitle": "MacStash User Guide",
            "settings.windowTitle": "MacStash Settings",
            "onboarding.windowTitle": "Welcome to MacStash",
            "guide.searchPlaceholder": "Search Guide...",
            "guide.emptySelection": "Select an article from the sidebar."
        ],
        "vi": [
            // Tabs
            "tab.general": "Tổng quan",
            "tab.hotCorners": "Góc nóng",
            "tab.appearance": "Giao diện",
            "tab.displays": "Màn hình",
            "tab.pomodoro": "Đồng hồ Pomodoro",
            "tab.shortcuts": "Phím tắt",
            "tab.about": "Thông tin & Nâng cao",

            // General Tab
            "general.masterControls": "Điều khiển chính",
            "general.enableMacStash": "Bật điều khiển MacStash",
            "general.showMenuBarIcon": "Hiện biểu tượng trên Menu Bar",
            "general.launchAtLogin": "Khởi động cùng máy tính",
            "general.languageLocale": "Ngôn ngữ & Vùng",
            "general.interfaceLanguage": "Ngôn ngữ giao diện",
            "general.systemDefault": "Mặc định hệ thống",
            "general.vietnamese": "Tiếng Việt",
            "general.english": "English",
            "general.languageHint": "Thay đổi được áp dụng ngay lập tức cho toàn bộ nhãn và hướng dẫn.",
            "general.systemPermissions": "Quyền hệ thống",
            "general.accessibility": "Trợ năng",
            "general.accessibilityDesc": "Bắt buộc để theo dõi con trỏ và kích hoạt góc nóng",
            "general.inputMonitoring": "Theo dõi đầu vào",
            "general.inputMonitoringDesc": "Bắt buộc để nhận diện phím bổ trợ và thao tác cuộn khi tinh chỉnh",
            "general.notifications": "Thông báo",
            "general.notificationsDesc": "Dùng để phát thông báo khi đồng hồ Pomodoro hoàn thành",
            "general.granted": "Đã cấp",
            "general.notGranted": "Chưa cấp",
            "general.grantPermission": "Cấp quyền",
            "general.openSettings": "Mở Cài đặt",
            "general.factoryReset": "Khôi phục cài đặt gốc",
            "general.resetDesc": "Khôi phục toàn bộ cài đặt, cấu hình và gán góc về giá trị mặc định.",
            "general.resetButton": "Đặt lại toàn bộ cài đặt...",
            "general.resetAlertTitle": "Đặt lại tất cả cài đặt?",
            "general.resetAlertMessage": "Thao tác này sẽ khôi phục toàn bộ gán góc, ngưỡng độ nhạy và cấu hình màn hình về mặc định ban đầu. Không thể hoàn tác hành động này.",
            "general.resetConfirm": "Đặt lại",
            "general.cancel": "Hủy",

            // Hot Corners Tab
            "corners.cornerAssignment": "Gán hành động góc",
            "corners.topLeft": "Góc Trên - Trái",
            "corners.topRight": "Góc Trên - Phải",
            "corners.bottomLeft": "Góc Dưới - Trái",
            "corners.bottomRight": "Góc Dưới - Phải",
            "corners.triggerPrecision": "Độ chính xác & Thời gian kích hoạt",
            "corners.hitZoneSensitivity": "Độ nhạy vùng chạm:",
            "corners.hitZoneHint": "Giá trị nhỏ hơn yêu cầu rê chuột sát rìa mép ngoài hơn, giúp chống chạm nhầm.",
            "corners.dwellDelay": "Độ trễ dừng chuột:",
            "corners.dwellDelayHint": "Con trỏ phải dừng trong vùng chạm đủ thời gian này trước khi vòng quay mở ra.",
            "corners.autoDismissDelay": "Thời gian chờ tự động ẩn:",
            "corners.autoDismissHint": "Khoảng thời gian cho phép sau khi rê chuột ra ngoài trước khi vòng quay biến mất.",
            "corners.suppressionRules": "Quy tắc ngăn chặn",
            "corners.suppressDragging": "Không mở vòng quay khi đang kéo tệp hoặc cửa sổ",
            "corners.suppressFullScreen": "Không mở vòng quay khi ứng dụng đang chạy toàn màn hình",
            "corners.excludedApps": "Ứng dụng loại trừ",
            "corners.excludedAppsDesc": "Vòng quay sẽ không bao giờ kích hoạt khi các ứng dụng này đang hoạt động:",
            "corners.bundleIDPlaceholder": "com.example.app (Mã Bundle ID)",
            "corners.add": "Thêm",
            "corners.noExcludedApps": "Chưa có ứng dụng loại trừ nào.",
            "corners.action.volume": "Âm lượng",
            "corners.action.brightness": "Độ sáng",
            "corners.action.backlight": "Đèn bàn phím",
            "corners.action.pomodoro": "Đồng hồ Pomodoro",
            "corners.action.none": "Không (Tắt)",

            // Appearance Tab
            "appearance.geometryStyling": "Hình học & Phong cách vòng quay",
            "appearance.dialRadius": "Bán kính vành quay:",
            "appearance.glassOpacity": "Độ mờ kính nền:",
            "appearance.theme": "Chủ đề giao diện:",
            "appearance.themeMatchSystem": "Theo hệ thống",
            "appearance.themeLight": "Sáng",
            "appearance.themeDark": "Tối",
            "appearance.animationMotion": "Hiệu ứng chuyển động",
            "appearance.animationSpeed": "Thời gian hiệu ứng:",
            "appearance.reduceMotion": "Tuân thủ thiết lập Giảm chuyển động của hệ thống",
            "appearance.reduceMotionHint": "Loại bỏ hiệu ứng phóng to/thu nhỏ cho người dùng nhạy cảm với chuyển động.",
            "appearance.tactileAudio": "Phản hồi xúc giác & Âm thanh",
            "appearance.soundFx": "Hiệu ứng âm thanh cơ học",
            "appearance.soundVolume": "Âm lượng âm thanh:",
            "appearance.trackpadHaptics": "Rung phản hồi haptic trên Trackpad",
            "appearance.hapticIntensity": "Cường độ rung:",
            "appearance.hapticLight": "Nhẹ",
            "appearance.hapticMedium": "Vừa",
            "appearance.hapticStrong": "Mạnh",

            // Displays Tab
            "displays.connectedDisplays": "Màn hình đang kết nối",
            "displays.scanning": "Đang dò tìm màn hình kết nối...",
            "displays.precision": "Độ chính xác điều chỉnh độ sáng",
            "displays.stepSize": "Bước nhảy điều chỉnh:",
            "displays.stepUltraFine": "1% (Siêu mịn)",
            "displays.stepBalanced": "5% (Cân bằng)",
            "displays.stepCoarse": "10% (Nhanh)",
            "displays.minClamp": "Ngưỡng sáng tối thiểu:",
            "displays.minClampHint": "Ngăn đèn nền tắt tối đen hoàn toàn khi xoay về mức nhỏ nhất.",
            "displays.method": "Phương thức:",
            "displays.methodAuto": "Tự động phát hiện",
            "displays.methodDDC": "Phần cứng DDC/CI",
            "displays.methodSoftware": "Giảm sáng phần mềm",
            "displays.methodBuiltIn": "DisplayServices mặc định",
            "displays.builtInDisplay": "Màn hình Retina tích hợp",
            "displays.externalDisplay": "Màn hình ngoài",
            "displays.brightnessTest": "Thử nghiệm độ sáng:",

            // Pomodoro Tab
            "pomodoro.intervalDurations": "Thời lượng các khoảng đếm",
            "pomodoro.focusDuration": "Thời gian tập trung:",
            "pomodoro.shortBreakDuration": "Thời gian nghỉ ngắn:",
            "pomodoro.longBreakDuration": "Thời gian nghỉ dài:",
            "pomodoro.roundsBeforeLong": "Số hiệp trước khi nghỉ dài:",
            "pomodoro.rounds": "hiệp",
            "pomodoro.automationAlerts": "Tự động hóa & Chuông báo",
            "pomodoro.autoStartBreak": "Tự động bắt đầu nghỉ khi kết thúc phiên tập trung",
            "pomodoro.playChime": "Phát chuông báo khi đồng hồ hoàn thành",
            "pomodoro.currentState": "Trạng thái Pomodoro hiện tại",
            "pomodoro.timeRemaining": "Thời gian còn lại:",
            "pomodoro.statusRunning": "Đang trong phiên tập trung",
            "pomodoro.statusPaused": "Tạm dừng / Đang chờ",
            "pomodoro.btnPause": "Tạm dừng",
            "pomodoro.btnStart": "Bắt đầu",
            "pomodoro.btnReset": "Đặt lại",
            "pomodoro.btnSkip": "Bỏ qua",
            "pomodoro.modeFocus": "Tập trung",
            "pomodoro.modeShortBreak": "Nghỉ ngắn",
            "pomodoro.modeLongBreak": "Nghỉ dài",
            "pomodoro.roundIndicator": "Hiệp %d/%d",
            "pomodoro.minutesUnit": "phút",
            "pomodoro.notifyBreakTitle": "Hoàn thành phiên Pomodoro",
            "pomodoro.notifyBreakBody": "Hãy nghỉ ngơi thư giãn một lát",
            "pomodoro.notifyFocusTitle": "Kết thúc giờ nghỉ",
            "pomodoro.notifyFocusBody": "Sẵn sàng trở lại phiên làm việc tiếp theo",

            // Shortcuts Tab
            "shortcuts.globalHotkeys": "Phím tắt toàn cục",
            "shortcuts.toggleDials": "Bật/Tắt vòng xoay góc",
            "shortcuts.toggleDialsDesc": "Hiện hoặc ẩn nhanh các vòng xoay điều khiển ở góc",
            "shortcuts.toggleDock": "Bật/Tắt Dock ẩn",
            "shortcuts.toggleDockDesc": "Trượt ra hoặc đóng ngăn kéo ứng dụng ẩn",
            "shortcuts.conflictAnalysis": "Phân tích xung đột phím tắt",
            "shortcuts.noConflicts": "Không phát hiện xung đột với phím tắt hệ thống.",
            "shortcuts.conflictHint": "MacStash tự động kiểm tra đối chiếu với các phím tắt hệ thống macOS (⌘Space Spotlight, ⌘Tab chuyển ứng dụng, ⌘⌥Esc buộc thoát).",

            // About Tab
            "about.title": "Thông tin MacStash",
            "about.version": "Phiên bản 2.1.1 (Universal arm64 / x86_64)",
            "about.subtitle": "Vòng xoay xúc giác góc màn hình & Điều khiển hiển thị cho macOS",
            "about.diagnostics": "Chẩn đoán & Nhật ký",
            "about.debugLogging": "Bật nhật ký gỡ lỗi chi tiết",
            "about.debugHint": "Ghi nhật ký hệ thống con vào macOS Unified Logging System (com.macstash.app).",
            "about.openConsole": "Mở nhật ký trong Console",
            "about.openGuide": "Mở hướng dẫn sử dụng",
            "about.backupRestore": "Sao lưu & Phục hồi cấu hình",
            "about.exportJSON": "Xuất cài đặt (JSON)...",
            "about.importJSON": "Nhập cài đặt (JSON)...",
            "about.importSuccess": "Đã nhập cấu hình cài đặt thành công!",
            "about.factoryReset": "Khôi phục gốc",
            "about.resetAllButton": "Đặt lại tất cả tùy chọn...",

            // Menu Bar Extra
            "menubar.activeContext": "NGỮ CẢNH HOẠT ĐỘNG",
            "menubar.focusTimer": "Đồng hồ tập trung:",
            "menubar.pause": "Tạm dừng",
            "menubar.start": "Bắt đầu",
            "menubar.reset": "Đặt lại",
            "menubar.skip": "Bỏ qua",
            "menubar.volume": "Âm lượng tổng",
            "menubar.brightness": "Độ sáng",
            "menubar.keyboard": "Đèn bàn phím",
            "menubar.quickSettings": "Tùy chọn...",
            "menubar.userGuide": "Hướng dẫn sử dụng",
            "menubar.quit": "Thoát MacStash",

            // Window Titles & Help
            "guide.windowTitle": "Hướng Dẫn Sử Dụng MacStash",
            "settings.windowTitle": "Cài Đặt MacStash",
            "onboarding.windowTitle": "Chào Mừng Đến Với MacStash",
            "guide.searchPlaceholder": "Tìm kiếm hướng dẫn...",
            "guide.emptySelection": "Chọn một bài viết từ danh mục bên trái."
        ]
    ]
}
