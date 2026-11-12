import SwiftUI

extension View {
    /// Applies standardized VoiceOver description and optional value/hint for interactive controls.
    public func dsAccessibleControl(
        label: String,
        value: String? = nil,
        hint: String? = nil,
        isButton: Bool = true
    ) -> some View {
        self
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityValue(value ?? "")
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(isButton ? .isButton : [])
    }

    /// Applies standardized VoiceOver readout for non-interactive indicators or text badges.
    public func dsAccessibleReadout(
        label: String,
        value: String
    ) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityValue(value)
    }
}
