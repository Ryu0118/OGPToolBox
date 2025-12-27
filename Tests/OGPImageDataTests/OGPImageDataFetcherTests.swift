import Foundation
import Testing

import OGPCache
@testable import OGPImageData

@Suite(.serialized)
struct OGPImageDataFetcherTests {
    @Test(arguments: BasicFetchTestCase.allCases)
    func basicFetch(_ testCase: BasicFetchTestCase) async throws {
        let pageURL = makeTestURL()
        let imageHost = UUID().uuidString + ".images.example.com"
        let imageURL = "https://\(imageHost)/image.jpg"
        let imageData = testCase.imageData

        let html = """
        <html>
        <head>
            <meta property="og:image" content="\(imageURL)">
            \(testCase.additionalMeta)
        </head>
        </html>
        """

        let session = makeMockSession()

        // Handler for the page
        MockURLProtocol.setHandler(for: pageURL.host!) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, html.data(using: .utf8)!)
        }

        // Handler for the image
        MockURLProtocol.setHandler(for: imageHost) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": testCase.contentType]
            )!
            return (response, imageData)
        }

        let fetcher = OGPImageDataFetcher(session: session)
        let result = try await fetcher.fetch(from: pageURL)

        #expect(result.data == imageData)
        #expect(result.mimeType == testCase.expectedMimeType)
        #expect(result.width == testCase.expectedWidth)
        #expect(result.height == testCase.expectedHeight)
    }

    struct BasicFetchTestCase: CustomTestStringConvertible, Sendable {
        let imageData: Data
        let contentType: String
        let additionalMeta: String
        let expectedMimeType: String?
        let expectedWidth: Int?
        let expectedHeight: Int?
        let testDescription: String

        static let allCases: [BasicFetchTestCase] = [
            BasicFetchTestCase(
                imageData: Data([0xFF, 0xD8, 0xFF, 0xE0]),
                contentType: "image/jpeg",
                additionalMeta: "",
                expectedMimeType: "image/jpeg",
                expectedWidth: nil,
                expectedHeight: nil,
                testDescription: "JPEG image without dimensions"
            ),
            BasicFetchTestCase(
                imageData: Data([0x89, 0x50, 0x4E, 0x47]),
                contentType: "image/png",
                additionalMeta: """
                <meta property="og:image:width" content="800">
                <meta property="og:image:height" content="600">
                """,
                expectedMimeType: "image/png",
                expectedWidth: 800,
                expectedHeight: 600,
                testDescription: "PNG image with dimensions"
            ),
            BasicFetchTestCase(
                imageData: Data([0x47, 0x49, 0x46, 0x38]),
                contentType: "image/gif",
                additionalMeta: """
                <meta property="og:image:alt" content="Test image">
                """,
                expectedMimeType: "image/gif",
                expectedWidth: nil,
                expectedHeight: nil,
                testDescription: "GIF image with alt text"
            ),
        ]
    }

    @Test(arguments: ImageURLResolutionTestCase.allCases)
    func imageURLResolution(_ testCase: ImageURLResolutionTestCase) async throws {
        let pageURL = makeTestURL()
        let imageHost = UUID().uuidString + ".images.example.com"
        let expectedImageURL = "https://\(imageHost)/resolved.jpg"
        let imageData = Data([0xFF, 0xD8, 0xFF, 0xE0])

        let html = testCase.html.replacingOccurrences(of: "{{IMAGE_URL}}", with: expectedImageURL)

        let session = makeMockSession()

        MockURLProtocol.setHandler(for: pageURL.host!) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, html.data(using: .utf8)!)
        }

        MockURLProtocol.setHandler(for: imageHost) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "image/jpeg"]
            )!
            return (response, imageData)
        }

        let fetcher = OGPImageDataFetcher(session: session)
        let result = try await fetcher.fetch(from: pageURL)

        #expect(result.data == imageData)
    }

    struct ImageURLResolutionTestCase: CustomTestStringConvertible, Sendable {
        let html: String
        let testDescription: String

        static let allCases: [ImageURLResolutionTestCase] = [
            ImageURLResolutionTestCase(
                html: """
                <html><head>
                <meta property="og:image:secure_url" content="{{IMAGE_URL}}">
                <meta property="og:image" content="http://other.com/image.jpg">
                </head></html>
                """,
                testDescription: "prefers secure_url over og:image"
            ),
            ImageURLResolutionTestCase(
                html: """
                <html><head>
                <meta property="og:image" content="{{IMAGE_URL}}">
                <meta name="twitter:image" content="http://twitter.com/image.jpg">
                </head></html>
                """,
                testDescription: "prefers og:image over twitter:image"
            ),
            ImageURLResolutionTestCase(
                html: """
                <html><head>
                <meta name="twitter:image" content="{{IMAGE_URL}}">
                </head></html>
                """,
                testDescription: "falls back to twitter:image"
            ),
        ]
    }

    @Test(arguments: ErrorTestCase.allCases)
    func errorHandling(_ testCase: ErrorTestCase) async {
        let pageURL = makeTestURL()
        let imageHost = UUID().uuidString + ".images.example.com"
        let imageURL = "https://\(imageHost)/image.jpg"

        let session = makeMockSession()

        switch testCase.scenario {
        case .noImageInMetadata:
            MockURLProtocol.setHandler(for: pageURL.host!) { request in
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (response, "<html><head></head></html>".data(using: .utf8)!)
            }

        case .imageFetchFailed:
            let html = """
            <html><head>
            <meta property="og:image" content="\(imageURL)">
            </head></html>
            """
            MockURLProtocol.setHandler(for: pageURL.host!) { request in
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (response, html.data(using: .utf8)!)
            }
            MockURLProtocol.setHandler(for: imageHost) { _ in
                throw URLError(.timedOut)
            }

        case .imageHTTPError:
            let html = """
            <html><head>
            <meta property="og:image" content="\(imageURL)">
            </head></html>
            """
            MockURLProtocol.setHandler(for: pageURL.host!) { request in
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (response, html.data(using: .utf8)!)
            }
            MockURLProtocol.setHandler(for: imageHost) { request in
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 404,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (response, Data())
            }

        case .emptyImageData:
            let html = """
            <html><head>
            <meta property="og:image" content="\(imageURL)">
            </head></html>
            """
            MockURLProtocol.setHandler(for: pageURL.host!) { request in
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (response, html.data(using: .utf8)!)
            }
            MockURLProtocol.setHandler(for: imageHost) { request in
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (response, Data())
            }

        case .invalidURLString:
            break // No handlers needed
        }

        let fetcher = OGPImageDataFetcher(session: session)

        await #expect(throws: Error.self) {
            if case .invalidURLString = testCase.scenario {
                try await fetcher.fetch(from: "not a valid url")
            } else {
                try await fetcher.fetch(from: pageURL)
            }
        }
    }

    enum ErrorScenario: Sendable {
        case noImageInMetadata
        case imageFetchFailed
        case imageHTTPError
        case emptyImageData
        case invalidURLString
    }

    struct ErrorTestCase: CustomTestStringConvertible, Sendable {
        let scenario: ErrorScenario
        let testDescription: String

        static let allCases: [ErrorTestCase] = [
            ErrorTestCase(scenario: .noImageInMetadata, testDescription: "throws when no image in metadata"),
            ErrorTestCase(scenario: .imageFetchFailed, testDescription: "throws on image network error"),
            ErrorTestCase(scenario: .imageHTTPError, testDescription: "throws on image HTTP error"),
            ErrorTestCase(scenario: .emptyImageData, testDescription: "throws on empty image data"),
            ErrorTestCase(scenario: .invalidURLString, testDescription: "throws on invalid URL string"),
        ]
    }

    @Test
    func fetchWithCacheReturnsFromCache() async throws {
        let pageURL = makeTestURL()
        let imageHost = UUID().uuidString + ".images.example.com"
        let imageURL = "https://\(imageHost)/image.jpg"
        let imageData = Data([0xFF, 0xD8, 0xFF, 0xE0])
        var pageRequestCount = 0
        var imageRequestCount = 0

        let html = """
        <html><head>
        <meta property="og:image" content="\(imageURL)">
        </head></html>
        """

        let session = makeMockSession()

        MockURLProtocol.setHandler(for: pageURL.host!) { request in
            pageRequestCount += 1
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, html.data(using: .utf8)!)
        }

        MockURLProtocol.setHandler(for: imageHost) { request in
            imageRequestCount += 1
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "image/jpeg"]
            )!
            return (response, imageData)
        }

        let cachePolicy = OGPCachePolicy<OGPImageData>(
            cacheSystem: .memory,
            ttl: .hours(1)
        )
        let fetcher = OGPImageDataFetcher(
            session: session,
            metadataCachePolicy: .none,
            imageCachePolicy: cachePolicy
        )

        let result1 = try await fetcher.fetch(from: pageURL)
        let result2 = try await fetcher.fetch(from: pageURL)

        // Image should be cached, so only one image request
        #expect(imageRequestCount == 1)
        #expect(result1 == result2)
    }

    @Test
    func fetchWithNoCacheMakesMultipleRequests() async throws {
        let pageURL = makeTestURL()
        let imageHost = UUID().uuidString + ".images.example.com"
        let imageURL = "https://\(imageHost)/image.jpg"
        let imageData = Data([0xFF, 0xD8, 0xFF, 0xE0])
        var imageRequestCount = 0

        let html = """
        <html><head>
        <meta property="og:image" content="\(imageURL)">
        </head></html>
        """

        let session = makeMockSession()

        MockURLProtocol.setHandler(for: pageURL.host!) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, html.data(using: .utf8)!)
        }

        MockURLProtocol.setHandler(for: imageHost) { request in
            imageRequestCount += 1
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "image/jpeg"]
            )!
            return (response, imageData)
        }

        let fetcher = OGPImageDataFetcher(
            session: session,
            metadataCachePolicy: .none,
            imageCachePolicy: .none
        )

        _ = try await fetcher.fetch(from: pageURL)
        _ = try await fetcher.fetch(from: pageURL)

        // Without cache, both requests should fetch the image
        #expect(imageRequestCount == 2)
    }
}
