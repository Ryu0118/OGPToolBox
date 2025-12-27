import Foundation

/// A cache entry with expiration support.
package struct CacheEntry<Value: Sendable & Codable>: Sendable, Codable {
    let value: Value
    let createdAt: Date
    let ttl: TimeInterval?

    package init(value: Value, ttl: TimeInterval?) {
        self.value = value
        self.createdAt = Date()
        self.ttl = ttl
    }

    package var isExpired: Bool {
        guard let ttl else { return false }
        return Date().timeIntervalSince(createdAt) > ttl
    }
}
