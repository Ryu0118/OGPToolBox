import Foundation

/// A mock URLProtocol for testing network requests.
/// Handlers are keyed by URL host to isolate tests.
final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    /// Lock for thread-safe access to handlers.
    private static let lock = NSLock()

    /// Handlers keyed by URL host.
    nonisolated(unsafe) private static var handlers: [String: (URLRequest) throws -> (HTTPURLResponse, Data)] = [:]

    /// Sets a handler for a specific host.
    static func setHandler(
        for host: String,
        handler: @escaping (URLRequest) throws -> (HTTPURLResponse, Data)
    ) {
        lock.lock()
        defer { lock.unlock() }
        handlers[host] = handler
    }

    /// Gets a handler for a specific host.
    private static func getHandler(for host: String) -> ((URLRequest) throws -> (HTTPURLResponse, Data))? {
        lock.lock()
        defer { lock.unlock() }
        return handlers[host]
    }

    /// Clears all handlers.
    static func clearAllHandlers() {
        lock.lock()
        defer { lock.unlock() }
        handlers.removeAll()
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let host = request.url?.host ?? "default"
        guard let handler = MockURLProtocol.getHandler(for: host) else {
            let error = NSError(domain: "MockURLProtocol", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "No handler set for host: \(host)"
            ])
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

/// Creates a URLSession configured with MockURLProtocol.
func makeMockSession() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: configuration)
}

/// Creates a unique test URL to avoid handler conflicts between tests.
func makeTestURL() -> URL {
    URL(string: "https://\(UUID().uuidString).example.com")!
}
