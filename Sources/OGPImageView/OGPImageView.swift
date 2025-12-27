import OGPCache
import OGPImageData
import OGPMetadata
import SwiftUI

/// A SwiftUI view that asynchronously loads and displays an OGP image from a URL.
///
/// This view handles the complete lifecycle of fetching OGP metadata from a web page,
/// downloading the associated image, and displaying it. It supports customizable
/// placeholder and error views, as well as caching policies.
///
/// Example usage:
/// ```swift
/// OGPImageView(url: URL(string: "https://example.com")!)
///     .frame(width: 300, height: 200)
/// ```
@MainActor
public struct OGPImageView<Placeholder: View, ErrorContent: View>: View {
    private let url: URL
    private let placeholder: () -> Placeholder
    private let errorContent: (Error) -> ErrorContent
    private let contentMode: ContentMode
    private let fetcher: OGPImageDataFetcher

    @State private var phase: OGPImagePhase = .empty

    /// Creates an OGP image view with custom placeholder and error views.
    ///
    /// - Parameters:
    ///   - url: The web page URL to fetch the OGP image from.
    ///   - contentMode: How the image should be scaled to fit the available space.
    ///   - metadataCachePolicy: The caching policy for OGP metadata.
    ///   - imageCachePolicy: The caching policy for image data.
    ///   - placeholder: A view builder that creates the placeholder view.
    ///   - error: A view builder that creates the error view.
    public init(
        url: URL,
        contentMode: ContentMode = .fit,
        metadataCachePolicy: OGPCachePolicy<OGPMetadata> = .none,
        imageCachePolicy: OGPCachePolicy<OGPImageData> = .none,
        @ViewBuilder placeholder: @escaping () -> Placeholder,
        @ViewBuilder error: @escaping (Error) -> ErrorContent
    ) {
        self.url = url
        self.contentMode = contentMode
        self.placeholder = placeholder
        errorContent = error
        fetcher = OGPImageDataFetcher(
            metadataCachePolicy: metadataCachePolicy,
            imageCachePolicy: imageCachePolicy
        )
    }

    public var body: some View {
        content
            .task(id: url) {
                await loadImage()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .empty:
            placeholder()

        case let .success(image):
            image
                .resizable()
                .aspectRatio(contentMode: contentMode)

        case let .failure(error):
            errorContent(error)

        @unknown default:
            placeholder()
        }
    }

    private func loadImage() async {
        phase = .empty

        do {
            let imageData = try await fetcher.fetch(from: url)
            guard let image = makeImage(from: imageData.data) else {
                phase = .failure(OGPImageViewError.invalidImageData)
                return
            }
            phase = .success(image)
        } catch {
            phase = .failure(error)
        }
    }

    private func makeImage(from data: Data) -> Image? {
        #if canImport(UIKit)
            guard let uiImage = UIImage(data: data) else { return nil }
            return Image(uiImage: uiImage)
        #elseif canImport(AppKit)
            guard let nsImage = NSImage(data: data) else { return nil }
            return Image(nsImage: nsImage)
        #else
            return nil
        #endif
    }
}

public extension OGPImageView where Placeholder == ProgressView<EmptyView, EmptyView>, ErrorContent == EmptyView {
    /// Creates an OGP image view with a default progress indicator placeholder.
    ///
    /// - Parameters:
    ///   - url: The web page URL to fetch the OGP image from.
    ///   - contentMode: How the image should be scaled to fit the available space.
    ///   - metadataCachePolicy: The caching policy for OGP metadata.
    ///   - imageCachePolicy: The caching policy for image data.
    init(
        url: URL,
        contentMode: ContentMode = .fit,
        metadataCachePolicy: OGPCachePolicy<OGPMetadata> = .none,
        imageCachePolicy: OGPCachePolicy<OGPImageData> = .none
    ) {
        self.init(
            url: url,
            contentMode: contentMode,
            metadataCachePolicy: metadataCachePolicy,
            imageCachePolicy: imageCachePolicy,
            placeholder: { ProgressView() },
            error: { _ in EmptyView() }
        )
    }
}

public extension OGPImageView where ErrorContent == EmptyView {
    /// Creates an OGP image view with a custom placeholder.
    ///
    /// - Parameters:
    ///   - url: The web page URL to fetch the OGP image from.
    ///   - contentMode: How the image should be scaled to fit the available space.
    ///   - metadataCachePolicy: The caching policy for OGP metadata.
    ///   - imageCachePolicy: The caching policy for image data.
    ///   - placeholder: A view builder that creates the placeholder view.
    init(
        url: URL,
        contentMode: ContentMode = .fit,
        metadataCachePolicy: OGPCachePolicy<OGPMetadata> = .none,
        imageCachePolicy: OGPCachePolicy<OGPImageData> = .none,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.init(
            url: url,
            contentMode: contentMode,
            metadataCachePolicy: metadataCachePolicy,
            imageCachePolicy: imageCachePolicy,
            placeholder: placeholder,
            error: { _ in EmptyView() }
        )
    }
}

/// The current phase of the asynchronous OGP image loading operation.
public enum OGPImagePhase: Sendable {
    /// No image is loaded.
    case empty

    /// An image successfully loaded.
    case success(Image)

    /// An image failed to load with an error.
    case failure(Error)
}

/// Errors that can occur during OGP image view operations.
public enum OGPImageViewError: Error, Sendable {
    /// The image data could not be decoded into an image.
    case invalidImageData
}
