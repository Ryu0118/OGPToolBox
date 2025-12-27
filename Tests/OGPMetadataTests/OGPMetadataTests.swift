import Foundation
import Testing

@testable import OGPMetadata

@Suite
struct OGPMetadataTests {
    @Test(arguments: ResolvedImageURLTestCase.allCases)
    func resolvedImageURL(_ testCase: ResolvedImageURLTestCase) {
        let metadata = OGPMetadata(
            imageURL: testCase.imageURL.flatMap { URL(string: $0) },
            imageSecureURL: testCase.imageSecureURL.flatMap { URL(string: $0) },
            twitterImageURL: testCase.twitterImageURL.flatMap { URL(string: $0) }
        )

        #expect(metadata.resolvedImageURL?.absoluteString == testCase.expectedURL)
    }

    struct ResolvedImageURLTestCase: CustomTestStringConvertible, Sendable {
        let imageURL: String?
        let imageSecureURL: String?
        let twitterImageURL: String?
        let expectedURL: String?
        let testDescription: String

        static let allCases: [ResolvedImageURLTestCase] = [
            ResolvedImageURLTestCase(
                imageURL: "http://example.com/image.jpg",
                imageSecureURL: "https://example.com/image.jpg",
                twitterImageURL: "https://twitter.example.com/image.jpg",
                expectedURL: "https://example.com/image.jpg",
                testDescription: "prefers secure URL"
            ),
            ResolvedImageURLTestCase(
                imageURL: "http://example.com/image.jpg",
                imageSecureURL: nil,
                twitterImageURL: "https://twitter.example.com/image.jpg",
                expectedURL: "http://example.com/image.jpg",
                testDescription: "falls back to og:image"
            ),
            ResolvedImageURLTestCase(
                imageURL: nil,
                imageSecureURL: nil,
                twitterImageURL: "https://twitter.example.com/image.jpg",
                expectedURL: "https://twitter.example.com/image.jpg",
                testDescription: "falls back to twitter:image"
            ),
            ResolvedImageURLTestCase(
                imageURL: nil,
                imageSecureURL: nil,
                twitterImageURL: nil,
                expectedURL: nil,
                testDescription: "returns nil when no images"
            ),
        ]
    }

    @Test(arguments: HasImageTestCase.allCases)
    func hasImage(_ testCase: HasImageTestCase) {
        let metadata = OGPMetadata(
            imageURL: testCase.imageURL.flatMap { URL(string: $0) }
        )

        #expect(metadata.hasImage == testCase.expected)
    }

    struct HasImageTestCase: CustomTestStringConvertible, Sendable {
        let imageURL: String?
        let expected: Bool
        let testDescription: String

        static let allCases: [HasImageTestCase] = [
            HasImageTestCase(
                imageURL: "https://example.com/image.jpg",
                expected: true,
                testDescription: "true when image exists"
            ),
            HasImageTestCase(
                imageURL: nil,
                expected: false,
                testDescription: "false when no image"
            ),
        ]
    }

    @Test
    func equatableConformance() {
        let metadata1 = OGPMetadata(
            imageURL: URL(string: "https://example.com/image.jpg"),
            imageWidth: 1200
        )
        let metadata2 = OGPMetadata(
            imageURL: URL(string: "https://example.com/image.jpg"),
            imageWidth: 1200
        )
        let metadata3 = OGPMetadata(
            imageURL: URL(string: "https://example.com/different.jpg")
        )

        #expect(metadata1 == metadata2)
        #expect(metadata1 != metadata3)
    }

    @Test(arguments: ResolvedVideoURLTestCase.allCases)
    func resolvedVideoURL(_ testCase: ResolvedVideoURLTestCase) {
        let metadata = OGPMetadata(
            videoURL: testCase.videoURL.flatMap { URL(string: $0) },
            videoSecureURL: testCase.videoSecureURL.flatMap { URL(string: $0) }
        )

        #expect(metadata.resolvedVideoURL?.absoluteString == testCase.expectedURL)
    }

