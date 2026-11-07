import SwiftUI
import AppKit
import MacStashCore

/// An instant floating scratchpad drawer for capturing ephemeral thoughts,
/// verification codes, terminal commands, or text snippets with automatic local persistence.
public struct ScratchpadView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var manager = ScratchpadManager.shared

    @State private var copyFeedback: Bool = false

    private let drawerWidth: CGFloat = Defaults.Scratchpad.defaultWidthPoints
    private let drawerHeight: CGFloat = Defaults.Scratchpad.defaultHeightPoints

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 1. Header Bar
            headerBar

            Divider()
                .background(Color.white.opacity(0.12))

            // 2. Text Editor Area
            editorArea
        }
        .frame(width: drawerWidth, height: drawerHeight)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.35), radius: 20, x: 4, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.green.opacity(0.6), Color.white.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.0
                )
        )
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "note.text")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.green)

            Text("SCRATCHPAD")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Spacer()

            Text("\(manager.wordCount)w · \(manager.characterCount)c")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.white.opacity(0.08)))

            // Copy All Button
            Button(action: {
                manager.copyAll()
                withAnimation(.easeInOut(duration: 0.15)) { copyFeedback = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeInOut(duration: 0.15)) { copyFeedback = false }
                }
            }) {
                Image(systemName: copyFeedback ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(copyFeedback ? .green : .secondary)
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                    )
            }
            .buttonStyle(.plain)
            .help("Copy All to Clipboard")

            // Clear Button
            Button(action: {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    manager.clear()
                }
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                    )
            }
            .buttonStyle(.plain)
            .help("Clear All")

            // Close Button
            Button(action: {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    manager.isScratchpadOpen = false
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.8))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .help("Close (Esc)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Editor Area

    private var editorArea: some View {
        ZStack(alignment: .topLeading) {
            if manager.text.isEmpty {
                Text("Type or paste quick notes, snippets, OTP codes, or prompts here...\nAutomatically saved.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary.opacity(0.6))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $manager.text)
                .font(.system(size: 12, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
