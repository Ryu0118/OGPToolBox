import Foundation
import Testing

@testable import OGPMetadata

@Suite
struct OGPMetadataParserTests {
    let parser = OGPMetadataParser()

    @Test(arguments: ParseOGImageTestCase.allCases)
    func parseOGImage(_ testCase: ParseOGImageTestCase) throws {
        let metadata = try parser.parse(testCase.html)
        #expect(metadata.imageURL?.absoluteString == testCase.expectedURL)
    }

    struct ParseOGImageTestCase: CustomTestStringConvertible, Sendable {
        let html: String
        let expectedURL: String?
        let testDescription: String

        static let allCases: [ParseOGImageTestCase] = [
            ParseOGImageTestCase(
                html: """
                <html><head>
                <meta property="og:image" content="https://example.com/image.jpg">
                </head></html>
                """,
                expectedURL: "https://example.com/image.jpg",
                testDescription: "standard og:image"
            ),
            ParseOGImageTestCase(
                html: """
                <html><head>
                <meta content="https://example.com/image.jpg" property="og:image">
                </head></html>
                """,
                expectedURL: "https://example.com/image.jpg",
                testDescription: "content before property"
            ),
            ParseOGImageTestCase(
                html: """
                <html><head>
                <META PROPERTY="OG:IMAGE" CONTENT="https://example.com/image.jpg">
                </head></html>
                """,
                expectedURL: "https://example.com/image.jpg",
                testDescription: "case insensitive"
            ),
            ParseOGImageTestCase(
                html: "<html><head><title>No OGP</title></head></html>",
                expectedURL: nil,
                testDescription: "no og:image tag"
            ),
        ]
    }

    @Test(arguments: ParseOGImageMetadataTestCase.allCases)
    func parseOGImageMetadata(_ testCase: ParseOGImageMetadataTestCase) throws {
        let metadata = try parser.parse(testCase.html)
        #expect(metadata.imageSecureURL?.absoluteString == testCase.expectedSecureURL)
        #expect(metadata.imageWidth == testCase.expectedWidth)
        #expect(metadata.imageHeight == testCase.expectedHeight)
        #expect(metadata.imageType == testCase.expectedType)
        #expect(metadata.imageAlt == testCase.expectedAlt)
    }

    struct ParseOGImageMetadataTestCase: CustomTestStringConvertible, Sendable {
        let html: String
        let expectedSecureURL: String?
        let expectedWidth: Int?
        let expectedHeight: Int?
        let expectedType: String?
        let expectedAlt: String?
        let testDescription: String

        static let allCases: [ParseOGImageMetadataTestCase] = [
            ParseOGImageMetadataTestCase(
                html: """
                <html><head>
                <meta property="og:image:secure_url" content="https://secure.example.com/image.jpg">
                <meta property="og:image:width" content="1200">
                <meta property="og:image:height" content="630">
                <meta property="og:image:type" content="image/jpeg">
                <meta property="og:image:alt" content="A sunset">
                </head></html>
                """,
                expectedSecureURL: "https://secure.example.com/image.jpg",
                expectedWidth: 1200,
                expectedHeight: 630,
                expectedType: "image/jpeg",
                expectedAlt: "A sunset",
                testDescription: "all metadata fields"
            ),
            ParseOGImageMetadataTestCase(
                html: "<html><head></head></html>",
                expectedSecureURL: nil,
                expectedWidth: nil,
                expectedHeight: nil,
                expectedType: nil,
                expectedAlt: nil,
                testDescription: "no metadata"
            ),
        ]
    }

    @Test(arguments: ParseTwitterTestCase.allCases)
    func parseTwitterTags(_ testCase: ParseTwitterTestCase) throws {
        let metadata = try parser.parse(testCase.html)
        #expect(metadata.twitterImageURL?.absoluteString == testCase.expectedImageURL)
        #expect(metadata.twitterCard == testCase.expectedCard)
    }

    struct ParseTwitterTestCase: CustomTestStringConvertible, Sendable {
        let html: String
        let expectedImageURL: String?
        let expectedCard: TwitterCardType?
        let testDescription: String

        static let allCases: [ParseTwitterTestCase] = [
            ParseTwitterTestCase(
                html: """
                <html><head>
                <meta name="twitter:image" content="https://twitter.example.com/image.jpg">
                <meta name="twitter:card" content="summary">
                </head></html>
                """,
                expectedImageURL: "https://twitter.example.com/image.jpg",
                expectedCard: .summary,
                testDescription: "summary card"
            ),
            ParseTwitterTestCase(
                html: """
                <html><head>
                <meta name="twitter:card" content="summary_large_image">
                </head></html>
                """,
                expectedImageURL: nil,
                expectedCard: .summaryLargeImage,
                testDescription: "summary_large_image card"
            ),
            ParseTwitterTestCase(
                html: """
                <html><head>
                <meta name="twitter:card" content="player">
                </head></html>
                """,
                expectedImageURL: nil,
                expectedCard: .player,
                testDescription: "player card"
            ),
            ParseTwitterTestCase(
                html: """
                <html><head>
                <meta name="twitter:card" content="app">
                </head></html>
                """,
                expectedImageURL: nil,
                expectedCard: .app,
                testDescription: "app card"
            ),
        ]
    }

    @Test
    func decodeHTMLEntities() throws {
        let html = """
        <html><head>
        <meta property="og:image:alt" content="Tom &amp; Jerry&#39;s &quot;Adventure&quot;">
        </head></html>
        """

        let metadata = try parser.parse(html)

        #expect(metadata.imageAlt == "Tom & Jerry's \"Adventure\"")
    }

    @Test
    func parseMultipleTags() throws {
        let html = """
        <html><head>
        <meta property="og:image" content="https://example.com/image.jpg">
        <meta property="og:image:width" content="1200">
        <meta name="twitter:image" content="https://twitter.example.com/image.jpg">
        <meta name="twitter:card" content="summary_large_image">
        </head></html>
        """

        let metadata = try parser.parse(html)

        #expect(metadata.imageURL?.absoluteString == "https://example.com/image.jpg")
        #expect(metadata.imageWidth == 1200)
        #expect(metadata.twitterImageURL?.absoluteString == "https://twitter.example.com/image.jpg")
        #expect(metadata.twitterCard == .summaryLargeImage)
    }
}
