import OGPImageData
import OGPMetadata
import SwiftUI

struct OGPResultView: View {
    let result: FetchResult

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            imageSection
            metadataSection
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var imageSection: some View {
        if let uiImage = UIImage(data: result.imageData.data) {
            VStack(alignment: .leading, spacing: 8) {
                Text("OGP Image")
                    .font(.headline)
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Metadata")
                .font(.headline)

            MetadataRow(label: "Image URL", value: result.metadata.imageURL?.absoluteString)
            MetadataRow(label: "Secure URL", value: result.metadata.imageSecureURL?.absoluteString)
            MetadataRow(label: "Width", value: result.metadata.imageWidth.map(String.init))
            MetadataRow(label: "Height", value: result.metadata.imageHeight.map(String.init))
            MetadataRow(label: "MIME Type", value: result.imageData.mimeType)
            MetadataRow(label: "Alt Text", value: result.metadata.imageAlt)
            MetadataRow(label: "Twitter Card", value: result.metadata.twitterCard?.rawValue)
            MetadataRow(label: "Twitter Image", value: result.metadata.twitterImageURL?.absoluteString)
            MetadataRow(label: "Data Size", value: formatBytes(result.imageData.data.count))
        }
    }

    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct MetadataRow: View {
    let label: String
    let value: String?

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
            Text(value ?? "-")
                .font(.subheadline)
                .lineLimit(3)
        }
    }
}
