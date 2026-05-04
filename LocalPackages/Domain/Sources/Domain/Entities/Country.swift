import Foundation

/// ISO-3166 alpha-2 국가 코드 newtype.
/// 항상 대문자 2자 영문. invalid 입력은 init에서 nil 반환.
public struct Country: Sendable, Hashable, Codable, RawRepresentable {
    public let rawValue: String

    public init?(rawValue: String) {
        let normalized = rawValue.uppercased()
        guard normalized.count == 2,
              normalized.unicodeScalars.allSatisfy({ ("A"..."Z").contains(Character($0)) }) else {
            return nil
        }
        self.rawValue = normalized
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        guard let value = Country(rawValue: raw) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid ISO-3166 alpha-2 country code: \(raw)"
            )
        }
        self = value
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
