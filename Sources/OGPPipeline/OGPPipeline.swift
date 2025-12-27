import Foundation
import OGPCache
import OGPCacheLive
import OGPImageData
import OGPMetadata

/// A shared pipeline for fetching OGP metadata and images.
///
/// `OGPPipeline` provides a centralized, Nuke-style approach to OGP fetching with
/// shared cache instances. This ensures that cache is preserved across multiple
/// view instances and component lifecycles.
///
/// ## Basic Usage
///
/// The pipeline is typically used through the shared instance:
///
/// ```swift
/// // Fetch metadata
/// let metadata = try await OGPPipeline.shared.fetchMetadata(from: url)
///
/// // Fetch image data
/// let imageData = try await OGPPipeline.shared.fetchImage(from: url)
/// ```
///
/// ## Custom Configuration
///
/// Create a custom pipeline with a specific configuration:
///
/// ```swift
/// let pipeline = OGPPipeline(configuration: .aggressive)
/// ```
///
/// ## Memory Management
///
/// The pipeline owns its cache instances. When using memory caching, the cache
/// persists for the lifetime of the pipeline instance. Use `clearCache()` to
/// free memory when needed.
public final class OGPPipeline: Sendable {
    /// The shared pipeline instance with default configuration.
    ///
    /// Use this for quick access to OGP fetching with default caching settings.
    /// For custom configurations, create your own `OGPPipeline` instance.
    public static let shared = OGPPipeline()

    /// The pipeline configuration.
    public let configuration: OGPPipelineConfiguration

    private let metadataCache: (any OGPCaching<OGPMetadata>)?
    private let imageCache: (any OGPCaching<OGPImageData>)?
    private let metadataFetcher: OGPMetadataFetcher
    private let imageDataFetcher: OGPImageDataFetcher

    /// Creates a new pipeline with the specified configuration.
    ///
    /// - Parameter configuration: The pipeline configuration. Defaults to `.default`.
    public init(configuration: OGPPipelineConfiguration = .default) {
        self.configuration = configuration

        // Create cache instances once
        metadataCache = CacheFactory.makeCache(
            for: configuration.metadataCachePolicy,
            name: "OGPMetadata"
        )
        imageCache = CacheFactory.makeCache(
            for: configuration.imageCachePolicy,
            name: "OGPImageData"
        )

        // Create fetchers with injected cache instances
        metadataFetcher = OGPMetadataFetcher(
            session: configuration.session,
            cache: metadataCache
        )
        imageDataFetcher = OGPImageDataFetcher(
            session: configuration.session,
            metadataFetcher: metadataFetcher,
            cache: imageCache
        )
    }

    /// Fetches OGP metadata from the specified URL.
    ///
    /// The result is cached according to the pipeline configuration.
    ///
    /// - Parameter url: The web page URL to fetch metadata from.
    /// - Returns: The extracted OGP metadata.
    /// - Throws: `OGPError` if fetching or parsing fails.
    public func fetchMetadata(from url: URL) async throws -> OGPMetadata {
        try await metadataFetcher.fetch(from: url)
    }

    /// Fetches OGP metadata from the specified URL string.
    ///
    /// - Parameter urlString: The web page URL string to fetch metadata from.
    /// - Returns: The extracted OGP metadata.
    /// - Throws: `OGPError.invalidURL` if the URL string is invalid,
    ///           or other `OGPError` if fetching or parsing fails.
    public func fetchMetadata(from urlString: String) async throws -> OGPMetadata {
        try await metadataFetcher.fetch(from: urlString)
    }

    /// Fetches OGP image data from the specified URL.
    ///
    /// The result is cached according to the pipeline configuration.
    ///
    /// - Parameter url: The web page URL to fetch the OGP image from.
    /// - Returns: The fetched image data with metadata.
    /// - Throws: `OGPError` if fetching fails or no image is found.
    public func fetchImage(from url: URL) async throws -> OGPImageData {
        try await imageDataFetcher.fetch(from: url)
    }

    /// Fetches OGP image data from the specified URL string.
    ///
    /// - Parameter urlString: The web page URL string to fetch the OGP image from.
    /// - Returns: The fetched image data with metadata.
    /// - Throws: `OGPError.invalidURL` if the URL string is invalid,
    ///           or other `OGPError` if fetching fails.
    public func fetchImage(from urlString: String) async throws -> OGPImageData {
        try await imageDataFetcher.fetch(from: urlString)
    }

    /// Clears all cached data.
    ///
    /// Call this to free memory when the app receives a memory warning
    /// or when the cache is no longer needed.
    public func clearCache() async {
        async let metadataClear: Void = metadataCache?.clear() ?? ()
        async let imageClear: Void = imageCache?.clear() ?? ()
        _ = await (metadataClear, imageClear)
    }

    /// Removes cached data for a specific URL.
    ///
    /// - Parameter url: The URL to remove from cache.
    public func removeFromCache(url: URL) async {
        let key = url.absoluteString
        async let metadataRemove: Void = metadataCache?.remove(for: key) ?? ()
        async let imageRemove: Void = imageCache?.remove(for: key) ?? ()
        _ = await (metadataRemove, imageRemove)
    }
}
