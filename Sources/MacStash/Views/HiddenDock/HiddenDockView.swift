import SwiftUI
import AppKit

public struct HiddenDockView: View {
    @ObservedObject var appState: AppState

    @State private var isHovered: Bool = false
    @State private var hoveredItemId: UUID? = nil

    private let dockWidth: CGFloat = 68
    private let handleWidth: CGFloat = 6

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        let isVisible = appState.isEnabled && appState.isHiddenDockEnabled
        let isExpanded = isHovered || appState.isDockExpanded

        ZStack(alignment: .leading) {
            if isVisible {
                HStack(spacing: 0) {
                    dockContent(isExpanded: isExpanded)
                        .offset(x: isExpanded ? 0 : -(dockWidth - handleWidth))
                }
                .animation(.spring(response: 0.32, dampingFraction: 0.74), value: isExpanded)
                .onHover { hovering in
                    isHovered = hovering
                    appState.isDockExpanded = hovering
                }
            }
        }
        .frame(width: dockWidth + 10)
    }

    @ViewBuilder
    private func dockContent(isExpanded: Bool) -> some View {
        VStack(spacing: 12) {
            // Pinned "Sometimes" Apps
            ForEach(appState.dockItems) { item in
                let isItemHovered = hoveredItemId == item.id
                let isRunning = isAppRunning(bundleId: item.bundleIdentifier)

                Button(action: {
                    item.launch()
                    appState.sound.playAccent(enabled: appState.isSoundEnabled)
                    appState.haptics.performBoundaryClick()
                }) {
                    VStack(spacing: 4) {
                        Image(nsImage: item.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .shadow(color: Color.black.opacity(0.3), radius: isItemHovered ? 6 : 2, x: 0, y: 2)
                            .scaleEffect(isItemHovered ? 1.25 : 1.0)
                            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isItemHovered)

                        // Running app dot indicator
                        Circle()
                            .fill(isRunning ? Color.white.opacity(0.85) : Color.clear)
                            .frame(width: 4, height: 4)
                    }
                    .frame(width: 52, height: 50)
                }
                .buttonStyle(.plain)
                .onHover { h in
                    if h {
                        hoveredItemId = item.id
                        appState.haptics.performDetentTick(intensity: .subtle)
                    } else if hoveredItemId == item.id {
                        hoveredItemId = nil
                    }
                }
                .help(item.name)
            }

            Divider()
                .padding(.horizontal, 12)

            // Quick App Launcher Search Button
            Button(action: {
                appState.isQuickLauncherPresented.toggle()
            }) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .fill(Color.accentColor.opacity(0.85))
                            .shadow(color: Color.accentColor.opacity(0.4), radius: 6, x: 0, y: 2)
                    )
            }
            .buttonStyle(.plain)
            .help("Quick App Launcher")
        }
        .padding(.vertical, 14)
        .frame(width: dockWidth)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 20,
                topTrailingRadius: 20,
                style: .continuous
            )
            .fill(.ultraThinMaterial)
            .shadow(color: Color.black.opacity(0.35), radius: 16, x: 6, y: 4)
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 20,
                topTrailingRadius: 20,
                style: .continuous
            )
            .stroke(
                LinearGradient(
                    colors: [Color.white.opacity(0.35), Color.white.opacity(0.08)],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 1
            )
        )
    }

    private func isAppRunning(bundleId: String) -> Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: bundleId).isEmpty
    }
}
