import Foundation

/// Errors that can occur during OGP operations.
public enum OGPError: Error, Sendable {
    /// The provided URL is invalid or malformed.
    case invalidURL(String)

    /// A network error occurred while fetching the web page.
    case networkError(underlying: Error)

    /// The HTTP response returned a non-success status code.
    case httpError(statusCode: Int)

    /// Failed to parse the HTML content.
    case parsingError(reason: String)

    /// No OGP image metadata was found in the web page.
    case noImageFound

    /// Failed to fetch the image data from the image URL.
    case imageFetchError(underlying: Error)

    /// The fetched data is not a valid image.
    case invalidImageData
}

extension OGPError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .invalidURL(urlString):
            "Invalid URL: \(urlString)"
        case let .networkError(underlying):
            "Network error: \(underlying.localizedDescription)"
        case let .httpError(statusCode):
            "HTTP error with status code: \(statusCode)"
        case let .parsingError(reason):
            "Failed to parse HTML: \(reason)"
        case .noImageFound:
            "No OGP image found in the web page"
        case let .imageFetchError(underlying):
            "Failed to fetch image: \(underlying.localizedDescription)"
        case .invalidImageData:
            "The fetched data is not a valid image"
        }
    }
}
