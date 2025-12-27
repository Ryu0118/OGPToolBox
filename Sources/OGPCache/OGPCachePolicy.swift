import Foundation

/// Defines the caching strategy for OGP data.
public struct OGPCachePolicy<Value: Sendable>: Sendable {
    /// Time-to-live configuration for cached entries.
    public enum TTL: Sendable {
        case unlimited
        case seconds(TimeInterval)
        case minutes(TimeInterval)
        case hours(TimeInterval)
        case days(TimeInterval)

        package var timeInterval: TimeInterval? {
            switch self {
            case .unlimited: nil
            case .seconds(let value): value
            case .minutes(let value): value * 60
            case .hours(let value): value * 3600
            case .days(let value): value * 86400
            }
        }
    }

    /// Maximum entry count configuration.
    public enum MaxCount: Sendable {
        case unlimited
        case count(Int)

        package var value: Int? {
            switch self {
            case .unlimited: nil
            case .count(let count): count
            }
        }
    }

    /// Maximum cache size configuration.
    public enum MaxSize: Sendable {
        case unlimited
        case bytes(Int)
        case kilobytes(Int)
        case megabytes(Int)

        package var bytes: Int? {
            switch self {
            case .unlimited: nil
            case .bytes(let value): value
            case .kilobytes(let value): value * 1024
            case .megabytes(let value): value * 1024 * 1024
            }
        }
    }

    /// The cache system to use, or `nil` for no caching.
    public let cacheSystem: (any OGPCaching<Value>)?

    /// The built-in cache system type, if using built-in cache.
    package let builtInCacheSystem: BuiltInCacheSystem?

    public let ttl: TTL
    public let maxCount: MaxCount
    public let maxSize: MaxSize

    /// Creates a cache policy with a custom cache system.
    /// - Parameters:
    ///   - cacheSystem: A custom cache implementation.
    ///   - ttl: Time-to-live for cached entries.
    ///   - maxCount: Maximum number of entries.
    ///   - maxSize: Maximum cache size.
    public init(
        cacheSystem: any OGPCaching<Value>,
        ttl: TTL = .hours(1),
        maxCount: MaxCount = .count(100),
        maxSize: MaxSize = .megabytes(50)
    ) {
        self.cacheSystem = cacheSystem
        self.builtInCacheSystem = nil
        self.ttl = ttl
        self.maxCount = maxCount
        self.maxSize = maxSize
    }

    /// Creates a cache policy with a built-in cache system.
    /// - Parameters:
    ///   - cacheSystem: The built-in cache system to use.
    ///   - ttl: Time-to-live for cached entries.
    ///   - maxCount: Maximum number of entries.
    ///   - maxSize: Maximum cache size.
    @_disfavoredOverload
    public init(
        cacheSystem: BuiltInCacheSystem,
        ttl: TTL = .hours(1),
        maxCount: MaxCount = .count(100),
        maxSize: MaxSize = .megabytes(50)
    ) {
        self.cacheSystem = nil
        self.builtInCacheSystem = cacheSystem
        self.ttl = ttl
        self.maxCount = maxCount
        self.maxSize = maxSize
    }

    private init() {
        self.cacheSystem = nil
        self.builtInCacheSystem = nil
        self.ttl = .unlimited
        self.maxCount = .unlimited
        self.maxSize = .unlimited
    }

    /// No caching.
    public static var none: OGPCachePolicy<Value> {
        OGPCachePolicy()
    }
}
