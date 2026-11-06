import Foundation
import os.log

public enum AppLogger {
    private static let subsystem = "com.macstash.app"

    public static let lifecycle = Logger(subsystem: subsystem, category: "lifecycle")
    public static let hotcorner = Logger(subsystem: subsystem, category: "hotcorner")
    public static let brightness = Logger(subsystem: subsystem, category: "brightness")
    public static let timer = Logger(subsystem: subsystem, category: "timer")
    public static let display = Logger(subsystem: subsystem, category: "display")
    public static let settings = Logger(subsystem: subsystem, category: "settings")
    public static let audio = Logger(subsystem: subsystem, category: "audio")
    public static let updates = Logger(subsystem: subsystem, category: "updates")
}
