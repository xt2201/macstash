import Foundation

public enum TestAssertion {
    public static var passCount: Int = 0
    public static var failCount: Int = 0

    public static func assertTrue(_ condition: Bool, _ message: String = "", file: String = #file, line: Int = #line) {
        if condition {
            passCount += 1
        } else {
            failCount += 1
            let filename = URL(fileURLWithPath: file).lastPathComponent
            fputs("[FAIL] \(filename):\(line) Expected true, got false. \(message)\n", stderr)
        }
    }

    public static func assertFalse(_ condition: Bool, _ message: String = "", file: String = #file, line: Int = #line) {
        assertTrue(!condition, message, file: file, line: line)
    }

    public static func assertEqual<T: Equatable>(_ a: T, _ b: T, _ message: String = "", file: String = #file, line: Int = #line) {
        if a == b {
            passCount += 1
        } else {
            failCount += 1
            let filename = URL(fileURLWithPath: file).lastPathComponent
            fputs("[FAIL] \(filename):\(line) Expected \(b), got \(a). \(message)\n", stderr)
        }
    }

    public static func assertThrows<T>(_ block: () throws -> T, _ message: String = "", file: String = #file, line: Int = #line) {
        do {
            _ = try block()
            failCount += 1
            let filename = URL(fileURLWithPath: file).lastPathComponent
            fputs("[FAIL] \(filename):\(line) Expected error thrown, but succeeded. \(message)\n", stderr)
        } catch {
            passCount += 1
        }
    }
}
