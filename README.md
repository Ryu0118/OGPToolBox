# OGPToolBox

A Swift toolbox for fetching and displaying Open Graph Protocol (OGP) images from web pages.

<div align="center">
    <img width="200" alt="screenshot" src="https://github.com/user-attachments/assets/aa123f2a-97c6-4eb8-9a46-8425eede5143" />
</div>

## Features

- Fetch and display OGP images with SwiftUI
- Flexible caching (memory, disk, or both)
- Full Swift 6 concurrency support

## Requirements

- iOS 16+ / macOS 13+ / tvOS 16+ / watchOS 9+ / visionOS 1+

## Installation

Add the package to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/Ryu0118/OGPToolBox.git", from: "0.1.0")
]
```

## Usage

The simplest way to display an OGP image is with `OGPImageView`. Just pass a URL and the view handles fetching, caching, and display automatically.

### Display an OGP Image

```swift
import OGPImageView

struct ContentView: View {
    var body: some View {
        OGPImageView(url: URL(string: "https://github.com")!)
            .frame(width: 300, height: 200)
    }
}
```

### Custom Content and Placeholder

You can customize how the image is displayed and provide a placeholder while loading:

```swift
OGPImageView(url: url) { image in
    image.resizable()
} placeholder: {
    ProgressView()
}
```

### Phase-Based Handling

For more control, use the phase-based initializer to handle loading, success, and failure states individually:

```swift
OGPImageView(url: url) { phase in
    switch phase {
    case .empty:
        ProgressView()
    case .success(let image):
        image.resizable()
    case .failure:
        Image(systemName: "exclamationmark.triangle")
    }
}
```

### Custom Pipeline

By default, `OGPImageView` uses a shared pipeline. You can create your own pipeline for custom caching behavior:

```swift
import OGPPipeline

@State private var pipeline = OGPPipeline(configuration: .memoryOnly)

var body: some View {
    OGPImageView(url: url, pipeline: pipeline)
}
```

### Fetch Directly

If you need the raw data without a SwiftUI view, use `OGPPipeline` directly:

```swift
import OGPPipeline

let imageData = try await OGPPipeline.shared.fetchImage(from: url)
let metadata = try await OGPPipeline.shared.fetchMetadata(from: url)
```

## Caching

OGPToolBox provides flexible caching options. Choose a preset or configure your own policy:

```swift
import OGPPipeline

// Memory only - cached data is cleared when the app terminates
OGPPipeline(configuration: .memoryOnly)

// Memory and disk (default) - cached data persists across app launches
OGPPipeline(configuration: .default)

// Custom - fine-tune TTL and storage for metadata and images separately
OGPPipeline(configuration: OGPPipelineConfiguration(
    metadataCachePolicy: OGPCachePolicy(cacheSystem: .memory, ttl: .hours(1)),
    imageCachePolicy: OGPCachePolicy(cacheSystem: .memoryAndDisk(), ttl: .days(7))
))
```

## Modules

The library is split into focused modules. Most users only need `OGPImageView`.

| Module | Description |
|--------|-------------|
| `OGPImageView` | SwiftUI view for displaying OGP images |
| `OGPPipeline` | Fetch metadata/images with caching |
| `OGPMetadata` | Parse OGP metadata from HTML |
| `OGPCache` | Cache protocol for custom implementations |

## License

MIT License
