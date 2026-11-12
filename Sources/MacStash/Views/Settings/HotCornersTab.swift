import SwiftUI
import AppKit
import MacStashCore
import MacStashDesignSystem

public struct HotCornersTab: View {
    @ObservedObject var appState: AppState

    @State private var selectedProfileID: UUID
    @State private var showingAddProfileSheet: Bool = false
    @State private var focusedCorner: CornerPosition? = nil
    @State private var focusedEdge: EdgePosition? = nil
    @State private var highlightTarget: InteractiveMapTarget? = nil

    public enum InteractiveMapTarget: Equatable {
        case corner(CornerPosition)
        case edgeSlider
        case drawer
    }

    public init(appState: AppState) {
        self.appState = appState
        let defaultID = appState.appProfiles.first(where: { $0.bundleIdentifier == nil })?.id
            ?? appState.appProfiles.first?.id
            ?? UUID()
        self._selectedProfileID = State(initialValue: defaultID)
    }

    private var selectedProfileIndex: Int {
        if let idx = appState.appProfiles.firstIndex(where: { $0.id == selectedProfileID }) {
            return idx
        }
        return 0
    }

    private var selectedProfile: AppProfile {
        guard appState.appProfiles.indices.contains(selectedProfileIndex) else {
            return appState.activeProfile
        }
        return appState.appProfiles[selectedProfileIndex]
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Section 1: Application Profiles Bar
            profileHeaderCard

            // Section 2: Interactive Desktop Screen Map
            SettingsCard(
                title: appState.localized("corners.visualPreview"),
                systemImage: "macwindow.on.rectangle",
                accentColor: .cyan
            ) {
                CornerDesktopMapView(
                    appState: appState,
                    selectedProfile: selectedProfile,
                    focusedCorner: $focusedCorner,
                    focusedEdge: $focusedEdge,
                    highlightTarget: $highlightTarget
                )

                Text(appState.localized("corners.previewHint"))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            // Section 3-5: Corner Quadrant, Edge Sliders & Drawers
            CornerQuadrantCard(
                appState: appState,
                selectedProfileIndex: selectedProfileIndex,
                selectedProfile: selectedProfile,
                focusedCorner: $focusedCorner,
                focusedEdge: $focusedEdge,
                highlightTarget: $highlightTarget
            )

            // Section 6-8: Advanced Settings (Precision, Suppression, Excluded Apps)
            CornerAdvancedSettingsCard(appState: appState)
        }
        .sheet(isPresented: $showingAddProfileSheet) {
            AddProfileSheet(
                appState: appState,
                isPresented: $showingAddProfileSheet,
                onAdded: { newProfile in
                    appState.appProfiles.append(newProfile)
                    selectedProfileID = newProfile.id
                    appState.saveSettings()
                }
            )
        }
        .onAppear {
            if !appState.appProfiles.contains(where: { $0.id == selectedProfileID }),
               let first = appState.appProfiles.first {
                selectedProfileID = first.id
            }
        }
    }

    private var profileHeaderCard: some View {
        SettingsCard(
            title: appState.localized("corners.profile"),
            systemImage: "app.badge.checkmark",
            accentColor: .blue
        ) {
            HStack(spacing: 10) {
                Picker("", selection: $selectedProfileID) {
                    ForEach(appState.appProfiles) { profile in
                        Text(profile.bundleIdentifier == nil ? appState.localized("corners.default") : profile.name)
                            .tag(profile.id)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(maxWidth: 260)

                Spacer()

                Button {
                    showingAddProfileSheet = true
                } label: {
                    Label(appState.localized("corners.addProfile"), systemImage: "plus")
                        .font(.system(size: 11.5, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                if selectedProfile.bundleIdentifier != nil {
                    Button(role: .destructive) {
                        deleteProfile(selectedProfile)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help(appState.localized("corners.deleteProfile"))
                }
            }

            if selectedProfile.bundleIdentifier != nil {
                Divider()
                HStack(spacing: 12) {
                    Toggle(
                        appState.localized("corners.profileEnabled"),
                        isOn: profileEnabledBinding(for: selectedProfileIndex)
                    )
                    .font(.system(size: 12, weight: .medium))

                    Spacer()

                    if let bId = selectedProfile.bundleIdentifier {
                        Text(bId)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private func profileEnabledBinding(for index: Int) -> Binding<Bool> {
        Binding(
            get: {
                guard appState.appProfiles.indices.contains(index) else { return true }
                return appState.appProfiles[index].isEnabled
            },
            set: { enabled in
                guard appState.appProfiles.indices.contains(index) else { return }
                appState.appProfiles[index].isEnabled = enabled
                appState.saveSettings()
            }
        )
    }

    private func deleteProfile(_ profile: AppProfile) {
        guard profile.bundleIdentifier != nil else { return }
        appState.appProfiles.removeAll { $0.id == profile.id }
        if let first = appState.appProfiles.first {
            selectedProfileID = first.id
        }
        appState.saveSettings()
    }
}
