import Foundation

/// Fetches HTML content from a URL.
package actor HTMLFetcher: Sendable {
    private let session: URLSession

    package init(session: URLSession = .shared) {
        self.session = session
    }

    /// Fetches HTML content from the specified URL.
    /// - Parameter url: The URL to fetch HTML from.
    /// - Returns: The HTML content as a string.
    /// - Throws: `OGPError` if fetching fails.
    package func fetch(from url: URL) async throws -> String {
        let request = createRequest(for: url)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw OGPError.networkError(underlying: error)
        }

        try validateResponse(response)
        return decodeHTML(from: data)
    }

    private func createRequest(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("text/html", forHTTPHeaderField: "Accept")
        return request
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            return
        }
        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            throw OGPError.httpError(statusCode: httpResponse.statusCode)
        }
    }

    private func decodeHTML(from data: Data) -> String {
        if let html = String(data: data, encoding: .utf8) {
            return html
        }
        if let html = String(data: data, encoding: .isoLatin1) {
            return html
        }
        return String(data: data, encoding: .ascii) ?? ""
    }

    private var userAgent: String {
        "Mozilla/5.0 (compatible; OGPToolBox/1.0)"
    }
}
