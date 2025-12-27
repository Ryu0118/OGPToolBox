import Foundation
import OGPCache

/// Factory for creating cache instances based on policy.
package enum CacheFactory {
    /// Creates an appropriate cache for the given policy.
    /// - Parameters:
    ///   - policy: The caching policy to use.
    ///   - name: The cache name (used for disk cache directory).
    /// - Returns: A cache instance, or `nil` if no caching is configured.
    package static func makeCache<Value: Sendable & Codable>(
        for policy: OGPCachePolicy<Value>,
        name: String = "OGPCache"
    ) -> (any OGPCaching<Value>)? {
        // If custom cache system is provided, use it
        if let cacheSystem = policy.cacheSystem {
            return cacheSystem
        }

        // If built-in cache system is specified, create it
        guard let builtIn = policy.builtInCacheSystem else {
            return nil
        }

        let ttl = policy.ttl.timeInterval
        let maxCount = policy.maxCount.value
        let maxBytes = policy.maxSize.bytes

        switch builtIn {
        case .memory:
            return MemoryCache<Value>(maxCount: maxCount, maxBytes: maxBytes, ttl: ttl)

        case let .disk(directory):
            return try? DiskCache<Value>(name: name, baseDirectory: directory, ttl: ttl, maxBytes: maxBytes)

        case let .memoryAndDisk(directory):
            guard let disk = try? DiskCache<Value>(name: name, baseDirectory: directory, ttl: ttl, maxBytes: maxBytes) else {
                return nil
            }
            let memory = MemoryCache<Value>(maxCount: maxCount, maxBytes: maxBytes, ttl: ttl)
            return CompositeCache(memory: memory, disk: disk)
        }
    }
}
