import Foundation

/// A protocol for caching OGP-related data.
///
/// Implement this protocol to provide custom cache storage
/// (e.g., using Nuke, Kingfisher, or other caching libraries).
public protocol OGPCaching<Value>: Sendable {
    associatedtype Value: Sendable

    /// Retrieves a cached value for the given key.
    /// - Parameter key: The cache key (typically a URL string).
    /// - Returns: The cached value, or `nil` if not found.
    func get(for key: String) async -> Value?

    /// Stores a value in the cache.
    /// - Parameters:
    ///   - value: The value to cache.
    ///   - key: The cache key (typically a URL string).
    func set(_ value: Value, for key: String) async

    /// Removes a cached value for the given key.
    /// - Parameter key: The cache key to remove.
    func remove(for key: String) async

    /// Clears all cached values.
    func clear() async
}
