import Foundation
import OGPCache

/// An in-memory cache implementation using NSCache.
package actor MemoryCache<Value: Sendable & Codable>: OGPCaching {
    private let cache = NSCache<NSString, Box<CacheEntry<Value>>>()
    private let ttl: TimeInterval?

    package init(maxCount: Int?, maxBytes: Int?, ttl: TimeInterval?) {
        if let maxCount {
            cache.countLimit = maxCount
        }
        if let maxBytes {
            cache.totalCostLimit = maxBytes
        }
        self.ttl = ttl
    }

    package func get(for key: String) async -> Value? {
        guard let box = cache.object(forKey: key as NSString) else { return nil }
        let entry = box.value
        if entry.isExpired {
            cache.removeObject(forKey: key as NSString)
            return nil
        }
        return entry.value
    }

    package func set(_ value: Value, for key: String) async {
        let entry = CacheEntry(value: value, ttl: ttl)
        let cost = estimateCost(of: entry)
        cache.setObject(Box(entry), forKey: key as NSString, cost: cost)
    }

    package func remove(for key: String) async {
        cache.removeObject(forKey: key as NSString)
    }

    package func clear() async {
        cache.removeAllObjects()
    }

    private func estimateCost(of entry: CacheEntry<Value>) -> Int {
        if let estimable = entry.value as? MemorySizeEstimable {
            return estimable.estimatedByteCount
        }
        do {
            let data = try JSONEncoder().encode(entry)
            return data.count
        } catch {
            return 1024 // Fallback estimate
        }
    }
}

/// A wrapper class for storing value types in NSCache.
private final class Box<T: Sendable>: Sendable {
    let value: T

    init(_ value: T) {
        self.value = value
    }
}
