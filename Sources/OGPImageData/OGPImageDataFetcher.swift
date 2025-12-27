import Foundation
import OGPCache
import OGPCacheLive
import OGPCore
import OGPMetadata

/// Fetches OGP image data from web page URLs.
///
/// This fetcher retrieves OGP metadata from a URL, extracts the image URL,
/// and downloads the image data. It supports caching of image data to avoid
/// redundant network requests.
public actor OGPImageDataFetcher: Sendable {
    private let metadataFetcher: OGPMetadataFetcher
    private let session: URLSession
    private let cache: (any OGPCaching<OGPImageData>)?

    /// Creates a new image data fetcher.
    ///
    /// - Parameters:
    ///   - session: The URLSession to use for network requests.
    ///   - metadataCachePolicy: The caching policy for metadata.
    ///   - imageCachePolicy: The caching policy for image data.
    public init(
        session: URLSession = .shared,
        metadataCachePolicy: OGPCachePolicy<OGPMetadata> = .none,
        imageCachePolicy: OGPCachePolicy<OGPImageData> = .none
    ) {
        metadataFetcher = OGPMetadataFetcher(
            session: session,
            cachePolicy: metadataCachePolicy
        )
        self.session = session
        cache = CacheFactory.makeCache(for: imageCachePolicy, name: "OGPImageData")
    }

    /// Fetches OGP image data from the specified URL.
    ///
    /// - Parameter url: The web page URL to fetch the OGP image from.
    /// - Returns: The fetched image data with metadata.
    /// - Throws: `OGPError` if fetching fails or no image is found.
    public func fetch(from url: URL) async throws -> OGPImageData {
        let cacheKey = url.absoluteString

        // Check cache first
        if let cache, let cached = await cache.get(for: cacheKey) {
            return cached
        }

        // Fetch metadata
        let metadata = try await metadataFetcher.fetch(from: url)

        // Resolve image URL
        guard let imageURL = metadata.resolvedImageURL else {
            throw OGPError.noImageFound
        }

        // Fetch image data
        let imageData = try await fetchImageData(from: imageURL, metadata: metadata)

        // Store in cache
        if let cache {
            await cache.set(imageData, for: cacheKey)
        }

        return imageData
    }

    /// Fetches OGP image data from the specified URL string.
    ///
    /// - Parameter urlString: The web page URL string to fetch the OGP image from.
    /// - Returns: The fetched image data with metadata.
    /// - Throws: `OGPError.invalidURL` if the URL string is invalid,
    ///           or other `OGPError` if fetching fails.
    public func fetch(from urlString: String) async throws -> OGPImageData {
        guard let url = URL(string: urlString) else {
            throw OGPError.invalidURL(urlString)
        }
        return try await fetch(from: url)
    }

    private func fetchImageData(from imageURL: URL, metadata: OGPMetadata) async throws -> OGPImageData {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(from: imageURL)
        } catch {
            throw OGPError.imageFetchError(underlying: error)
        }

        // Check HTTP status code
        if let httpResponse = response as? HTTPURLResponse,
           !(200 ..< 300).contains(httpResponse.statusCode)
        {
            throw OGPError.httpError(statusCode: httpResponse.statusCode)
        }

        // Validate image data
        guard !data.isEmpty else {
            throw OGPError.invalidImageData
        }

        // Extract MIME type from response or metadata
        let mimeType = (response as? HTTPURLResponse)?.mimeType ?? metadata.imageType

        return OGPImageData(
            data: data,
            mimeType: mimeType,
            width: metadata.imageWidth,
            height: metadata.imageHeight,
            alt: metadata.imageAlt
        )
    }
}
