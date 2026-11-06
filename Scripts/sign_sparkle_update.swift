import Foundation
import CryptoKit

guard CommandLine.arguments.count > 1 else {
    fputs("Usage: swift sign_sparkle_update.swift <archive_file> [private_key_base64]\n", stderr)
    exit(1)
}

let archivePath = CommandLine.arguments[1]
var privKeyBase64 = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : ""

if privKeyBase64.isEmpty {
    if let envKey = ProcessInfo.processInfo.environment["SPARKLE_PRIVATE_KEY"], !envKey.isEmpty {
        privKeyBase64 = envKey
    } else {
        // Try reading from Scripts/.sparkle_keys.json
        let jsonURL = URL(fileURLWithPath: "Scripts/.sparkle_keys.json")
        if let data = try? Data(contentsOf: jsonURL),
           let obj = try? JSONSerialization.jsonObject(with: data) as? [String: String],
           let k = obj["private_key"] {
            privKeyBase64 = k
        }
    }
}

guard !privKeyBase64.isEmpty, let rawPrivKey = Data(base64Encoded: privKeyBase64) else {
    fputs("Error: Could not locate private key for signing.\n", stderr)
    exit(1)
}

let archiveURL = URL(fileURLWithPath: archivePath)
guard let archiveData = try? Data(contentsOf: archiveURL) else {
    fputs("Error: Could not read archive file at \(archivePath)\n", stderr)
    exit(1)
}

do {
    let privateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: rawPrivKey)
    let signature = try privateKey.signature(for: archiveData)
    let sigBase64 = signature.base64EncodedString()
    let length = archiveData.count

    print("ED_SIGNATURE=\(sigBase64)")
    print("FILE_LENGTH=\(length)")
} catch {
    fputs("Signing failed: \(error.localizedDescription)\n", stderr)
    exit(1)
}
