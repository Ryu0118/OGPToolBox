import OGPPipeline
import SwiftUI

/// A SwiftUI view that asynchronously loads and displays an OGP image from a URL.
///
/// This view handles the complete lifecycle of fetching OGP metadata from a web page,
/// downloading the associated image, and displaying it.
///
/// The API design follows Apple's `AsyncImage` pattern with three initialization styles:
///
/// **Simple usage with default placeholder:**
/// ```swift
/// OGPImageView(url: URL(string: "https://example.com")!)
///     .frame(width: 300, height: 200)
/// ```
///
/// **Custom content and placeholder:**
/// ```swift
/// OGPImageView(url: url) { image in
///     image.resizable()
/// } placeholder: {
///     ProgressView()
/// }
/// ```
///
/// **Phase-based handling:**
/// ```swift
/// OGPImageView(url: url) { phase in
///     switch phase {
///     case .empty:
///         ProgressView()
///     case .success(let image):
///         image.resizable()
///     case .failure(let error):
///         Text(error.localizedDescription)
///     }
/// }
/// ```
///
/// The view uses `OGPPipeline.shared` by default, which provides shared caching across
/// all `OGPImageView` instances.
@MainActor
public struct OGPImageView<Content: View>: View {
    private let url: URL
    private let pipeline: OGPPipeline
    private let transaction: Transaction
    private let content: (OGPImagePhase) -> Content

    @State private var phase: OGPImagePhase = .empty

    /// Creates an OGP image view that handles loading phases.
    ///
    /// Use this initializer when you need complete control over the display
    /// in each loading phase.
    ///
    /// - Parameters:
    ///   - url: The web page URL to fetch the OGP image from.
    ///   - pipeline: The pipeline to use for fetching. Defaults to `.shared`.
    ///   - transaction: The transaction to use when the phase changes.
    ///   - content: A closure that returns a view for the current phase.
    public init(
        url: URL,
        pipeline: OGPPipeline = .shared,
        transaction: Transaction = Transaction(),
        @ViewBuilder content: @escaping (OGPImagePhase) -> Content
    ) {
        self.url = url
        self.pipeline = pipeline
        self.transaction = transaction
        self.content = content
    }

    public var body: some View {
        content(phase)
            .task(id: url) {
                await loadImage()
            }
    }

    private func loadImage() async {
        withTransaction(transaction) {
            phase = .empty
        }

        do {
            let imageData = try await pipeline.fetchImage(from: url)
            guard let image = makeImage(from: imageData.data) else {
                withTransaction(transaction) {
                    phase = .failure(OGPImageViewError.invalidImageData)
                }
                return
            }
            withTransaction(transaction) {
                phase = .success(image)
            }
        } catch {
            withTransaction(transaction) {
                phase = .failure(error)
            }
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

// MARK: - Content and placeholder initializer

public extension OGPImageView {
    /// Creates an OGP image view with custom content and placeholder.
    ///
    /// - Parameters:
    ///   - url: The web page URL to fetch the OGP image from.
    ///   - pipeline: The pipeline to use for fetching. Defaults to `.shared`.
    ///   - content: A closure that returns the view to display when the image loads.
    ///   - placeholder: A closure that returns the placeholder view.
    init<I: View, P: View>(
        url: URL,
        pipeline: OGPPipeline = .shared,
        @ViewBuilder content: @escaping (Image) -> I,
        @ViewBuilder placeholder: @escaping () -> P
    ) where Content == _ConditionalContent<I, P> {
        self.init(
            url: url,
            pipeline: pipeline,
            transaction: Transaction()
        ) { phase in
            if case let .success(image) = phase {
                content(image)
            } else {
                placeholder()
            }
        }
    }
}

// MARK: - Simple initializer

public extension OGPImageView where Content == _ConditionalContent<Image, EmptyView> {
    /// Creates an OGP image view.
    ///
    /// - Parameters:
    ///   - url: The web page URL to fetch the OGP image from.
    ///   - pipeline: The pipeline to use for fetching. Defaults to `.shared`.
    init(
        url: URL,
        pipeline: OGPPipeline = .shared
    ) {
        self.init(
            url: url,
            pipeline: pipeline,
            content: { $0 },
            placeholder: { EmptyView() }
        )
    }
}

// MARK: - Phase

/// The current phase of the asynchronous OGP image loading operation.
///
/// Use this type with the phase-based `OGPImageView` initializer to handle
/// each state of the image loading process.
public enum OGPImagePhase: Sendable {
    /// No image is loaded.
    case empty

    /// An image successfully loaded.
    case success(Image)

    /// An image failed to load with an error.
    case failure(Error)

    /// The loaded image, if available.
    ///
    /// Returns the image when in the `success` phase, otherwise `nil`.
    public var image: Image? {
        if case let .success(image) = self {
            return image
        }
        return nil
    }

    /// The error that occurred, if any.
    ///
    /// Returns the error when in the `failure` phase, otherwise `nil`.
    public var error: Error? {
        if case let .failure(error) = self {
            return error
        }
        return nil
    }
}

// MARK: - Error

/// Errors that can occur during OGP image view operations.
public enum OGPImageViewError: Error, Sendable {
    /// The image data could not be decoded into an image.
    case invalidImageData
}
