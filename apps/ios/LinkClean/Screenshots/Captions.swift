import Foundation

struct CaptionContent: Decodable {
    let headline: String
}

typealias CaptionsByFrame = [String: CaptionContent]

enum Captions {
    static func load(from url: URL) throws -> CaptionsByFrame {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(CaptionsByFrame.self, from: data)
    }
}
