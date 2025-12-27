import Foundation
import OGPCache

/// A cache that combines memory and disk caching.
/// Memory cache is checked first for faster access, with disk as fallback.
package actor CompositeCache<Value: Sendable & Codable>: OGPCaching {
    private let memory: MemoryCache<Value>
    private let disk: DiskCache<Value>

    package init(memory: MemoryCache<Value>, disk: DiskCache<Value>) {
        self.memory = memory
        self.disk = disk
    }

    package func get(for key: String) async -> Value? {
        if let value = await memory.get(for: key) {
            return value
        }

        if let value = await disk.get(for: key) {
            await memory.set(value, for: key)
            return value
        }

        return nil
    }

    package func set(_ value: Value, for key: String) async {
        await memory.set(value, for: key)
        await disk.set(value, for: key)
    }

    package func remove(for key: String) async {
        await memory.remove(for: key)
        await disk.remove(for: key)
    }

    package func clear() async {
        await memory.clear()
        await disk.clear()
    }
}
