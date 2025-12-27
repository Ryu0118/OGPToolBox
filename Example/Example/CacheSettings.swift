import OGPCache
import OGPImageData
import OGPMetadata
import OGPPipeline

struct CacheSettings: Equatable, Sendable {
    var cacheType: CacheType
    var ttlValue: Double
    var ttlUnit: TTLUnit
    var maxCount: Int
    var maxSizeMB: Int

    nonisolated init(
        cacheType: CacheType = .memory,
        ttlValue: Double = 1,
        ttlUnit: TTLUnit = .hours,
        maxCount: Int = 100,
        maxSizeMB: Int = 50
    ) {
        self.cacheType = cacheType
        self.ttlValue = ttlValue
        self.ttlUnit = ttlUnit
        self.maxCount = maxCount
        self.maxSizeMB = maxSizeMB
    }

    var pipelineConfiguration: OGPPipelineConfiguration {
        OGPPipelineConfiguration(
            metadataCachePolicy: metadataCachePolicy,
            imageCachePolicy: imageCachePolicy
        )
    }

    var metadataCachePolicy: OGPCachePolicy<OGPMetadata> {
        makePolicy()
    }

    var imageCachePolicy: OGPCachePolicy<OGPImageData> {
        makePolicy()
    }

    private func makePolicy<T: Sendable & Codable & MemorySizeEstimable>() -> OGPCachePolicy<T> {
        guard cacheType != .none else {
            return .none
        }

        let ttl: OGPCachePolicy<T>.TTL = switch ttlUnit {
        case .seconds: .seconds(ttlValue)
        case .minutes: .minutes(ttlValue)
        case .hours: .hours(ttlValue)
        case .days: .days(ttlValue)
        }

        return OGPCachePolicy(
            cacheSystem: cacheType.builtInSystem,
            ttl: ttl,
            maxCount: .count(maxCount),
            maxSize: .megabytes(maxSizeMB)
        )
    }
}

enum CacheType: String, CaseIterable, Sendable {
    case none = "None"
    case memory = "Memory"
    case disk = "Disk"
    case memoryAndDisk = "Memory + Disk"

    var builtInSystem: BuiltInCacheSystem {
        switch self {
        case .none: .memory
        case .memory: .memory
        case .disk: .disk()
        case .memoryAndDisk: .memoryAndDisk()
        }
    }
}

enum TTLUnit: String, CaseIterable, Sendable {
    case seconds = "Seconds"
    case minutes = "Minutes"
    case hours = "Hours"
    case days = "Days"
}
