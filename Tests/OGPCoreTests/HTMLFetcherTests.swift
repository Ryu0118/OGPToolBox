import Foundation
import Testing

@testable import OGPCore

@Suite(.serialized)
struct HTMLFetcherTests {
    @Test
    func fetchReturnsHTMLContent() async throws {
        let testURL = makeTestURL()
        let expectedHTML = "<html><head></head><body>Test</body></html>"
        let session = makeMockSession()

        MockURLProtocol.setHandler(for: testURL.host!) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, expectedHTML.data(using: .utf8)!)
        }

        let fetcher = HTMLFetcher(session: session)
        let html = try await fetcher.fetch(from: testURL)

        #expect(html == expectedHTML)
    }

    @Test
    func fetchSetsCorrectHeaders() async throws {
        let testURL = makeTestURL()
        let session = makeMockSession()
        var capturedRequest: URLRequest?

        MockURLProtocol.setHandler(for: testURL.host!) { request in
            capturedRequest = request
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let fetcher = HTMLFetcher(session: session)
        _ = try await fetcher.fetch(from: testURL)

        #expect(capturedRequest?.value(forHTTPHeaderField: "User-Agent") == "Mozilla/5.0 (compatible; OGPToolBox/1.0)")
        #expect(capturedRequest?.value(forHTTPHeaderField: "Accept") == "text/html")
    }

    @Test(arguments: HTTPErrorTestCase.allCases)
    func fetchThrowsHTTPError(_ testCase: HTTPErrorTestCase) async {
        let testURL = makeTestURL()
        let session = makeMockSession()

        MockURLProtocol.setHandler(for: testURL.host!) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: testCase.statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let fetcher = HTMLFetcher(session: session)

        await #expect(throws: OGPError.self) {
            try await fetcher.fetch(from: testURL)
        }
    }

    struct HTTPErrorTestCase: CustomTestStringConvertible, Sendable {
        let statusCode: Int
        let testDescription: String

        static let allCases: [HTTPErrorTestCase] = [
            HTTPErrorTestCase(statusCode: 400, testDescription: "bad request"),
            HTTPErrorTestCase(statusCode: 404, testDescription: "not found"),
            HTTPErrorTestCase(statusCode: 500, testDescription: "internal server error"),
            HTTPErrorTestCase(statusCode: 503, testDescription: "service unavailable"),
        ]
    }

    @Test
    func fetchThrowsNetworkError() async {
        let testURL = makeTestURL()
        let session = makeMockSession()
        let expectedError = URLError(.notConnectedToInternet)

        MockURLProtocol.setHandler(for: testURL.host!) { _ in
            throw expectedError
        }

        let fetcher = HTMLFetcher(session: session)

        await #expect(throws: OGPError.self) {
            try await fetcher.fetch(from: testURL)
        }
    }

    @Test(arguments: EncodingTestCase.allCases)
    func fetchDecodesWithEncoding(_ testCase: EncodingTestCase) async throws {
        let testURL = makeTestURL()
        let session = makeMockSession()

        MockURLProtocol.setHandler(for: testURL.host!) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, testCase.html.data(using: testCase.encoding)!)
        }

        let fetcher = HTMLFetcher(session: session)
        let html = try await fetcher.fetch(from: testURL)

        #expect(html == testCase.html)
    }

    struct EncodingTestCase: CustomTestStringConvertible, Sendable {
        let html: String
        let encoding: String.Encoding
        let testDescription: String

        static let allCases: [EncodingTestCase] = [
            EncodingTestCase(
                html: "<html>UTF-8 content</html>",
                encoding: .utf8,
                testDescription: "UTF-8"
            ),
            EncodingTestCase(
                html: "<html>ISO Latin content</html>",
                encoding: .isoLatin1,
                testDescription: "ISO Latin 1"
            ),
            EncodingTestCase(
                html: "<html>ASCII content</html>",
                encoding: .ascii,
                testDescription: "ASCII"
            ),
        ]
    }

    @Test
    func fetchSucceedsWithStatusCode200() async throws {
        let testURL = makeTestURL()
        let session = makeMockSession()

        MockURLProtocol.setHandler(for: testURL.host!) { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, "<html></html>".data(using: .utf8)!)
        }

        let fetcher = HTMLFetcher(session: session)
        let html = try await fetcher.fetch(from: testURL)

        #expect(html == "<html></html>")
    }
}
