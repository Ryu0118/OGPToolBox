import Foundation
import OGPCache

/// A disk-based cache implementation using the file system.
package actor DiskCache<Value: Sendable & Codable>: OGPCaching {
    private let directory: URL
    private let fileManager = FileManager.default
    private let ttl: TimeInterval?
    private let maxBytes: Int?

    /// Creates a new disk cache.
    ///
    /// - Parameters:
    ///   - name: The cache name, used as subdirectory name.
    ///   - baseDirectory: Custom base directory URL. If `nil`, uses the default caches directory.
    ///   - ttl: Time-to-live for cached entries.
    ///   - maxBytes: Maximum cache size in bytes.
    package init(name: String, baseDirectory: URL? = nil, ttl: TimeInterval?, maxBytes: Int?) throws {
        let fm = FileManager.default
        let base = baseDirectory ?? fm.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.directory = base.appendingPathComponent(name, isDirectory: true)
        self.ttl = ttl
        self.maxBytes = maxBytes

        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }

    package func get(for key: String) async -> Value? {
        let fileURL = fileURL(for: key)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        guard let entry = try? JSONDecoder().decode(CacheEntry<Value>.self, from: data) else { return nil }

        if entry.isExpired {
            try? fileManager.removeItem(at: fileURL)
            return nil
        }

        return entry.value
    }

    package func set(_ value: Value, for key: String) async {
        let entry = CacheEntry(value: value, ttl: ttl)
        let fileURL = fileURL(for: key)
        guard let data = try? JSONEncoder().encode(entry) else { return }

        if let maxBytes, await currentDiskSize() + data.count > maxBytes {
            await evictOldestEntries(toFree: data.count)
        }

        try? data.write(to: fileURL)
    }

    package func remove(for key: String) async {
        let fileURL = fileURL(for: key)
        try? fileManager.removeItem(at: fileURL)
    }

    package func clear() async {
        guard let files = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else {
            return
        }
        for file in files {
            try? fileManager.removeItem(at: file)
        }
    }

    private func fileURL(for key: String) -> URL {
        let hashedKey = key.data(using: .utf8)!.base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
        return directory.appendingPathComponent(hashedKey)
    }

    private func currentDiskSize() async -> Int {
        guard let files = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        return files.reduce(0) { total, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return total + size
        }
    }

    private func evictOldestEntries(toFree bytesNeeded: Int) async {
        guard let files = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]
        ) else { return }

        let sortedFiles = files.sorted { url1, url2 in
            let date1 = (try? url1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let date2 = (try? url2.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return date1 < date2
        }

        var freedBytes = 0
        for file in sortedFiles {
            guard freedBytes < bytesNeeded else { break }
            let size = (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            try? fileManager.removeItem(at: file)
            freedBytes += size
        }
    }
}
