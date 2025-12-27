import Foundation
import OGPCache
import OGPImageData
import OGPMetadata

/// Configuration for the OGP pipeline.
///
/// Controls the caching behavior and network settings for fetching OGP metadata and images.
/// Use preset configurations for common use cases, or create custom configurations.
///
/// Example usage:
/// ```swift
/// // Use a preset configuration
/// OGPPipeline.shared = OGPPipeline(configuration: .aggressive)
///
/// // Or create a custom configuration
/// let config = OGPPipelineConfiguration(
///     session: .shared,
///     metadataCachePolicy: .init(cacheSystem: .memory, ttl: .hours(2)),
///     imageCachePolicy: .init(cacheSystem: .memoryAndDisk(), ttl: .days(7))
/// )
/// OGPPipeline.shared = OGPPipeline(configuration: config)
/// ```
public struct OGPPipelineConfiguration: Sendable {
    /// The URLSession to use for network requests.
    public let session: URLSession

    /// The caching policy for OGP metadata.
    public let metadataCachePolicy: OGPCachePolicy<OGPMetadata>

    /// The caching policy for OGP image data.
    public let imageCachePolicy: OGPCachePolicy<OGPImageData>

    /// Creates a new pipeline configuration.
    ///
    /// - Parameters:
    ///   - session: The URLSession to use for network requests. Defaults to `.shared`.
    ///   - metadataCachePolicy: The caching policy for OGP metadata. Defaults to memory cache with 1 hour TTL.
    ///   - imageCachePolicy: The caching policy for OGP image data. Defaults to memory and disk cache with 1 day TTL.
    public init(
        session: URLSession = .shared,
        metadataCachePolicy: OGPCachePolicy<OGPMetadata> = .init(
            cacheSystem: .memory,
            ttl: .hours(1),
            maxCount: .count(100)
        ),
        imageCachePolicy: OGPCachePolicy<OGPImageData> = .init(
            cacheSystem: .memoryAndDisk(),
            ttl: .days(1),
            maxCount: .count(100),
            maxSize: .megabytes(100)
        )
    ) {
        self.session = session
        self.metadataCachePolicy = metadataCachePolicy
        self.imageCachePolicy = imageCachePolicy
    }
}

// MARK: - Preset Configurations

public extension OGPPipelineConfiguration {
    /// Default configuration with balanced caching.
    ///
    /// - Metadata: Memory cache, 1 hour TTL, max 100 entries
    /// - Images: Memory + disk cache, 1 day TTL, max 100 MB
    static let `default` = OGPPipelineConfiguration()

    /// Memory-only caching for minimal disk usage.
    ///
    /// - Metadata: Memory cache, 1 hour TTL
    /// - Images: Memory cache only, 30 minutes TTL
    static let memoryOnly = OGPPipelineConfiguration(
        metadataCachePolicy: .init(
            cacheSystem: .memory,
            ttl: .hours(1),
            maxCount: .count(100)
        ),
        imageCachePolicy: .init(
            cacheSystem: .memory,
            ttl: .minutes(30),
            maxCount: .count(50),
            maxSize: .megabytes(50)
        )
    )

    /// Aggressive caching for offline support and faster loads.
    ///
    /// - Metadata: Memory + disk cache, 7 days TTL
    /// - Images: Memory + disk cache, 30 days TTL, 500 MB limit
    static let aggressive = OGPPipelineConfiguration(
        metadataCachePolicy: .init(
            cacheSystem: .memoryAndDisk(),
            ttl: .days(7),
            maxCount: .count(500)
        ),
        imageCachePolicy: .init(
            cacheSystem: .memoryAndDisk(),
            ttl: .days(30),
            maxCount: .count(500),
            maxSize: .megabytes(500)
        )
    )

    /// No caching. Every request fetches fresh data.
    static let noCache = OGPPipelineConfiguration(
        metadataCachePolicy: .none,
        imageCachePolicy: .none
    )
}
