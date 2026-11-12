import Foundation
import MacStashCore

public enum NowPlayingArtworkTests {
    public static func run() {
        testValidBase64SetsArtworkData()
        testUnchangedArtworkPreservesExistingCover()
        testMissingArtworkClearsStaleCoverEvenWhilePlaying()
        testLegacyPayloadWithoutHasArtworkClearsStaleCover()
        testContradictoryHasArtworkFalseOverridesUnchangedFlag()
        testEmptyOrInvalidBase64ClearsArtwork()
        testFallbackTransitionClearsWhenNilOrEmpty()
    }

    private static func testValidBase64SetsArtworkData() {
        let sampleBytes = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        let b64 = sampleBytes.base64EncodedString()

        let transition = NowPlayingArtworkPolicy.resolveHelperTransition(
            artworkBase64: b64,
            artworkUnchanged: false,
            hasArtwork: true
        )
        TestAssertion.assertEqual(transition, .set(sampleBytes), "Valid Base64 artwork payload should set new artwork bytes")
    }

    private static func testUnchangedArtworkPreservesExistingCover() {
        let modern = NowPlayingArtworkPolicy.resolveHelperTransition(
            artworkBase64: nil,
            artworkUnchanged: true,
            hasArtwork: true
        )
        TestAssertion.assertEqual(modern, .keepExisting, "Unchanged artwork with hasArtwork=true should keep existing artwork")

        let legacy = NowPlayingArtworkPolicy.resolveHelperTransition(
            artworkBase64: nil,
            artworkUnchanged: true,
            hasArtwork: nil
        )
        TestAssertion.assertEqual(legacy, .keepExisting, "Unchanged artwork with omitted hasArtwork should keep existing artwork")
    }

    private static func testMissingArtworkClearsStaleCoverEvenWhilePlaying() {
        // Reproduces switching in Music.app from a track with artwork to a playing track without artwork.
        let transition = NowPlayingArtworkPolicy.resolveHelperTransition(
            artworkBase64: nil,
            artworkUnchanged: false,
            hasArtwork: false
        )
        TestAssertion.assertEqual(transition, .clear, "Track without artwork must clear previous track artwork")
    }

    private static func testLegacyPayloadWithoutHasArtworkClearsStaleCover() {
        let transition = NowPlayingArtworkPolicy.resolveHelperTransition(
            artworkBase64: nil,
            artworkUnchanged: false,
            hasArtwork: nil
        )
        TestAssertion.assertEqual(transition, .clear, "Missing artworkBase64 with artworkUnchanged=false must clear artwork")
    }

    private static func testContradictoryHasArtworkFalseOverridesUnchangedFlag() {
        let transition = NowPlayingArtworkPolicy.resolveHelperTransition(
            artworkBase64: nil,
            artworkUnchanged: true,
            hasArtwork: false
        )
        TestAssertion.assertEqual(transition, .clear, "Explicit hasArtwork=false must clear artwork even if artworkUnchanged=true")
    }

    private static func testEmptyOrInvalidBase64ClearsArtwork() {
        let emptyTransition = NowPlayingArtworkPolicy.resolveHelperTransition(
            artworkBase64: "",
            artworkUnchanged: false,
            hasArtwork: false
        )
        TestAssertion.assertEqual(emptyTransition, .clear, "Empty Base64 string must clear artwork")

        let invalidTransition = NowPlayingArtworkPolicy.resolveHelperTransition(
            artworkBase64: "%%%not-valid-base64%%%",
            artworkUnchanged: false,
            hasArtwork: true
        )
        TestAssertion.assertEqual(invalidTransition, .clear, "Invalid Base64 string must clear artwork instead of keeping stale cover")
    }

    private static func testFallbackTransitionClearsWhenNilOrEmpty() {
        TestAssertion.assertEqual(
            NowPlayingArtworkPolicy.resolveFallbackTransition(artworkData: nil),
            .clear,
            "Fallback transition with nil artworkData must clear artwork"
        )
        TestAssertion.assertEqual(
            NowPlayingArtworkPolicy.resolveFallbackTransition(artworkData: Data()),
            .clear,
            "Fallback transition with empty artworkData must clear artwork"
        )

        let bytes = Data([0xFF, 0xD8, 0xFF, 0xE0])
        TestAssertion.assertEqual(
            NowPlayingArtworkPolicy.resolveFallbackTransition(artworkData: bytes),
            .set(bytes),
            "Fallback transition with valid artworkData must set artwork"
        )
    }
}
