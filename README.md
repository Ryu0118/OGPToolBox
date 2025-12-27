# OGPToolBox

A Swift toolbox for fetching and displaying Open Graph Protocol (OGP) images from web pages.

## Features

- Fetch and display OGP images with SwiftUI
- Flexible caching (memory, disk, or both)
- Full Swift 6 concurrency support

## Requirements

- iOS 16+ / macOS 13+ / tvOS 16+ / watchOS 9+ / visionOS 1+

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/user/OGPToolBox.git", from: "1.0.0")
]
```

## Usage

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

```swift
OGPImageView(url: url) { image in
    image.resizable()
} placeholder: {
    ProgressView()
}
```

### Phase-Based Handling

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

```swift
import OGPPipeline

@State private var pipeline = OGPPipeline(configuration: .memoryOnly)

var body: some View {
    OGPImageView(url: url, pipeline: pipeline)
}
```

### Fetch Directly

```swift
import OGPPipeline

let imageData = try await OGPPipeline.shared.fetchImage(from: url)
let metadata = try await OGPPipeline.shared.fetchMetadata(from: url)
```

## Caching

```swift
import OGPPipeline

// Memory only
OGPPipeline(configuration: .memoryOnly)

// Memory and disk
OGPPipeline(configuration: .default)

// Custom
OGPPipeline(configuration: OGPPipelineConfiguration(
    metadataCachePolicy: OGPCachePolicy(cacheSystem: .memory, ttl: .hours(1)),
    imageCachePolicy: OGPCachePolicy(cacheSystem: .memoryAndDisk(), ttl: .days(7))
))
```

## License

MIT License
