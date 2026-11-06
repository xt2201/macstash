import SwiftUI
import AppKit

public struct QuickLauncherSheet: View {
    @ObservedObject var appState: AppState
    @State private var searchText: String = ""
    @State private var selectedIndex: Int = 0

    private var filteredApps: [DockItem] {
        let all = appState.appManager.installedApps
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return Array(all.prefix(12))
        }
        return all.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Search Input Header
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)

                TextField("Search and launch applications...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .onSubmit {
                        launchSelectedApp()
                    }

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Button("Esc") {
                    appState.isQuickLauncherPresented = false
                }
                .font(.system(size: 11, weight: .bold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.secondary.opacity(0.2)))
                .buttonStyle(.plain)
            }
            .padding(16)

            Divider()

            // App Results List
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(Array(filteredApps.prefix(8).enumerated()), id: \.element.id) { index, item in
                        let isSelected = index == selectedIndex
                        Button(action: {
                            item.launch()
                            appState.isQuickLauncherPresented = false
                        }) {
                            HStack(spacing: 12) {
                                Image(nsImage: item.icon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 32, height: 32)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(isSelected ? .white : .primary)

                                    Text(item.bundleIdentifier)
                                        .font(.system(size: 10))
                                        .foregroundColor(isSelected ? Color.white.opacity(0.8) : .secondary)
                                }

                                Spacer()

                                if isSelected {
                                    Image(systemName: "return")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(isSelected ? Color.accentColor : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
            }
            .frame(maxHeight: 320)
        }
        .frame(width: 520)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.35), radius: 24, x: 0, y: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .padding(20)
    }

    private func launchSelectedApp() {
        if let first = filteredApps.first {
            first.launch()
            appState.isQuickLauncherPresented = false
        }
    }
}
