import Foundation
import Testing

import OGPCache
@testable import OGPCore
@testable import OGPMetadata

@Suite(.serialized)
struct OGPMetadataFetcherTests {
    @Test
    func fetchParsesOGPMetadata() async throws {
        let testURL = makeTestURL()
        let html = """
        <html>
        <head>
            <meta property="og:image" content="https://example.com/image.jpg">
            <meta property="og:image:width" content="1200">
            <meta property="og:image:height" content="630">
        </head>
        </html>
        """

        let session = makeMockSession()
        MockURLProtocol.setHandler(for: testURL.host!) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, html.data(using: .utf8)!)
        }

        let fetcher = OGPMetadataFetcher(session: session)
        let metadata = try await fetcher.fetch(from: testURL)

        #expect(metadata.imageURL?.absoluteString == "https://example.com/image.jpg")
        #expect(metadata.imageWidth == 1200)
        #expect(metadata.imageHeight == 630)
    }

    @Test
    func fetchFromURLStringWithValidURL() async throws {
        let testHost = UUID().uuidString + ".example.com"
        let testURLString = "https://\(testHost)"
        let html = """
        <html>
        <head>
            <meta property="og:image" content="https://example.com/image.jpg">
        </head>
        </html>
        """

        let session = makeMockSession()
        MockURLProtocol.setHandler(for: testHost) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, html.data(using: .utf8)!)
        }

        let fetcher = OGPMetadataFetcher(session: session)
        let metadata = try await fetcher.fetch(from: testURLString)

        #expect(metadata.imageURL?.absoluteString == "https://example.com/image.jpg")
    }

    @Test
    func fetchFromURLStringWithInvalidURLThrowsError() async {
        let fetcher = OGPMetadataFetcher()

        await #expect(throws: OGPError.self) {
            try await fetcher.fetch(from: "not a valid url")
        }
    }

    @Test
    func fetchReturnsEmptyMetadataWhenNoOGPTags() async throws {
        let testURL = makeTestURL()
        let html = "<html><head><title>No OGP</title></head></html>"

        let session = makeMockSession()
        MockURLProtocol.setHandler(for: testURL.host!) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, html.data(using: .utf8)!)
        }

        let fetcher = OGPMetadataFetcher(session: session)
        let metadata = try await fetcher.fetch(from: testURL)

        #expect(metadata.imageURL == nil)
        #expect(metadata.hasImage == false)
    }

    @Test
    func fetchWithCachePolicyNoneMakesMultipleRequests() async throws {
        let testURL = makeTestURL()
        var requestCount = 0
        let html = """
        <html>
        <head>
            <meta property="og:image" content="https://example.com/image.jpg">
        </head>
        </html>
        """

        let session = makeMockSession()
        MockURLProtocol.setHandler(for: testURL.host!) { request in
            requestCount += 1
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, html.data(using: .utf8)!)
        }

        let fetcher = OGPMetadataFetcher(session: session, cachePolicy: .none)

        // Fetch twice
        _ = try await fetcher.fetch(from: testURL)
        _ = try await fetcher.fetch(from: testURL)

        // Without cache, both requests should hit the network
        #expect(requestCount == 2)
    }

    @Test
    func fetchWithMemoryCacheReturnsFromCache() async throws {
        let testURL = makeTestURL()
        var requestCount = 0
        let html = """
        <html>
        <head>
            <meta property="og:image" content="https://example.com/image.jpg">
        </head>
        </html>
        """

        let session = makeMockSession()
        MockURLProtocol.setHandler(for: testURL.host!) { request in
            requestCount += 1
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, html.data(using: .utf8)!)
        }

        let cachePolicy = OGPCachePolicy<OGPMetadata>(
            cacheSystem: .memory,
            ttl: .hours(1)
        )
        let fetcher = OGPMetadataFetcher(session: session, cachePolicy: cachePolicy)

        // Fetch twice
        let metadata1 = try await fetcher.fetch(from: testURL)
        let metadata2 = try await fetcher.fetch(from: testURL)

        // With cache, only one request should hit the network
        #expect(requestCount == 1)
        #expect(metadata1 == metadata2)
    }

    @Test
    func fetchParsesTwitterCard() async throws {
        let testURL = makeTestURL()
        let html = """
        <html>
        <head>
            <meta name="twitter:card" content="summary_large_image">
            <meta name="twitter:image" content="https://twitter.example.com/image.jpg">
        </head>
        </html>
        """

        let session = makeMockSession()
        MockURLProtocol.setHandler(for: testURL.host!) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, html.data(using: .utf8)!)
        }

        let fetcher = OGPMetadataFetcher(session: session)
        let metadata = try await fetcher.fetch(from: testURL)

        #expect(metadata.twitterCard == .summaryLargeImage)
        #expect(metadata.twitterImageURL?.absoluteString == "https://twitter.example.com/image.jpg")
    }

    @Test
    func fetchThrowsOnHTTPError() async {
        let testURL = makeTestURL()
        let session = makeMockSession()
        MockURLProtocol.setHandler(for: testURL.host!) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let fetcher = OGPMetadataFetcher(session: session)

        await #expect(throws: OGPError.self) {
            try await fetcher.fetch(from: testURL)
        }
    }

    @Test
    func fetchThrowsOnNetworkError() async {
        let testURL = makeTestURL()
        let session = makeMockSession()
        MockURLProtocol.setHandler(for: testURL.host!) { _ in
            throw URLError(.timedOut)
        }

        let fetcher = OGPMetadataFetcher(session: session)

        await #expect(throws: OGPError.self) {
            try await fetcher.fetch(from: testURL)
        }
    }
}
