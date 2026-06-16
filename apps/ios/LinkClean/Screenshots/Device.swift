import Foundation

enum Device: String, CaseIterable {
    case iphone69
    case ipad13

    var canvasSize: CGSize {
        switch self {
        case .iphone69:
            CGSize(width: 1320, height: 2868)
        case .ipad13:
            CGSize(width: 2064, height: 2752)
        }
    }

    var outputPrefix: String {
        switch self {
        case .iphone69:
            "iPhone69-"
        case .ipad13:
            "iPad13-"
        }
    }

    var layout: ScreenshotComposer.Layout {
        switch self {
        case .iphone69:
            .iphone69
        case .ipad13:
            .ipad13
        }
    }
}
