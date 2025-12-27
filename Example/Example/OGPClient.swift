import OGPCache
import OGPImageData
import OGPMetadata
import OGPPipeline
import SwiftUI

@MainActor
@Observable
final class OGPClient {
    private(set) var pipeline: OGPPipeline
    private var currentSettings: CacheSettings

    init(settings: CacheSettings = CacheSettings()) {
        currentSettings = settings
        pipeline = OGPPipeline(configuration: settings.pipelineConfiguration)
    }

    func updateSettings(_ settings: CacheSettings) {
        guard settings != currentSettings else { return }
        currentSettings = settings
        pipeline = OGPPipeline(configuration: settings.pipelineConfiguration)
    }
}
