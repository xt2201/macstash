import SwiftUI
import AppKit
import MacStashCore
import MacStashDesignSystem

public struct MenuBarHeaderAndContextCard: View {
    @ObservedObject var appState: AppState
    public var onOpenSettings: () -> Void
    public var onOpenGuide: () -> Void

    public init(
        appState: AppState,
        onOpenSettings: @escaping () -> Void,
        onOpenGuide: @escaping () -> Void
    ) {
        self.appState = appState
        self.onOpenSettings = onOpenSettings
        self.onOpenGuide = onOpenGuide
    }

    public var body: some View {
        VStack(spacing: 8) {
            // Header Strip
            HStack(spacing: 8) {
                StashBrandLogoView(size: 22)

                VStack(alignment: .leading, spacing: 0) {
                    Text("MacStash")
                        .font(.system(size: 13, weight: .bold))
                    Text(appState.isEnabled ? appState.localized("settings.statusActive") : appState.localized("settings.statusPaused"))
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundColor(appState.isEnabled ? .green : .secondary)
                }

                Spacer()

                Button(action: onOpenGuide) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(appState.localized("menubar.userGuide"))

                Button(action: onOpenSettings) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(appState.localized("menubar.quickSettings"))

                Toggle("", isOn: $appState.isEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
            }

            // Active Context App Card
            HStack(spacing: 8) {
                if let icon = AppIconCache.shared.icon(forBundleID: appState.profiles.currentBundleId, targetSize: NSSize(width: 20, height: 20)) {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(width: 20, height: 20)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(appState.localized("menubar.activeContext"))
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(.secondary)
                    Text(appState.profiles.currentAppName)
                        .font(.system(size: 11.5, weight: .semibold))
                        .lineLimit(1)
                }

                Spacer()

                Text(appState.activeProfile.name)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.accentColor.opacity(0.14)))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.primary.opacity(0.045))
            )
        }
    }
}
