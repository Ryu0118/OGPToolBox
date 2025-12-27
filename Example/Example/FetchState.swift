import Foundation
import OGPImageData
import OGPMetadata

enum FetchState {
    case idle
    case loading
    case success(FetchResult)
    case failure(Error)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}

struct FetchResult {
    let metadata: OGPMetadata
    let imageData: OGPImageData
}

enum FetchError: LocalizedError {
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Invalid URL"
        }
    }
}
