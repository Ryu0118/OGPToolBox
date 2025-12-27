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

    @Test(arguments: ParseOGVideoTestCase.allCases)
    func parseOGVideo(_ testCase: ParseOGVideoTestCase) throws {
        let metadata = try parser.parse(testCase.html)
        #expect(metadata.videoURL?.absoluteString == testCase.expectedURL)
        #expect(metadata.videoSecureURL?.absoluteString == testCase.expectedSecureURL)
        #expect(metadata.videoWidth == testCase.expectedWidth)
        #expect(metadata.videoHeight == testCase.expectedHeight)
        #expect(metadata.videoType == testCase.expectedType)
    }

    struct ParseOGVideoTestCase: CustomTestStringConvertible, Sendable {
        let html: String
        let expectedURL: String?
        let expectedSecureURL: String?
        let expectedWidth: Int?
        let expectedHeight: Int?
        let expectedType: String?
        let testDescription: String

        static let allCases: [ParseOGVideoTestCase] = [
            ParseOGVideoTestCase(
                html: """
                <html><head>
                <meta property="og:video" content="https://example.com/video.mp4">
                <meta property="og:video:secure_url" content="https://secure.example.com/video.mp4">
                <meta property="og:video:width" content="1920">
                <meta property="og:video:height" content="1080">
                <meta property="og:video:type" content="video/mp4">
                </head></html>
                """,
                expectedURL: "https://example.com/video.mp4",
                expectedSecureURL: "https://secure.example.com/video.mp4",
                expectedWidth: 1920,
                expectedHeight: 1080,
                expectedType: "video/mp4",
                testDescription: "all video metadata fields"
            ),
            ParseOGVideoTestCase(
                html: """
                <html><head>
                <meta property="og:video" content="https://example.com/video.mp4">
                </head></html>
                """,
                expectedURL: "https://example.com/video.mp4",
                expectedSecureURL: nil,
                expectedWidth: nil,
                expectedHeight: nil,
                expectedType: nil,
                testDescription: "video URL only"
            ),
            ParseOGVideoTestCase(
                html: "<html><head></head></html>",
                expectedURL: nil,
                expectedSecureURL: nil,
                expectedWidth: nil,
                expectedHeight: nil,
                expectedType: nil,
                testDescription: "no video metadata"
            ),
        ]
    }

    @Test(arguments: ParseOGAudioTestCase.allCases)
    func parseOGAudio(_ testCase: ParseOGAudioTestCase) throws {
        let metadata = try parser.parse(testCase.html)
        #expect(metadata.audioURL?.absoluteString == testCase.expectedURL)
        #expect(metadata.audioSecureURL?.absoluteString == testCase.expectedSecureURL)
        #expect(metadata.audioType == testCase.expectedType)
    }

    struct ParseOGAudioTestCase: CustomTestStringConvertible, Sendable {
        let html: String
        let expectedURL: String?
        let expectedSecureURL: String?
        let expectedType: String?
        let testDescription: String

        static let allCases: [ParseOGAudioTestCase] = [
            ParseOGAudioTestCase(
                html: """
                <html><head>
                <meta property="og:audio" content="https://example.com/audio.mp3">
                <meta property="og:audio:secure_url" content="https://secure.example.com/audio.mp3">
                <meta property="og:audio:type" content="audio/mpeg">
                </head></html>
                """,
                expectedURL: "https://example.com/audio.mp3",
                expectedSecureURL: "https://secure.example.com/audio.mp3",
                expectedType: "audio/mpeg",
                testDescription: "all audio metadata fields"
            ),
            ParseOGAudioTestCase(
                html: """
                <html><head>
                <meta property="og:audio" content="https://example.com/audio.mp3">
                </head></html>
                """,
                expectedURL: "https://example.com/audio.mp3",
                expectedSecureURL: nil,
                expectedType: nil,
                testDescription: "audio URL only"
            ),
            ParseOGAudioTestCase(
                html: "<html><head></head></html>",
                expectedURL: nil,
                expectedSecureURL: nil,
                expectedType: nil,
                testDescription: "no audio metadata"
            ),
        ]
    }

    @Test
    func parseAllMediaTypes() throws {
        let html = """
        <html><head>
        <meta property="og:image" content="https://example.com/image.jpg">
        <meta property="og:video" content="https://example.com/video.mp4">
        <meta property="og:video:type" content="video/mp4">
        <meta property="og:audio" content="https://example.com/audio.mp3">
        <meta property="og:audio:type" content="audio/mpeg">
        </head></html>
        """

        let metadata = try parser.parse(html)

        #expect(metadata.imageURL?.absoluteString == "https://example.com/image.jpg")
        #expect(metadata.videoURL?.absoluteString == "https://example.com/video.mp4")
        #expect(metadata.videoType == "video/mp4")
        #expect(metadata.audioURL?.absoluteString == "https://example.com/audio.mp3")
        #expect(metadata.audioType == "audio/mpeg")
    }
}
