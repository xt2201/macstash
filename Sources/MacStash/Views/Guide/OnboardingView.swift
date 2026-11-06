import SwiftUI
import AppKit

public struct OnboardingView: View {
    @State private var currentStep: Int = 1
    @StateObject private var permissions = SystemPermissionService.shared
    public var onFinish: () -> Void

    public init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
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
                    Button("Previous") {
                        currentStep -= 1
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                if currentStep < 4 {
                    Button("Next Step") {
                        currentStep += 1
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Get Started") {
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

            Text("Welcome to MacStash")
                .font(.system(size: 22, weight: .bold))

            Text("MacStash brings tactile corner dials and hidden productivity controls directly to your macOS workspace. Controls remain completely hidden and zero-resource until you summon them.")
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

            Text("Outer Corner Triggering")
                .font(.system(size: 20, weight: .bold))

            Text("To reveal a dial, move your mouse into the extreme corner of your display and pause for a fraction of a second. On multi-display setups, inner junctions are automatically filtered out to ensure smooth cursor transitions.")
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

            Text("Tactile Hardware & Focus Controls")
                .font(.system(size: 20, weight: .bold))

            Text("Easily adjust per-monitor brightness (via DDC/CI hardware control or software dimming), master audio output, keyboard backlight, and the monotonic Pomodoro focus timer.")
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

            Text("Permissions Setup")
                .font(.system(size: 20, weight: .bold))

            Text("MacStash operates locally on your machine with zero telemetry. Grant Accessibility permission to enable cursor tracking across your displays.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            HStack(spacing: 12) {
                Button("Configure Accessibility") {
                    permissions.openAccessibilitySettings()
                }
                .buttonStyle(.bordered)

                Button("Configure Notifications") {
                    permissions.openNotificationSettings()
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 4)
        }
    }
}
