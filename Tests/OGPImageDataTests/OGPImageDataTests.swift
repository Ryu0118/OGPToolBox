import Foundation
import Testing

@testable import OGPImageData

@Suite
struct OGPImageDataTests {
    @Test
    func initializesWithAllProperties() {
        let data = Data([0xFF, 0xD8, 0xFF, 0xE0])
        let imageData = OGPImageData(
            data: data,
            mimeType: "image/jpeg",
            width: 1200,
            height: 630,
            alt: "Test image"
        )

        #expect(imageData.data == data)
        #expect(imageData.mimeType == "image/jpeg")
        #expect(imageData.width == 1200)
        #expect(imageData.height == 630)
        #expect(imageData.alt == "Test image")
    }

    @Test
    func initializesWithMinimalProperties() {
        let data = Data([0x89, 0x50, 0x4E, 0x47])
        let imageData = OGPImageData(data: data)

        #expect(imageData.data == data)
        #expect(imageData.mimeType == nil)
        #expect(imageData.width == nil)
        #expect(imageData.height == nil)
        #expect(imageData.alt == nil)
    }

    @Test
    func estimatedByteCountReflectsDataSize() {
        let smallData = Data([0x01, 0x02, 0x03])
        let smallImage = OGPImageData(data: smallData)
        #expect(smallImage.estimatedByteCount >= 3)

        let largeData = Data(repeating: 0xFF, count: 1000)
        let largeImage = OGPImageData(data: largeData)
        #expect(largeImage.estimatedByteCount >= 1000)
    }

    @Test
    func estimatedByteCountIncludesMetadata() {
        let data = Data([0x01])
        let withMetadata = OGPImageData(
            data: data,
            mimeType: "image/png",
            width: 100,
            height: 100,
            alt: "Test"
        )
        let withoutMetadata = OGPImageData(data: data)

        #expect(withMetadata.estimatedByteCount > withoutMetadata.estimatedByteCount)
    }

    @Test
    func equatableComparesAllProperties() {
        let data = Data([0xFF, 0xD8])

        let image1 = OGPImageData(
            data: data,
            mimeType: "image/jpeg",
            width: 100,
            height: 100,
            alt: "Alt"
        )

        let image2 = OGPImageData(
            data: data,
            mimeType: "image/jpeg",
            width: 100,
            height: 100,
            alt: "Alt"
        )

        let image3 = OGPImageData(
            data: data,
            mimeType: "image/png",
            width: 100,
            height: 100,
            alt: "Alt"
        )

        #expect(image1 == image2)
        #expect(image1 != image3)
    }

    @Test
    func codableRoundTrip() throws {
        let original = OGPImageData(
            data: Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]),
            mimeType: "image/jpeg",
            width: 1920,
            height: 1080,
            alt: "Test image description"
        )

        let encoder = JSONEncoder()
        let encoded = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(OGPImageData.self, from: encoded)

        #expect(decoded == original)
    }
}
