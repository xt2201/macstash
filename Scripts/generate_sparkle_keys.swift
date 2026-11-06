import Foundation
import CryptoKit

let privateKey = Curve25519.Signing.PrivateKey()
let pubKey = privateKey.publicKey.rawRepresentation.base64EncodedString()
let privKey = privateKey.rawRepresentation.base64EncodedString()

let keys = [
    "public_key": pubKey,
    "private_key": privKey
]

let jsonData = try! JSONSerialization.data(withJSONObject: keys, options: [.prettyPrinted, .sortedKeys])
let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Scripts/.sparkle_keys.json"
try! jsonData.write(to: URL(fileURLWithPath: outPath))

print("GENERATED_PUBLIC_KEY=\(pubKey)")
