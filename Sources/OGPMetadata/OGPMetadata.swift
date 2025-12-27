import Foundation
import OGPCache

/// Represents parsed Open Graph Protocol metadata from a web page.
///
/// This struct contains all OGP image-related metadata extracted from
/// a web page's meta tags, including both standard OGP tags and
/// Twitter-specific tags.
public struct OGPMetadata: Sendable, Equatable, Codable {
    /// The URL of the image as specified by `og:image`.
    public let imageURL: URL?

    /// The secure (HTTPS) URL of the image as specified by `og:image:secure_url`.
    public let imageSecureURL: URL?

    /// The width of the image in pixels as specified by `og:image:width`.
    public let imageWidth: Int?

    /// The height of the image in pixels as specified by `og:image:height`.
    public let imageHeight: Int?

    /// The MIME type of the image as specified by `og:image:type`.
    public let imageType: String?

    /// Alternative text for the image as specified by `og:image:alt`.
    public let imageAlt: String?

    /// The URL of the Twitter card image as specified by `twitter:image`.
    public let twitterImageURL: URL?

    /// The Twitter card type as specified by `twitter:card`.
    public let twitterCard: TwitterCardType?

    /// Creates a new OGP metadata instance.
    ///
    /// - Parameters:
    ///   - imageURL: The URL from `og:image`.
    ///   - imageSecureURL: The URL from `og:image:secure_url`.
    ///   - imageWidth: The width from `og:image:width`.
    ///   - imageHeight: The height from `og:image:height`.
    ///   - imageType: The MIME type from `og:image:type`.
    ///   - imageAlt: The alt text from `og:image:alt`.
    ///   - twitterImageURL: The URL from `twitter:image`.
    ///   - twitterCard: The card type from `twitter:card`.
    public init(
        imageURL: URL? = nil,
        imageSecureURL: URL? = nil,
        imageWidth: Int? = nil,
        imageHeight: Int? = nil,
        imageType: String? = nil,
        imageAlt: String? = nil,
        twitterImageURL: URL? = nil,
        twitterCard: TwitterCardType? = nil
    ) {
        self.imageURL = imageURL
        self.imageSecureURL = imageSecureURL
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.imageType = imageType
        self.imageAlt = imageAlt
        self.twitterImageURL = twitterImageURL
        self.twitterCard = twitterCard
    }

    /// Returns the best available image URL.
    ///
    /// Priority order:
    /// 1. `og:image:secure_url` (HTTPS preferred)
    /// 2. `og:image`
    /// 3. `twitter:image`
    public var resolvedImageURL: URL? {
        imageSecureURL ?? imageURL ?? twitterImageURL
    }

    /// Returns `true` if any image URL is available.
    public var hasImage: Bool {
        resolvedImageURL != nil
    }
}

extension OGPMetadata: MemorySizeEstimable {
    public var estimatedByteCount: Int {
        var size = 0
        size += imageURL?.absoluteString.utf8.count ?? 0
        size += imageSecureURL?.absoluteString.utf8.count ?? 0
        size += imageWidth.map { _ in MemoryLayout<Int>.size } ?? 0
        size += imageHeight.map { _ in MemoryLayout<Int>.size } ?? 0
        size += imageType?.utf8.count ?? 0
        size += imageAlt?.utf8.count ?? 0
        size += twitterImageURL?.absoluteString.utf8.count ?? 0
        size += twitterCard.map { _ in MemoryLayout<TwitterCardType>.size } ?? 0
        return size
    }
}
