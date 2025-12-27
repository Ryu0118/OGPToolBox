import Foundation
import OGPCache
import OGPCacheLive
import OGPCore

/// Fetches OGP metadata from web page URLs.
///
/// This fetcher retrieves HTML content from a URL and extracts OGP metadata.
/// It supports caching of parsed metadata to avoid redundant network requests
/// and HTML parsing.
///
/// - Note: This fetcher caches `OGPMetadata` (parsed result), not raw HTML.
///   If the cache hits, no network request is made. URLSession's own HTTP
///   caching operates independently and is controlled by the injected session.
public actor OGPMetadataFetcher: Sendable {
    private let htmlFetcher: HTMLFetcher
    private let parser: OGPMetadataParser
    private let cache: (any OGPCaching<OGPMetadata>)?

    /// Creates a new metadata fetcher.
    ///
    /// - Parameters:
    ///   - session: The URLSession to use for network requests.
    ///   - cachePolicy: The caching policy for metadata.
    public init(
        session: URLSession = .shared,
        cachePolicy: OGPCachePolicy<OGPMetadata> = .none
    ) {
        htmlFetcher = HTMLFetcher(session: session)
        parser = OGPMetadataParser()
        cache = CacheFactory.makeCache(for: cachePolicy, name: "OGPMetadata")
    }

    /// Creates a new metadata fetcher with an injected cache instance.
    ///
    /// This initializer is used by `OGPPipeline` to share cache instances
    /// across multiple fetchers.
    ///
    /// - Parameters:
    ///   - session: The URLSession to use for network requests.
    ///   - cache: The cache instance to use, or `nil` for no caching.
    package init(
        session: URLSession,
        cache: (any OGPCaching<OGPMetadata>)?
    ) {
        htmlFetcher = HTMLFetcher(session: session)
        parser = OGPMetadataParser()
        self.cache = cache
    }

    /// Fetches OGP metadata from the specified URL.
    ///
    /// - Parameter url: The web page URL to fetch metadata from.
    /// - Returns: The extracted OGP metadata.
    /// - Throws: `OGPError` if fetching or parsing fails.
    public func fetch(from url: URL) async throws -> OGPMetadata {
        let cacheKey = url.absoluteString

        // Check cache first
        if let cache, let cached = await cache.get(for: cacheKey) {
            return cached
        }

        // Fetch and parse
        let html = try await htmlFetcher.fetch(from: url)
        let metadata = try parser.parse(html)

        // Store in cache
        if let cache {
            await cache.set(metadata, for: cacheKey)
        }

        return metadata
    }

    /// Fetches OGP metadata from the specified URL string.
    ///
    /// - Parameter urlString: The web page URL string to fetch metadata from.
    /// - Returns: The extracted OGP metadata.
    /// - Throws: `OGPError.invalidURL` if the URL string is invalid,
    ///           or other `OGPError` if fetching or parsing fails.
    public func fetch(from urlString: String) async throws -> OGPMetadata {
        guard let url = URL(string: urlString) else {
            throw OGPError.invalidURL(urlString)
        }
        return try await fetch(from: url)
    }
}
