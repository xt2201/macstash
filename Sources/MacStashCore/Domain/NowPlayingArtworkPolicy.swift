import Foundation

/// Pure state transition outcome for track artwork updates in `NowPlayingManager`.
public enum NowPlayingArtworkTransition: Equatable, Sendable {
    case set(Data)
    case keepExisting
    case clear
}

/// Pure domain policy resolving whether album artwork should be updated, preserved, or cleared
/// from MediaRemote helper payloads and in-process fallback queries.
public enum NowPlayingArtworkPolicy {
    /// Resolves the artwork transition for a JSON payload emitted by `MacStashNowPlaying`.
    public static func resolveHelperTransition(
        artworkBase64: String?,
        artworkUnchanged: Bool,
        hasArtwork: Bool?
    ) -> NowPlayingArtworkTransition {
        if let b64 = artworkBase64,
           !b64.isEmpty,
           let decoded = Data(base64Encoded: b64, options: .ignoreUnknownCharacters),
           !decoded.isEmpty {
            return .set(decoded)
        }

        if hasArtwork != false && artworkUnchanged {
            return .keepExisting
        }

        return .clear
    }

    /// Resolves the artwork transition for direct in-process MediaRemote fallback queries.
    public static func resolveFallbackTransition(artworkData: Data?) -> NowPlayingArtworkTransition {
        if let data = artworkData, !data.isEmpty {
            return .set(data)
        }
        return .clear
    }
}
