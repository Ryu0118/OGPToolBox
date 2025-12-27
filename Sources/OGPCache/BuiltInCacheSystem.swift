import Foundation

/// Built-in cache system options.
public enum BuiltInCacheSystem: Sendable, Equatable {
    /// Cache in memory only. Data is lost when the app terminates.
    case memory

    /// Cache on disk only. Data persists across app launches.
    /// - Parameter directory: Custom directory URL for disk cache.
    ///   If `nil`, uses the default caches directory.
    case disk(directory: URL? = nil)

    /// Cache in both memory and disk. Memory is checked first for faster access.
    /// - Parameter directory: Custom directory URL for disk cache.
    ///   If `nil`, uses the default caches directory.
    case memoryAndDisk(directory: URL? = nil)

    /// The custom directory URL for disk-based caching, if specified.
    package var diskDirectory: URL? {
        switch self {
        case .memory:
            nil
        case let .disk(directory):
            directory
        case let .memoryAndDisk(directory):
            directory
        }
    }
}
