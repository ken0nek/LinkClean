import Foundation

enum ScreenshotFrame: String, CaseIterable {
    case home = "01_home"
    case history = "02_history"
    case parameters = "03_parameters"

    var outputSuffix: String {
        switch self {
        case .home:
            "1-home"
        case .history:
            "2-history"
        case .parameters:
            "3-parameters"
        }
    }
}
