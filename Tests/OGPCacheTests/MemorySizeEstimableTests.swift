import Foundation
import Testing

import OGPCache
import OGPMetadata

@Suite
struct MemorySizeEstimableTests {
    @Test(arguments: DataTestCase.allCases)
    func dataEstimatedByteCount(_ testCase: DataTestCase) {
        let data = Data(repeating: 0, count: testCase.byteCount)

        #expect(data.estimatedByteCount == testCase.byteCount)
    }

    struct DataTestCase: CustomTestStringConvertible, Sendable {
        let byteCount: Int
        let testDescription: String

        static let allCases: [DataTestCase] = [
            DataTestCase(byteCount: 0, testDescription: "empty data"),
            DataTestCase(byteCount: 1, testDescription: "single byte"),
            DataTestCase(byteCount: 1024, testDescription: "1KB"),
            DataTestCase(byteCount: 1024 * 1024, testDescription: "1MB"),
        ]
    }

    @Test
    func emptyMetadataHasZeroSize() {
        let metadata = OGPMetadata()

        #expect(metadata.estimatedByteCount == 0)
    }

    @Test
    func metadataWithImageURLIncludesURLSize() {
        let urlString = "https://example.com/image.jpg"
        let metadata = OGPMetadata(imageURL: URL(string: urlString))

        #expect(metadata.estimatedByteCount == urlString.utf8.count)
    }

    @Test
    func metadataWithMultipleURLsIncludesAllSizes() {
        let imageURL = "https://example.com/image.jpg"
        let secureURL = "https://secure.example.com/image.jpg"
        let twitterURL = "https://twitter.example.com/image.jpg"

        let metadata = OGPMetadata(
            imageURL: URL(string: imageURL),
            imageSecureURL: URL(string: secureURL),
            twitterImageURL: URL(string: twitterURL)
        )

        let expectedSize = imageURL.utf8.count + secureURL.utf8.count + twitterURL.utf8.count
        #expect(metadata.estimatedByteCount == expectedSize)
    }

    @Test
    func metadataWithDimensionsIncludesIntSizes() {
        let metadata = OGPMetadata(imageWidth: 1200, imageHeight: 630)

        let expectedSize = MemoryLayout<Int>.size * 2
        #expect(metadata.estimatedByteCount == expectedSize)
    }

    @Test
    func metadataWithStringPropertiesIncludesStringSizes() {
        let imageType = "image/jpeg"
        let imageAlt = "Example image description"

        let metadata = OGPMetadata(imageType: imageType, imageAlt: imageAlt)

        let expectedSize = imageType.utf8.count + imageAlt.utf8.count
        #expect(metadata.estimatedByteCount == expectedSize)
    }

    @Test
    func metadataWithTwitterCardIncludesEnumSize() {
        let metadata = OGPMetadata(twitterCard: .summaryLargeImage)

        #expect(metadata.estimatedByteCount == MemoryLayout<TwitterCardType>.size)
    }

    @Test
    func fullyPopulatedMetadataIncludesAllProperties() {
        let imageURL = "https://example.com/image.jpg"
        let secureURL = "https://secure.example.com/image.jpg"
        let twitterURL = "https://twitter.example.com/image.jpg"
        let imageType = "image/png"
        let imageAlt = "Alt text"

        let metadata = OGPMetadata(
            imageURL: URL(string: imageURL),
            imageSecureURL: URL(string: secureURL),
            imageWidth: 800,
            imageHeight: 600,
            imageType: imageType,
            imageAlt: imageAlt,
            twitterImageURL: URL(string: twitterURL),
            twitterCard: .summary
        )

        var expectedSize = 0
        expectedSize += imageURL.utf8.count
        expectedSize += secureURL.utf8.count
        expectedSize += MemoryLayout<Int>.size * 2 // width + height
        expectedSize += imageType.utf8.count
        expectedSize += imageAlt.utf8.count
        expectedSize += twitterURL.utf8.count
        expectedSize += MemoryLayout<TwitterCardType>.size

        #expect(metadata.estimatedByteCount == expectedSize)
    }
}
