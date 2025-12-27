import Foundation
import OGPCore

/// Parses HTML content to extract OGP metadata.
///
/// This parser extracts Open Graph Protocol meta tags and Twitter card
/// meta tags from HTML content using regex-based parsing.
public struct OGPMetadataParser: Sendable {
    /// Creates a new OGP metadata parser instance.
    public init() {}

    /// Parses HTML content and extracts OGP metadata.
    ///
    /// - Parameter html: The HTML content to parse.
    /// - Returns: The extracted OGP metadata.
    /// - Throws: `OGPError.parsingError` if parsing fails.
    public func parse(_ html: String) throws -> OGPMetadata {
        let metaTags = try extractMetaTags(from: html)
        return buildMetadata(from: metaTags)
    }
}

extension OGPMetadataParser {
    private typealias MetaTagMap = [String: String]

    private func extractMetaTags(from html: String) throws -> MetaTagMap {
        var tags: MetaTagMap = [:]

        let pattern = #"<meta\s+[^>]*(?:property|name)\s*=\s*["']([^"']+)["'][^>]*content\s*=\s*["']([^"']*)["'][^>]*>"#
        let alternatePattern = #"<meta\s+[^>]*content\s*=\s*["']([^"']*)["'][^>]*(?:property|name)\s*=\s*["']([^"']+)["'][^>]*>"#

        try extractMatches(from: html, pattern: pattern, keyIndex: 1, valueIndex: 2, into: &tags)
        try extractMatches(from: html, pattern: alternatePattern, keyIndex: 2, valueIndex: 1, into: &tags)

        return tags
    }

    private func extractMatches(
        from html: String,
        pattern: String,
        keyIndex: Int,
        valueIndex: Int,
        into tags: inout MetaTagMap
    ) throws {
        let regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        } catch {
            throw OGPError.parsingError(reason: "Invalid regex pattern")
        }

        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, options: [], range: range)

        for match in matches {
            guard match.numberOfRanges > max(keyIndex, valueIndex),
                  let keyRange = Range(match.range(at: keyIndex), in: html),
                  let valueRange = Range(match.range(at: valueIndex), in: html)
            else {
                continue
            }

            let key = String(html[keyRange]).lowercased()
            let value = decodeHTMLEntities(String(html[valueRange]))

            if key.hasPrefix("og:") || key.hasPrefix("twitter:") {
                tags[key] = value
            }
        }
    }

    private func buildMetadata(from tags: MetaTagMap) -> OGPMetadata {
        OGPMetadata(
            imageURL: extractURL(from: tags, key: "og:image"),
            imageSecureURL: extractURL(from: tags, key: "og:image:secure_url"),
            imageWidth: extractInt(from: tags, key: "og:image:width"),
            imageHeight: extractInt(from: tags, key: "og:image:height"),
            imageType: tags["og:image:type"],
            imageAlt: tags["og:image:alt"],
            videoURL: extractURL(from: tags, key: "og:video"),
            videoSecureURL: extractURL(from: tags, key: "og:video:secure_url"),
            videoWidth: extractInt(from: tags, key: "og:video:width"),
            videoHeight: extractInt(from: tags, key: "og:video:height"),
            videoType: tags["og:video:type"],
            audioURL: extractURL(from: tags, key: "og:audio"),
            audioSecureURL: extractURL(from: tags, key: "og:audio:secure_url"),
            audioType: tags["og:audio:type"],
            twitterImageURL: extractURL(from: tags, key: "twitter:image"),
            twitterCard: extractTwitterCardType(from: tags)
        )
    }

    private func extractURL(from tags: MetaTagMap, key: String) -> URL? {
        guard let urlString = tags[key], !urlString.isEmpty else {
            return nil
        }
        return URL(string: urlString)
    }

    private func extractInt(from tags: MetaTagMap, key: String) -> Int? {
        guard let value = tags[key] else {
            return nil
        }
        return Int(value)
    }

    private func extractTwitterCardType(from tags: MetaTagMap) -> TwitterCardType? {
        guard let value = tags["twitter:card"] else {
            return nil
        }
        return TwitterCardType(rawValue: value)
    }

    private func decodeHTMLEntities(_ string: String) -> String {
        var result = string
        let entities: [(String, String)] = [
            ("&amp;", "&"),
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&quot;", "\""),
            ("&#39;", "'"),
            ("&apos;", "'"),
        ]
        for (entity, character) in entities {
            result = result.replacingOccurrences(of: entity, with: character)
        }
        return result
    }
}
