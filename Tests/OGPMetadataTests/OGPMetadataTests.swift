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
}
