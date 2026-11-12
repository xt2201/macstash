import SwiftUI
import AppKit
import MacStashCore
import MacStashDesignSystem

public struct MenuBarExtraView: View {
    @ObservedObject var appState: AppState
    public var onOpenSettings: () -> Void
    public var onOpenGuide: () -> Void

    public init(
        appState: AppState,
        onOpenSettings: @escaping () -> Void,
        onOpenGuide: @escaping () -> Void = {}
    ) {
        self.appState = appState
        self.onOpenSettings = onOpenSettings
        self.onOpenGuide = onOpenGuide
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 1. Header Strip & Active Context
            MenuBarHeaderAndContextCard(
                appState: appState,
                onOpenSettings: onOpenSettings,
                onOpenGuide: onOpenGuide
            )

            // 2. Pomodoro Focus Card
            MenuBarPomodoroCard(appState: appState)

            // 3. Hardware Control Card (Audio, Displays with maxHeight: 165, Keyboard)
            MenuBarHardwareCard(appState: appState)

            // 4. Modular Quick Utilities Grid
            MenuBarModulesGrid(appState: appState)

            Divider()
                .opacity(0.6)

            // 5. Footer Actions (Updates, Guide, Settings, Quit)
            MenuBarFooterBar(
                appState: appState,
                onOpenSettings: onOpenSettings,
                onOpenGuide: onOpenGuide
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(width: 296)
        .macStashTheme(appState.resolvedColorScheme)
        .onAppear {
            appState.keyboard.updateBrightnessFromHardware()
            appState.audio.updateVolumeFromHardware()
            _ = appState.connectedDisplays(forceRefresh: true)
        }
    }
}
