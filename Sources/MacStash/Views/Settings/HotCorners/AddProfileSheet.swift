import SwiftUI
import AppKit
import MacStashCore
import MacStashDesignSystem

public struct AddProfileSheet: View {
    @ObservedObject var appState: AppState
    @Binding var isPresented: Bool
    public let onAdded: (AppProfile) -> Void

    @State private var newProfileName: String = ""
    @State private var newProfileBundleID: String = ""

    public init(
        appState: AppState,
        isPresented: Binding<Bool>,
        onAdded: @escaping (AppProfile) -> Void
    ) {
        self.appState = appState
        self._isPresented = isPresented
        self.onAdded = onAdded
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(appState.localized("corners.addProfile"))
                .font(.system(size: 15, weight: .bold))

            VStack(alignment: .leading, spacing: 6) {
                Text(appState.localized("corners.profileName"))
                    .font(.system(size: 12, weight: .medium))
                TextField("Safari / Final Cut Pro", text: $newProfileName)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(appState.localized("corners.bundleID"))
                    .font(.system(size: 12, weight: .medium))

                HStack(spacing: 8) {
                    TextField("com.apple.Safari", text: $newProfileBundleID)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))

                    Menu(appState.localized("corners.chooseApp")) {
                        let running = AppPickerHelper.runningUserApps()
                        if !running.isEmpty {
                            Section(appState.localized("corners.runningApps")) {
                                ForEach(running) { picked in
                                    Button(picked.name) {
                                        if newProfileName.trimmingCharacters(in: .whitespaces).isEmpty {
                                            newProfileName = picked.name
                                        }
                                        newProfileBundleID = picked.bundleIdentifier
                                    }
                                }
                            }
                        }
                        Divider()
                        Button(appState.localized("corners.browseApps")) {
                            AppPickerHelper.browseForApplication { picked in
                                if let picked {
                                    if newProfileName.trimmingCharacters(in: .whitespaces).isEmpty {
                                        newProfileName = picked.name
                                    }
                                    newProfileBundleID = picked.bundleIdentifier
                                }
                            }
                        }
                    }
                    .menuStyle(.borderedButton)
                    .fixedSize()
                }
            }

            HStack {
                Spacer()
                Button(appState.localized("corners.cancel")) {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Button(appState.localized("corners.save")) {
                    saveProfile()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(
                    newProfileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    newProfileBundleID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
            }
            .padding(.top, 6)
        }
        .padding(20)
        .frame(width: 420)
        .macStashTheme(appState.resolvedColorScheme)
    }

    private func saveProfile() {
        let name = newProfileName.trimmingCharacters(in: .whitespacesAndNewlines)
        let bundleID = newProfileBundleID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !bundleID.isEmpty else { return }

        let profile = AppProfile(
            name: name,
            bundleIdentifier: bundleID,
            cornerActions: appState.settings.cornerActions,
            leftEdgeAction: appState.activeProfile.leftEdgeAction,
            rightEdgeAction: appState.activeProfile.rightEdgeAction
        )
        onAdded(profile)
        isPresented = false
    }
}
