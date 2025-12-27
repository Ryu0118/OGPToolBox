import Foundation
import OGPCache

/// Represents the fetched OGP image data along with its metadata.
public struct OGPImageData: Sendable, Equatable {
    /// The raw image data.
    public let data: Data

    /// The MIME type of the image, if available.
    public let mimeType: String?

    /// The width of the image in pixels, if available from metadata.
    public let width: Int?

    /// The height of the image in pixels, if available from metadata.
    public let height: Int?

    /// Alternative text for the image, if available from metadata.
    public let alt: String?

    /// Creates a new OGP image data instance.
    ///
    /// - Parameters:
    ///   - data: The raw image data.
    ///   - mimeType: The MIME type of the image.
    ///   - width: The width in pixels.
    ///   - height: The height in pixels.
    ///   - alt: Alternative text.
    public init(
        data: Data,
        mimeType: String? = nil,
        width: Int? = nil,
        height: Int? = nil,
        alt: String? = nil
    ) {
        self.data = data
        self.mimeType = mimeType
        self.width = width
        self.height = height
        self.alt = alt
    }
}

extension OGPImageData: Codable {}

extension OGPImageData: MemorySizeEstimable {
    public var estimatedByteCount: Int {
        var size = data.count
        size += mimeType?.utf8.count ?? 0
        size += width.map { _ in MemoryLayout<Int>.size } ?? 0
        size += height.map { _ in MemoryLayout<Int>.size } ?? 0
        size += alt?.utf8.count ?? 0
        return size
    }
}
