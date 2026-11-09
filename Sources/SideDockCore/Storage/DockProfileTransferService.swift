import Foundation

public struct ExportedProfilePackage: Codable, Sendable {
    public let schemaVersion: Int
    public let exportedAt: Date
    public let appVersion: String
    public let profile: DockProfile

    public init(
        schemaVersion: Int = 1,
        exportedAt: Date = Date(),
        appVersion: String = "2.11.0",
        profile: DockProfile
    ) {
        self.schemaVersion = schemaVersion
        self.exportedAt = exportedAt
        self.appVersion = appVersion
        self.profile = profile
    }
}

public struct DockProfileTransferService: Sendable {
    public init() {}

    /// Exports a dock profile as formatted JSON data.
    public func exportProfileJSON(profile: DockProfile) throws -> Data {
        let package = ExportedProfilePackage(profile: profile)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(package)
    }

    /// Imports a dock profile from JSON package data, assigning a fresh UUID to prevent collisions.
    public func importProfile(from data: Data) throws -> DockProfile {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let package = try? decoder.decode(ExportedProfilePackage.self, from: data) {
            var prof = package.profile
            prof.id = UUID()
            return prof
        }

        if var rawProfile = try? decoder.decode(DockProfile.self, from: data) {
            rawProfile.id = UUID()
            return rawProfile
        }

        throw DecodingError.dataCorrupted(
            DecodingError.Context(codingPath: [], debugDescription: "Invalid or unsupported .sidedock-profile file format")
        )
    }
}
