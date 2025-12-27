import Foundation
import Testing

@testable import OGPCacheLive

@Suite(.serialized)
struct CompositeCacheTests {
    private static let testCacheName = "OGPCompositeCacheTests"

    private func makeCache() throws -> (CompositeCache<String>, MemoryCache<String>, DiskCache<String>) {
        let memory = MemoryCache<String>(maxCount: nil, maxBytes: nil, ttl: nil)
        let disk = try DiskCache<String>(name: Self.testCacheName + UUID().uuidString, ttl: nil, maxBytes: nil)
        let composite = CompositeCache(memory: memory, disk: disk)
        return (composite, memory, disk)
    }

    @Test(arguments: BasicOperationTestCase.allCases)
    func basicOperations(_ testCase: BasicOperationTestCase) async throws {
        let (cache, _, _) = try makeCache()
        defer { Task { await cache.clear() } }

        switch testCase.operation {
        case .setAndGet:
            await cache.set("value", for: "key")
            let result = await cache.get(for: "key")
            #expect(result == "value")

        case .getNonExistent:
            let result = await cache.get(for: "nonexistent")
            #expect(result == nil)

        case .remove:
            await cache.set("value", for: "key")
            await cache.remove(for: "key")
            let result = await cache.get(for: "key")
            #expect(result == nil)

        case .clear:
            await cache.set("value1", for: "key1")
            await cache.set("value2", for: "key2")
            await cache.clear()
            #expect(await cache.get(for: "key1") == nil)
            #expect(await cache.get(for: "key2") == nil)

        case .overwrite:
            await cache.set("original", for: "key")
            await cache.set("updated", for: "key")
            let result = await cache.get(for: "key")
            #expect(result == "updated")
        }
    }

    enum CacheOperation: Sendable {
        case setAndGet
        case getNonExistent
        case remove
        case clear
        case overwrite
    }

    struct BasicOperationTestCase: CustomTestStringConvertible, Sendable {
        let operation: CacheOperation
        let testDescription: String

        static let allCases: [BasicOperationTestCase] = [
            BasicOperationTestCase(operation: .setAndGet, testDescription: "set and get value"),
            BasicOperationTestCase(operation: .getNonExistent, testDescription: "get non-existent key returns nil"),
            BasicOperationTestCase(operation: .remove, testDescription: "remove deletes from both caches"),
            BasicOperationTestCase(operation: .clear, testDescription: "clear removes all values"),
            BasicOperationTestCase(operation: .overwrite, testDescription: "set overwrites existing value"),
        ]
    }

    @Test(arguments: CacheLayerTestCase.allCases)
    func cacheLayerBehavior(_ testCase: CacheLayerTestCase) async throws {
        let (cache, memory, disk) = try makeCache()
        defer { Task { await cache.clear() } }

        switch testCase.scenario {
        case .memoryFirst:
            // Set value in composite (both memory and disk)
            await cache.set("value", for: "key")
            // Clear only disk to verify memory is checked first
            await disk.clear()
            let result = await cache.get(for: "key")
            #expect(result == "value")

        case .diskFallback:
            // Set directly to disk only
            await disk.set("diskValue", for: "key")
            // Get should find it from disk
            let result = await cache.get(for: "key")
            #expect(result == "diskValue")

        case .promoteToMemory:
            // Set directly to disk only
            await disk.set("diskValue", for: "key")
            // Get should promote to memory
            _ = await cache.get(for: "key")
            // Verify it's now in memory
            let memoryResult = await memory.get(for: "key")
            #expect(memoryResult == "diskValue")
        }
    }

    enum CacheLayerScenario: Sendable {
        case memoryFirst
        case diskFallback
        case promoteToMemory
    }

    struct CacheLayerTestCase: CustomTestStringConvertible, Sendable {
        let scenario: CacheLayerScenario
        let testDescription: String

        static let allCases: [CacheLayerTestCase] = [
            CacheLayerTestCase(scenario: .memoryFirst, testDescription: "retrieves from memory first"),
            CacheLayerTestCase(scenario: .diskFallback, testDescription: "falls back to disk when memory misses"),
            CacheLayerTestCase(scenario: .promoteToMemory, testDescription: "promotes from disk to memory"),
        ]
    }
}
