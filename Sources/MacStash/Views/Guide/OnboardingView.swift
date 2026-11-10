import SwiftUI
import AppKit
import MacStashCore

public struct OnboardingView: View {
    @State private var currentStep: Int = 1
    @StateObject private var permissions = SystemPermissionService.shared
    public var onFinish: () -> Void

    public init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    private func localized(_ key: String) -> String {
        LocalizationService.shared.localized(key)
    }

    public var body: some View {
        VStack(spacing: 24) {
            // Step Indicator
            HStack(spacing: 8) {
                ForEach(1...4, id: \.self) { step in
                    Capsule()
                        .fill(step <= currentStep ? Color.accentColor : Color.secondary.opacity(0.2))
                        .frame(width: 40, height: 4)
                }
            }
            .padding(.top, 24)

            // Step Content
            VStack(spacing: 16) {
                switch currentStep {
                case 1:
                    stepWelcome
                case 2:
                    stepCorners
                case 3:
                    stepControls
                default:
                    stepPermissions
                }
            }
            .frame(height: 280)

            Divider()

            // Navigation Buttons
            HStack {
                if currentStep > 1 {
                    Button(localized("onboarding.previous")) {
                        currentStep -= 1
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                if currentStep < 4 {
                    Button(localized("onboarding.next")) {
                        currentStep += 1
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(localized("onboarding.getStarted")) {
                        onFinish()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .frame(width: 520, height: 400)
    }

    private var stepWelcome: some View {
        VStack(spacing: 14) {
            StashBrandLogoView(size: 64, showWordmark: true)

            Text(localized("onboarding.welcome"))
                .font(.system(size: 22, weight: .bold))

            Text(localized("onboarding.welcomeDesc"))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }

    private var stepCorners: some View {
        VStack(spacing: 14) {
            Image(systemName: "viewfinder")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 54, height: 54)
                .foregroundColor(.accentColor)

            Text(localized("onboarding.cornersTitle"))
                .font(.system(size: 20, weight: .bold))

            Text(localized("onboarding.cornersDesc"))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }

    private var stepControls: some View {
        VStack(spacing: 14) {
            Image(systemName: "slider.horizontal.3")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 54, height: 54)
                .foregroundColor(.accentColor)

            Text(localized("onboarding.controlsTitle"))
                .font(.system(size: 20, weight: .bold))

            Text(localized("onboarding.controlsDesc"))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }

    private var stepPermissions: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
                .foregroundColor(.green)

            Text(localized("onboarding.permissionsTitle"))
                .font(.system(size: 20, weight: .bold))

            Text(localized("onboarding.permissionsDesc"))
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            HStack(spacing: 12) {
                Button(localized("onboarding.configAccessibility")) {
                    permissions.openAccessibilitySettings()
                }
                .buttonStyle(.bordered)

                Button(localized("onboarding.configNotifications")) {
                    permissions.openNotificationSettings()
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 4)
        }
    }
}
