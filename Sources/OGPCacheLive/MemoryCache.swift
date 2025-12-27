import Foundation
import OGPCache

/// An in-memory cache implementation with strict count and size limits.
package actor MemoryCache<Value: Sendable & Codable>: OGPCaching {
    private var storage: [String: CacheEntry<Value>] = [:]
    private var accessOrder: [String] = []
    private let maxCount: Int?
    private let maxBytes: Int?
    private let ttl: TimeInterval?
    private var currentBytes: Int = 0

    package init(maxCount: Int?, maxBytes: Int?, ttl: TimeInterval?) {
        self.maxCount = maxCount
        self.maxBytes = maxBytes
        self.ttl = ttl
    }

    package func get(for key: String) async -> Value? {
        guard let entry = storage[key] else { return nil }
        if entry.isExpired {
            removeEntry(for: key)
            return nil
        }
        updateAccessOrder(for: key)
        return entry.value
    }

    package func set(_ value: Value, for key: String) async {
        let entry = CacheEntry(value: value, ttl: ttl)
        let cost = estimateCost(of: value)

        // Remove existing entry if present
        if storage[key] != nil {
            removeEntry(for: key)
        }

        // Evict entries if needed to satisfy maxBytes
        if let maxBytes {
            while currentBytes + cost > maxBytes, !accessOrder.isEmpty {
                let oldest = accessOrder.removeFirst()
                if let oldEntry = storage.removeValue(forKey: oldest) {
                    currentBytes -= estimateCost(of: oldEntry.value)
                }
            }
        }

        // Evict entries if needed to satisfy maxCount
        if let maxCount {
            while storage.count >= maxCount, !accessOrder.isEmpty {
                let oldest = accessOrder.removeFirst()
                if let oldEntry = storage.removeValue(forKey: oldest) {
                    currentBytes -= estimateCost(of: oldEntry.value)
                }
            }
        }

        storage[key] = entry
        accessOrder.append(key)
        currentBytes += cost
    }

    package func remove(for key: String) async {
        removeEntry(for: key)
    }

    package func clear() async {
        storage.removeAll()
        accessOrder.removeAll()
        currentBytes = 0
    }

    private func removeEntry(for key: String) {
        if let entry = storage.removeValue(forKey: key) {
            currentBytes -= estimateCost(of: entry.value)
            accessOrder.removeAll { $0 == key }
        }
    }

    private func updateAccessOrder(for key: String) {
        accessOrder.removeAll { $0 == key }
        accessOrder.append(key)
    }

    private func estimateCost(of value: Value) -> Int {
        if let estimable = value as? MemorySizeEstimable {
            return estimable.estimatedByteCount
        }
        do {
            let data = try JSONEncoder().encode(value)
            return data.count
        } catch {
            return 1024
        }
    }
}
