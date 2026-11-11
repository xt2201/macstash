import SwiftUI
import AppKit
import MacStashCore

public struct OnboardingView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var appState: AppState
    @ObservedObject private var permissions = SystemPermissionService.shared
    @State private var currentStep: Int = 0

    public let onFinish: () -> Void

    public init(appState: AppState = .shared, onFinish: @escaping () -> Void) {
        self.appState = appState
        self.onFinish = onFinish
    }

    private let totalSteps: Int = 4

    public var body: some View {
        VStack(spacing: 0) {
            // Top Progress & Language Bar
            HStack {
                Text(String(format: appState.localized("onboarding.stepOf"), currentStep + 1, totalSteps))
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 5) {
                    ForEach(0..<totalSteps, id: \.self) { step in
                        Capsule()
                            .fill(step == currentStep ? Color.accentColor : Color.primary.opacity(0.14))
                            .frame(width: step == currentStep ? 24 : 8, height: 6)
                            .animation(.spring(response: 0.28, dampingFraction: 0.8), value: currentStep)
                    }
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Divider()

            // Main Step Content
            Group {
                switch currentStep {
                case 0:
                    welcomeStep
                case 1:
                    cornersStep
                case 2:
                    controlsStep
                default:
                    permissionsStep
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .transition(.opacity.combined(with: .move(edge: .trailing)))

            Divider()

            // Bottom Navigation Bar
            HStack {
                if currentStep > 0 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            currentStep -= 1
                        }
                    } label: {
                        Text(appState.localized("onboarding.previous"))
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                if currentStep < totalSteps - 1 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            currentStep += 1
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(appState.localized("onboarding.next"))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 11, weight: .bold))
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                } else {
                    Button {
                        onFinish()
                    } label: {
                        HStack(spacing: 6) {
                            Text(appState.localized("onboarding.getStarted"))
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
        }
        .frame(width: 620, height: 470)
        .background(Color(NSColor.windowBackgroundColor))
        .macStashTheme(appState.resolvedColorScheme)
        .onAppear {
            permissions.checkAllPermissions()
        }
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.cyan.opacity(0.28), Color.blue.opacity(0.08), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 85
                        )
                    )
                    .frame(width: 150, height: 150)

                StashBrandLogoView(size: 80, showWordmark: false)
            }

            VStack(spacing: 8) {
                Text(appState.localized("onboarding.welcome"))
                    .font(.system(size: 22, weight: .bold))
                    .multilineTextAlignment(.center)

                Text(appState.localized("onboarding.welcomeDesc"))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
            }

            // Inline Language Picker
            HStack(spacing: 10) {
                Text(appState.localized("onboarding.language"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                Picker("", selection: $appState.settings.language) {
                    Text(appState.localized("general.systemDefault")).tag("system")
                    Text(appState.localized("general.vietnamese")).tag("vi")
                    Text(appState.localized("general.english")).tag("en")
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 260)
            }
            .padding(.top, 4)
        }
    }

    private var cornersStep: some View {
        VStack(spacing: 18) {
            // Custom Vector Screen Quadrant Graphic
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: colorScheme == .dark
                                ? [Color(red: 0.08, green: 0.10, blue: 0.16), Color(red: 0.13, green: 0.17, blue: 0.27)]
                                : [Color(red: 0.86, green: 0.91, blue: 0.98), Color(red: 0.77, green: 0.85, blue: 0.95)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.18), lineWidth: 1.5)
                    )

                VStack {
                    HStack {
                        cornerMiniDial(color: .indigo, icon: "keyboard.fill")
                        Spacer()
                        cornerMiniDial(color: .orange, icon: "sun.max.fill")
                    }
                    Spacer()
                    HStack {
                        cornerMiniDial(color: .red, icon: "timer")
                        Spacer()
                        cornerMiniDial(color: .cyan, icon: "speaker.wave.3.fill")
                    }
                }
                .padding(10)

                // Edge Slider & Stash Shelf indicators
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.purple.opacity(0.8))
                        .frame(width: 6, height: 48)
                        .padding(.leading, 5)
                    Spacer()
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue.opacity(0.85))
                        .frame(width: 6, height: 64)
                        .padding(.trailing, 5)
                }

                // Bottom Second Dock pill
                VStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Circle().fill(Color.teal).frame(width: 8, height: 8)
                        Circle().fill(Color.cyan).frame(width: 8, height: 8)
                        Circle().fill(Color.orange).frame(width: 8, height: 8)
                        Circle().fill(Color.pink).frame(width: 8, height: 8)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.ultraThinMaterial))
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.25), lineWidth: 0.8))
                    .padding(.bottom, 10)
                }
            }
            .frame(width: 290, height: 164)

            VStack(spacing: 8) {
                Text(appState.localized("onboarding.cornersTitle"))
                    .font(.system(size: 19, weight: .bold))
                    .multilineTextAlignment(.center)

                Text(appState.localized("onboarding.cornersDesc"))
                    .font(.system(size: 12.5))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
            }
        }
    }

    private func cornerMiniDial(color: Color, icon: String) -> some View {
        ZStack {
            Circle()
                .fill(color.gradient)
                .frame(width: 34, height: 34)
                .shadow(color: color.opacity(0.4), radius: 6, x: 0, y: 2)
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
        }
    }

    private var controlsStep: some View {
        VStack(spacing: 18) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                featureCard(
                    icon: "sun.max.fill",
                    tint: .orange,
                    title: appState.localized("palette.brightness"),
                    subtitle: "DDC/CI + Native"
                )
                featureCard(
                    icon: "speaker.wave.3.fill",
                    tint: .cyan,
                    title: appState.localized("palette.volume"),
                    subtitle: "CoreAudio + Now Playing"
                )
                featureCard(
                    icon: "timer",
                    tint: .red,
                    title: appState.localized("tab.pomodoro"),
                    subtitle: "Monotonic + Alerts"
                )
                featureCard(
                    icon: "dock.rectangle",
                    tint: .teal,
                    title: appState.localized("tab.sideDock"),
                    subtitle: "16 Live Widgets"
                )
            }
            .frame(maxWidth: 440)

            VStack(spacing: 8) {
                Text(appState.localized("onboarding.controlsTitle"))
                    .font(.system(size: 19, weight: .bold))
                    .multilineTextAlignment(.center)

                Text(appState.localized("onboarding.controlsDesc"))
                    .font(.system(size: 12.5))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
            }
        }
    }

    private func featureCard(icon: String, tint: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 34, height: 34)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(tint.gradient)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12.5, weight: .bold))
                Text(subtitle)
                    .font(.system(size: 10.5))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.035))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(tint.opacity(0.25), lineWidth: 0.8)
        )
    }

    private var permissionsStep: some View {
        VStack(spacing: 14) {
            VStack(spacing: 6) {
                Text(appState.localized("onboarding.permissionsTitle"))
                    .font(.system(size: 19, weight: .bold))

                Text(appState.localized("onboarding.permissionsDesc"))
                    .font(.system(size: 12.5))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 10) {
                onboardingPermissionRow(
                    title: appState.localized("general.accessibility"),
                    description: appState.localized("general.accessibilityDesc"),
                    isGranted: permissions.isAccessibilityGranted,
                    actionTitle: appState.localized("onboarding.configAccessibility"),
                    onRequest: { permissions.requestAccessibilityPermission() },
                    onOpen: { permissions.openAccessibilitySettings() }
                )

                onboardingPermissionRow(
                    title: appState.localized("general.inputMonitoring"),
                    description: appState.localized("general.inputMonitoringDesc"),
                    isGranted: permissions.isInputMonitoringGranted,
                    actionTitle: appState.localized("general.grantPermission"),
                    onRequest: { permissions.requestInputMonitoringPermission() },
                    onOpen: { permissions.openInputMonitoringSettings() }
                )

                onboardingPermissionRow(
                    title: appState.localized("general.notifications"),
                    description: appState.localized("general.notificationsDesc"),
                    isGranted: permissions.isNotificationGranted,
                    actionTitle: appState.localized("onboarding.configNotifications"),
                    onRequest: { permissions.requestNotificationPermission() },
                    onOpen: { permissions.openNotificationSettings() }
                )
            }
        }
    }

    private func onboardingPermissionRow(
        title: String,
        description: String,
        isGranted: Bool,
        actionTitle: String,
        onRequest: @escaping () -> Void,
        onOpen: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 12.5, weight: .semibold))
                    StatusBadgePill(
                        text: appState.localized(isGranted ? "general.granted" : "general.notGranted"),
                        color: isGranted ? .green : .orange
                    )
                }
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if !isGranted {
                Button(actionTitle) {
                    onRequest()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            Button(appState.localized("general.openSettings")) {
                onOpen()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.045) : Color.black.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.8)
        )
    }
}
