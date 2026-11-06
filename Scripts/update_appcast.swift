import Foundation

// Usage:
// swift Scripts/update_appcast.swift <version> <build_number> <zip_file> <ed_signature> [release_notes_file_or_string]

guard CommandLine.arguments.count >= 5 else {
    fputs("Usage: swift update_appcast.swift <version> <build_number> <zip_file> <ed_signature> [release_notes]\n", stderr)
    exit(1)
}

let version = CommandLine.arguments[1]
let buildNumber = CommandLine.arguments[2]
let zipPath = CommandLine.arguments[3]
let signature = CommandLine.arguments[4]
var releaseNotes = CommandLine.arguments.count > 5 ? CommandLine.arguments[5] : ""

let zipURL = URL(fileURLWithPath: zipPath)
guard let zipData = try? Data(contentsOf: zipURL) else {
    fputs("Error: Could not read zip file at \(zipPath)\n", stderr)
    exit(1)
}
let fileLength = zipData.count

let appcastPath = "appcast.xml"
let appcastURL = URL(fileURLWithPath: appcastPath)

let rfc2822Formatter = DateFormatter()
rfc2822Formatter.locale = Locale(identifier: "en_US_POSIX")
rfc2822Formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
let pubDate = rfc2822Formatter.string(from: Date())

if releaseNotes.isEmpty {
    releaseNotes = """
<h2>What's New in Stash \(version)</h2>
<ul>
    <li>Industry standard 1-click in-place background auto-updates via Sparkle 2.</li>
    <li>Ed25519 cryptographic update signing and verification.</li>
    <li>Screen corner responsiveness and dynamic display tracking improvements.</li>
    <li>Menu bar icon and native macOS visual polish.</li>
</ul>
"""
} else if FileManager.default.fileExists(atPath: releaseNotes),
          let fileContent = try? String(contentsOfFile: releaseNotes, encoding: .utf8) {
    releaseNotes = fileContent
}

let downloadURL = "https://github.com/xt2201/macstash/releases/download/v\(version)/Stash-\(version).zip"

let newItem = """
        <item>
            <title>Version \(version)</title>
            <pubDate>\(pubDate)</pubDate>
            <sparkle:version>\(buildNumber)</sparkle:version>
            <sparkle:shortVersionString>\(version)</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
            <description><![CDATA[
\(releaseNotes.trimmingCharacters(in: .whitespacesAndNewlines))
            ]]></description>
            <enclosure
                url="\(downloadURL)"
                sparkle:edSignature="\(signature)"
                length="\(fileLength)"
                type="application/octet-stream" />
        </item>
"""

var existingContent = ""
if FileManager.default.fileExists(atPath: appcastPath),
   let content = try? String(contentsOf: appcastURL, encoding: .utf8) {
    existingContent = content
}

let finalXML: String
if existingContent.contains("<channel>") {
    let escapedVersion = NSRegularExpression.escapedPattern(for: version)
    let pattern = "\\s*<item>(?:(?!</item>)[\\s\\S])*?<sparkle:shortVersionString>\(escapedVersion)</sparkle:shortVersionString>(?:(?!</item>)[\\s\\S])*?</item>"
    var cleaned = existingContent
    if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
        let range = NSRange(cleaned.startIndex..<cleaned.endIndex, in: cleaned)
        cleaned = regex.stringByReplacingMatches(in: cleaned, options: [], range: range, withTemplate: "")
    }

    if let channelRange = cleaned.range(of: "<language>en</language>") {
        var updated = cleaned
        updated.insert(contentsOf: "\n" + newItem, at: channelRange.upperBound)
        finalXML = updated
    } else {
        finalXML = cleaned
    }
} else {
    finalXML = """
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
    <channel>
        <title>Stash Changelog</title>
        <link>https://raw.githubusercontent.com/xt2201/macstash/main/appcast.xml</link>
        <description>Most recent changes with links to updates.</description>
        <language>en</language>
\(newItem)
    </channel>
</rss>
"""
}

try! finalXML.write(to: appcastURL, atomically: true, encoding: .utf8)
print("Updated \(appcastPath) with version \(version).")
