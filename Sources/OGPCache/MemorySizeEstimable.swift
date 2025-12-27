import Foundation

/// A type that can estimate its memory footprint in bytes.
///
/// Conform to this protocol to provide accurate memory size estimation
/// for cache cost calculations. Types that don't conform will fall back
/// to JSON encoding for size estimation.
public protocol MemorySizeEstimable {
    /// The estimated memory size in bytes.
    var estimatedByteCount: Int { get }
}

extension Data: MemorySizeEstimable {
    public var estimatedByteCount: Int { count }
}
