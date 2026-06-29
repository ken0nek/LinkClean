import Foundation

struct CaptionContent: Decodable {
    let headline: String
}

/// Frame id (e.g. `"01_home"`) → caption.
typealias CaptionsByFrame = [String: CaptionContent]

/// App Store locale code (e.g. `"en-US"`, `"ja"`, `"de-DE"`) → that locale's captions.
typealias CaptionsByLocale = [String: CaptionsByFrame]

enum Captions {
    static func load(from url: URL) throws -> CaptionsByLocale {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(CaptionsByLocale.self, from: data)
    }
}