    struct ResolvedVideoURLTestCase: CustomTestStringConvertible, Sendable {
        let videoURL: String?
        let videoSecureURL: String?
        let expectedURL: String?
        let testDescription: String

        static let allCases: [ResolvedVideoURLTestCase] = [
            ResolvedVideoURLTestCase(
                videoURL: "http://example.com/video.mp4",
                videoSecureURL: "https://example.com/video.mp4",
                expectedURL: "https://example.com/video.mp4",
                testDescription: "prefers secure URL"
            ),
            ResolvedVideoURLTestCase(
                videoURL: "http://example.com/video.mp4",
                videoSecureURL: nil,
                expectedURL: "http://example.com/video.mp4",
                testDescription: "falls back to og:video"
            ),
            ResolvedVideoURLTestCase(
                videoURL: nil,
                videoSecureURL: nil,
                expectedURL: nil,
                testDescription: "returns nil when no video"
            ),
        ]
    }

    @Test(arguments: ResolvedAudioURLTestCase.allCases)
    func resolvedAudioURL(_ testCase: ResolvedAudioURLTestCase) {
        let metadata = OGPMetadata(
            audioURL: testCase.audioURL.flatMap { URL(string: $0) },
            audioSecureURL: testCase.audioSecureURL.flatMap { URL(string: $0) }
        )

        #expect(metadata.resolvedAudioURL?.absoluteString == testCase.expectedURL)
    }

    struct ResolvedAudioURLTestCase: CustomTestStringConvertible, Sendable {
        let audioURL: String?
        let audioSecureURL: String?
        let expectedURL: String?
        let testDescription: String

        static let allCases: [ResolvedAudioURLTestCase] = [
            ResolvedAudioURLTestCase(
                audioURL: "http://example.com/audio.mp3",
                audioSecureURL: "https://example.com/audio.mp3",
                expectedURL: "https://example.com/audio.mp3",
                testDescription: "prefers secure URL"
            ),
            ResolvedAudioURLTestCase(
                audioURL: "http://example.com/audio.mp3",
                audioSecureURL: nil,
                expectedURL: "http://example.com/audio.mp3",
                testDescription: "falls back to og:audio"
            ),
            ResolvedAudioURLTestCase(
                audioURL: nil,
                audioSecureURL: nil,
                expectedURL: nil,
                testDescription: "returns nil when no audio"
            ),
        ]
    }

    @Test(arguments: HasVideoTestCase.allCases)
    func hasVideo(_ testCase: HasVideoTestCase) {
        let metadata = OGPMetadata(
            videoURL: testCase.videoURL.flatMap { URL(string: $0) }
        )

        #expect(metadata.hasVideo == testCase.expected)
    }

    struct HasVideoTestCase: CustomTestStringConvertible, Sendable {
        let videoURL: String?
        let expected: Bool
        let testDescription: String

        static let allCases: [HasVideoTestCase] = [
            HasVideoTestCase(
                videoURL: "https://example.com/video.mp4",
                expected: true,
                testDescription: "true when video exists"
            ),
            HasVideoTestCase(
                videoURL: nil,
                expected: false,
                testDescription: "false when no video"
            ),
        ]
    }

    @Test(arguments: HasAudioTestCase.allCases)
    func hasAudio(_ testCase: HasAudioTestCase) {
        let metadata = OGPMetadata(
            audioURL: testCase.audioURL.flatMap { URL(string: $0) }
        )

        #expect(metadata.hasAudio == testCase.expected)
    }

    struct HasAudioTestCase: CustomTestStringConvertible, Sendable {
        let audioURL: String?
        let expected: Bool
        let testDescription: String

        static let allCases: [HasAudioTestCase] = [
            HasAudioTestCase(
                audioURL: "https://example.com/audio.mp3",
                expected: true,
                testDescription: "true when audio exists"
            ),
            HasAudioTestCase(
                audioURL: nil,
                expected: false,
                testDescription: "false when no audio"
            ),
        ]
    }
}
