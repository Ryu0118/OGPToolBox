import Foundation
import Testing

@testable import OGPCacheLive

@Suite(.serialized)
struct DiskCacheTests {
    private static let testCacheName = "OGPDiskCacheTests"

    private func makeCache(ttl: TimeInterval? = nil, maxBytes: Int? = nil) throws -> DiskCache<String> {
        try DiskCache<String>(name: Self.testCacheName + UUID().uuidString, ttl: ttl, maxBytes: maxBytes)
    }

    @Test(arguments: BasicOperationTestCase.allCases)
    func basicOperations(_ testCase: BasicOperationTestCase) async throws {
        let cache = try makeCache()
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
            BasicOperationTestCase(operation: .remove, testDescription: "remove deletes value"),
            BasicOperationTestCase(operation: .clear, testDescription: "clear removes all values"),
            BasicOperationTestCase(operation: .overwrite, testDescription: "set overwrites existing value"),
        ]
    }

    @Test(arguments: TTLTestCase.allCases)
    func ttlBehavior(_ testCase: TTLTestCase) async throws {
        let cache = try makeCache(ttl: testCase.ttl)
        defer { Task { await cache.clear() } }

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
        ]
    }

    @Test
    func storesComplexCodableValues() async throws {
        struct TestData: Codable, Equatable, Sendable {
            let id: Int
            let name: String
        }

        let cache = try DiskCache<TestData>(name: Self.testCacheName + UUID().uuidString, ttl: nil, maxBytes: nil)
        defer { Task { await cache.clear() } }

        let testData = TestData(id: 1, name: "test")

        await cache.set(testData, for: "key")
        let result = await cache.get(for: "key")

        #expect(result == testData)
    }

    @Test
    func handlesSpecialCharactersInKey() async throws {
        let cache = try makeCache()
        defer { Task { await cache.clear() } }

        let specialKey = "https://example.com/path?query=value&other=123"
        await cache.set("value", for: specialKey)
        let result = await cache.get(for: specialKey)

        #expect(result == "value")
    }
}
