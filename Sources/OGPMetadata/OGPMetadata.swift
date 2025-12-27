import Foundation
import OGPCache

/// Represents parsed Open Graph Protocol metadata from a web page.
///
/// This struct contains all OGP image-related metadata extracted from
/// a web page's meta tags, including both standard OGP tags and
/// Twitter-specific tags.
public struct OGPMetadata: Sendable, Equatable, Codable {
    // MARK: - Image Properties

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

    // MARK: - Video Properties

    /// The URL of the video as specified by `og:video`.
    public let videoURL: URL?

    /// The secure (HTTPS) URL of the video as specified by `og:video:secure_url`.
    public let videoSecureURL: URL?

    /// The width of the video in pixels as specified by `og:video:width`.
    public let videoWidth: Int?

    /// The height of the video in pixels as specified by `og:video:height`.
    public let videoHeight: Int?

    /// The MIME type of the video as specified by `og:video:type`.
    public let videoType: String?

    // MARK: - Audio Properties

    /// The URL of the audio as specified by `og:audio`.
    public let audioURL: URL?

    /// The secure (HTTPS) URL of the audio as specified by `og:audio:secure_url`.
    public let audioSecureURL: URL?

    /// The MIME type of the audio as specified by `og:audio:type`.
    public let audioType: String?

    // MARK: - Twitter Properties

    /// The URL of the Twitter card image as specified by `twitter:image`.
    public let twitterImageURL: URL?

    /// The Twitter card type as specified by `twitter:card`.
    public let twitterCard: TwitterCardType?

    // MARK: - Initialization

    /// Creates a new OGP metadata instance.
    ///
    /// - Parameters:
    ///   - imageURL: The URL from `og:image`.
    ///   - imageSecureURL: The URL from `og:image:secure_url`.
    ///   - imageWidth: The width from `og:image:width`.
    ///   - imageHeight: The height from `og:image:height`.
    ///   - imageType: The MIME type from `og:image:type`.
    ///   - imageAlt: The alt text from `og:image:alt`.
    ///   - videoURL: The URL from `og:video`.
    ///   - videoSecureURL: The URL from `og:video:secure_url`.
    ///   - videoWidth: The width from `og:video:width`.
    ///   - videoHeight: The height from `og:video:height`.
    ///   - videoType: The MIME type from `og:video:type`.
    ///   - audioURL: The URL from `og:audio`.
    ///   - audioSecureURL: The URL from `og:audio:secure_url`.
    ///   - audioType: The MIME type from `og:audio:type`.
    ///   - twitterImageURL: The URL from `twitter:image`.
    ///   - twitterCard: The card type from `twitter:card`.
    public init(
        imageURL: URL? = nil,
        imageSecureURL: URL? = nil,
        imageWidth: Int? = nil,
        imageHeight: Int? = nil,
        imageType: String? = nil,
        imageAlt: String? = nil,
        videoURL: URL? = nil,
        videoSecureURL: URL? = nil,
        videoWidth: Int? = nil,
        videoHeight: Int? = nil,
        videoType: String? = nil,
        audioURL: URL? = nil,
        audioSecureURL: URL? = nil,
        audioType: String? = nil,
        twitterImageURL: URL? = nil,
        twitterCard: TwitterCardType? = nil
    ) {
        self.imageURL = imageURL
        self.imageSecureURL = imageSecureURL
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.imageType = imageType
        self.imageAlt = imageAlt
        self.videoURL = videoURL
        self.videoSecureURL = videoSecureURL
        self.videoWidth = videoWidth
        self.videoHeight = videoHeight
        self.videoType = videoType
        self.audioURL = audioURL
        self.audioSecureURL = audioSecureURL
        self.audioType = audioType
        self.twitterImageURL = twitterImageURL
        self.twitterCard = twitterCard
    }

    // MARK: - Computed Properties

    /// Returns the best available image URL.
    ///
    /// Priority order:
    /// 1. `og:image:secure_url` (HTTPS preferred)
    /// 2. `og:image`
    /// 3. `twitter:image`
    public var resolvedImageURL: URL? {
        imageSecureURL ?? imageURL ?? twitterImageURL
    }

    /// Returns the best available video URL.
    ///
    /// Priority order:
    /// 1. `og:video:secure_url` (HTTPS preferred)
    /// 2. `og:video`
    public var resolvedVideoURL: URL? {
        videoSecureURL ?? videoURL
    }

    /// Returns the best available audio URL.
    ///
    /// Priority order:
    /// 1. `og:audio:secure_url` (HTTPS preferred)
    /// 2. `og:audio`
    public var resolvedAudioURL: URL? {
        audioSecureURL ?? audioURL
    }

    /// Returns `true` if any image URL is available.
    public var hasImage: Bool {
        resolvedImageURL != nil
    }

    /// Returns `true` if any video URL is available.
    public var hasVideo: Bool {
        resolvedVideoURL != nil
    }

    /// Returns `true` if any audio URL is available.
    public var hasAudio: Bool {
        resolvedAudioURL != nil
    }
}

extension OGPMetadata: MemorySizeEstimable {
    public var estimatedByteCount: Int {
        var size = 0
        // Image properties
        size += imageURL?.absoluteString.utf8.count ?? 0
        size += imageSecureURL?.absoluteString.utf8.count ?? 0
        size += imageWidth.map { _ in MemoryLayout<Int>.size } ?? 0
        size += imageHeight.map { _ in MemoryLayout<Int>.size } ?? 0
        size += imageType?.utf8.count ?? 0
        size += imageAlt?.utf8.count ?? 0
        // Video properties
        size += videoURL?.absoluteString.utf8.count ?? 0
        size += videoSecureURL?.absoluteString.utf8.count ?? 0
        size += videoWidth.map { _ in MemoryLayout<Int>.size } ?? 0
        size += videoHeight.map { _ in MemoryLayout<Int>.size } ?? 0
        size += videoType?.utf8.count ?? 0
        // Audio properties
        size += audioURL?.absoluteString.utf8.count ?? 0
        size += audioSecureURL?.absoluteString.utf8.count ?? 0
        size += audioType?.utf8.count ?? 0
        // Twitter properties
        size += twitterImageURL?.absoluteString.utf8.count ?? 0
        size += twitterCard.map { _ in MemoryLayout<TwitterCardType>.size } ?? 0
        return size
    }
}
