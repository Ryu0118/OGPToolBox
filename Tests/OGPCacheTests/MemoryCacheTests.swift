import Foundation
import Testing

@testable import OGPCacheLive

@Suite
struct MemoryCacheTests {
    @Test(arguments: BasicOperationTestCase.allCases)
    func basicOperations(_ testCase: BasicOperationTestCase) async {
        let cache = MemoryCache<String>(maxCount: nil, maxBytes: nil, ttl: nil)

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
            BasicOperationTestCase(operation: .remove, testDescription: "remove deletes value"),
            BasicOperationTestCase(operation: .clear, testDescription: "clear removes all values"),
            BasicOperationTestCase(operation: .overwrite, testDescription: "set overwrites existing value"),
        ]
    }

    @Test(arguments: TTLTestCase.allCases)
    func ttlBehavior(_ testCase: TTLTestCase) async throws {
        let cache = MemoryCache<String>(maxCount: nil, maxBytes: nil, ttl: testCase.ttl)

        await cache.set("value", for: "key")

        if let sleepDuration = testCase.sleepMilliseconds {
            try await Task.sleep(for: .milliseconds(sleepDuration))
        }

        let result = await cache.get(for: "key")
        #expect(result == testCase.expectedValue)
    }

    struct TTLTestCase: CustomTestStringConvertible, Sendable {
        let ttl: TimeInterval?
        let sleepMilliseconds: Int?
        let expectedValue: String?
        let testDescription: String

        static let allCases: [TTLTestCase] = [
            TTLTestCase(ttl: 0.1, sleepMilliseconds: 150, expectedValue: nil, testDescription: "expired entry returns nil"),
            TTLTestCase(ttl: 10, sleepMilliseconds: nil, expectedValue: "value", testDescription: "non-expired entry returns value"),
            TTLTestCase(ttl: nil, sleepMilliseconds: nil, expectedValue: "value", testDescription: "no TTL never expires"),
        ]
    }

    @Test
    func storesComplexCodableValues() async {
        struct TestData: Codable, Equatable, Sendable {
            let id: Int
            let name: String
        }

        let cache = MemoryCache<TestData>(maxCount: nil, maxBytes: nil, ttl: nil)
        let testData = TestData(id: 1, name: "test")

        await cache.set(testData, for: "key")
        let result = await cache.get(for: "key")

        #expect(result == testData)
    }

    // MARK: - maxCount Tests

    @Test(arguments: MaxCountTestCase.allCases)
    func maxCountEnforcement(_ testCase: MaxCountTestCase) async {
        let cache = MemoryCache<String>(maxCount: testCase.maxCount, maxBytes: nil, ttl: nil)

        for (key, value) in testCase.insertions {
            await cache.set(value, for: key)
        }

        for (key, expectedValue) in testCase.expectations {
            let result = await cache.get(for: key)
            #expect(result == expectedValue, "key '\(key)' should be \(expectedValue == nil ? "nil" : "'\(expectedValue!)'")")
        }
    }

    struct MaxCountTestCase: CustomTestStringConvertible, Sendable {
        let maxCount: Int
        let insertions: [(key: String, value: String)]
        let expectations: [(key: String, expectedValue: String?)]
        let testDescription: String

        static let allCases: [MaxCountTestCase] = [
            MaxCountTestCase(
                maxCount: 1,
                insertions: [("key1", "value1"), ("key2", "value2")],
                expectations: [("key1", nil), ("key2", "value2")],
                testDescription: "maxCount=1 evicts oldest entry"
            ),
            MaxCountTestCase(
                maxCount: 2,
                insertions: [("key1", "value1"), ("key2", "value2"), ("key3", "value3")],
                expectations: [("key1", nil), ("key2", "value2"), ("key3", "value3")],
                testDescription: "maxCount=2 evicts oldest when third added"
            ),
            MaxCountTestCase(
                maxCount: 3,
                insertions: [("key1", "value1"), ("key2", "value2")],
                expectations: [("key1", "value1"), ("key2", "value2")],
                testDescription: "no eviction when under limit"
            ),
        ]
    }

    @Test
    func maxCountLRUEviction() async {
        let cache = MemoryCache<String>(maxCount: 2, maxBytes: nil, ttl: nil)

        await cache.set("value1", for: "key1")
        await cache.set("value2", for: "key2")

        // Access key1 to make it more recent than key2
        _ = await cache.get(for: "key1")

        // Add key3, should evict key2 (least recently used)
        await cache.set("value3", for: "key3")

        #expect(await cache.get(for: "key1") == "value1", "key1 should remain (recently accessed)")
        #expect(await cache.get(for: "key2") == nil, "key2 should be evicted (LRU)")
        #expect(await cache.get(for: "key3") == "value3", "key3 should exist")
    }

    // MARK: - maxBytes Tests

    @Test(arguments: MaxBytesTestCase.allCases)
    func maxBytesEnforcement(_ testCase: MaxBytesTestCase) async {
        let cache = MemoryCache<String>(maxCount: nil, maxBytes: testCase.maxBytes, ttl: nil)

        for (key, value) in testCase.insertions {
            await cache.set(value, for: key)
        }

        for (key, expectedValue) in testCase.expectations {
            let result = await cache.get(for: key)
            #expect(result == expectedValue, "key '\(key)' should be \(expectedValue == nil ? "nil" : "present")")
        }
    }

    struct MaxBytesTestCase: CustomTestStringConvertible, Sendable {
        let maxBytes: Int
        let insertions: [(key: String, value: String)]
        let expectations: [(key: String, expectedValue: String?)]
        let testDescription: String

        static let allCases: [MaxBytesTestCase] = [
            MaxBytesTestCase(
                maxBytes: 20,
                insertions: [("key1", "short"), ("key2", "another short value")],
                expectations: [("key1", nil), ("key2", "another short value")],
                testDescription: "evicts oldest when bytes exceeded"
            ),
            MaxBytesTestCase(
                maxBytes: 1000,
                insertions: [("key1", "small"), ("key2", "also small")],
                expectations: [("key1", "small"), ("key2", "also small")],
                testDescription: "no eviction when under byte limit"
            ),
        ]
    }

    @Test
    func maxBytesLRUEviction() async {
        // "aaa" JSON encoded is 5 bytes: "aaa"
        // Two entries = ~10 bytes, maxBytes=12 allows both
        // Adding larger value forces eviction of LRU entry
        let cache = MemoryCache<String>(maxCount: nil, maxBytes: 12, ttl: nil)

        await cache.set("aaa", for: "key1")  // 5 bytes
        await cache.set("bbb", for: "key2")  // 5 bytes, total ~10 bytes

        // Access key1 to make it more recent
        _ = await cache.get(for: "key1")

        // Add value that forces eviction (needs to evict key2 to fit)
        await cache.set("ccc", for: "key3")

        #expect(await cache.get(for: "key1") == "aaa", "key1 should remain (recently accessed)")
        #expect(await cache.get(for: "key2") == nil, "key2 should be evicted (LRU)")
        #expect(await cache.get(for: "key3") == "ccc", "key3 should exist")
    }

    @Test
    func overwriteUpdatesAccessOrder() async {
        let cache = MemoryCache<String>(maxCount: 2, maxBytes: nil, ttl: nil)

        await cache.set("value1", for: "key1")
        await cache.set("value2", for: "key2")

        // Overwrite key1 to make it most recent
        await cache.set("value1-updated", for: "key1")

        // Add key3, should evict key2 (now oldest)
        await cache.set("value3", for: "key3")

        #expect(await cache.get(for: "key1") == "value1-updated", "key1 should remain")
        #expect(await cache.get(for: "key2") == nil, "key2 should be evicted")
        #expect(await cache.get(for: "key3") == "value3", "key3 should exist")
    }
}
