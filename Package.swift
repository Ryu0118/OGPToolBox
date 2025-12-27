// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "OGPToolBox",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "OGPCache",
            targets: ["OGPCache"]
        ),
        .library(
            name: "OGPMetadata",
            targets: ["OGPMetadata"]
        ),
        .library(
            name: "OGPImageData",
            targets: ["OGPImageData"]
        ),
        .library(
            name: "OGPPipeline",
            targets: ["OGPPipeline"]
        ),
        .library(
            name: "OGPImageView",
            targets: ["OGPImageView"]
        ),
    ],
    targets: [
        // Internal modules (not exposed as products)
        .target(
            name: "OGPCore"
        ),
        .target(
            name: "OGPCache"
        ),
        .target(
            name: "OGPCacheLive",
            dependencies: ["OGPCache"]
        ),

        // Public modules
        .target(
            name: "OGPMetadata",
            dependencies: ["OGPCore", "OGPCache", "OGPCacheLive"]
        ),
        .target(
            name: "OGPImageData",
            dependencies: ["OGPMetadata", "OGPCache", "OGPCacheLive"]
        ),
        .target(
            name: "OGPPipeline",
            dependencies: ["OGPMetadata", "OGPImageData", "OGPCache", "OGPCacheLive"]
        ),
        .target(
            name: "OGPImageView",
            dependencies: ["OGPPipeline", "OGPImageData", "OGPMetadata", "OGPCache"]
        ),

        // Test targets
        .testTarget(
            name: "OGPCoreTests",
            dependencies: ["OGPCore"]
        ),
        .testTarget(
            name: "OGPCacheTests",
            dependencies: ["OGPCache", "OGPCacheLive", "OGPMetadata"]
        ),
        .testTarget(
            name: "OGPMetadataTests",
            dependencies: ["OGPMetadata"]
        ),
        .testTarget(
            name: "OGPImageDataTests",
            dependencies: ["OGPImageData"]
        ),
    ]
)
