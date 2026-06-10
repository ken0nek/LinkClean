import Foundation

enum DebugMode {
    static var isScreenshotMode: Bool {
        #if DEBUG
        CommandLine.arguments.contains("-screenshotMode")
        #else
        false
        #endif
    }
}
