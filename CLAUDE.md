# OGPToolBox

A Swift library for fetching and displaying Open Graph Protocol (OGP) images from web page URLs.

## Project Overview

OGPToolBox provides a modular toolkit for working with OGP metadata, specifically focused on extracting and displaying OGP images. The library is designed with separation of concerns in mind, offering different modules for different use cases. Users can import only the modules they need, and optionally inject custom cache implementations.

## Architecture

### Module Structure

| Module | Product | Description |
|--------|---------|-------------|
| OGPCore | ❌ Internal | Shared utilities (internal parser, error types) |
| OGPCache | ✅ Public | Cache protocol definitions |
| OGPCacheLive | ❌ Internal | Built-in cache implementation |
| OGPMetadata | ✅ Public | Metadata fetching and parsing |
| OGPImageData | ✅ Public | Image Data fetching |
| OGPImageView | ✅ Public | SwiftUI components |

### Directory Structure

```
Sources/
├── OGPCore/          # Internal shared utilities
├── OGPCache/         # Cache protocols (public)
├── OGPCacheLive/     # Built-in cache implementation (internal)
├── OGPMetadata/      # Metadata fetching and parsing
├── OGPImageData/     # Image Data fetching
└── OGPImageView/     # SwiftUI components

Tests/
├── OGPCoreTests/
├── OGPCacheTests/
├── OGPMetadataTests/
├── OGPImageDataTests/
└── OGPImageViewTests/
```

### Module Dependencies

```
OGPImageView ───► OGPImageData ───► OGPMetadata ───► OGPCore
     │                 │                 │
     └─────────► OGPCacheLive ◄──────────┘
                       │
                       ▼
                   OGPCache
```

### Supported OGP Meta Tags

| Meta Tag | Priority | Description |
|----------|----------|-------------|
| `og:image` | Primary | Standard OGP image |
| `og:image:url` | Fallback | Explicit image URL |
| `og:image:secure_url` | Preferred | HTTPS version |
| `twitter:image` | Twitter-specific | Twitter/X image |
| `twitter:card` | Twitter-specific | Card type |

Optional metadata: `og:image:width`, `og:image:height`, `og:image:type`, `og:image:alt`

## Tech Stack

- Swift 6.2+
- Platforms: iOS 16+, macOS 13+, tvOS 16+, watchOS 9+, visionOS 1+
- Dependencies: Foundation, SwiftUI (OGPImageView only)

## Coding Standards

### File Organization

- One significant object per file
- File name matches the primary type name

### Design Principles

- **SSoT** - Single Source of Truth
- **DRY** - Extract common logic into `OGPCore`
- **SOLID** - Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion

### Access Control

| Scope | Modifier |
|-------|----------|
| Within file/type | `private` |
| Within module | `internal` |
| Across modules in package | `package` |
| Public API | `public` |

Use `package` instead of `public` when the API is only used within this package.

### Code Complexity

- Extract functions exceeding ~20 lines
- Abstract repeated patterns into protocols/generics
- Prefer composition over inheritance

### Documentation

- All `public`/`package` APIs require doc comments in English
- Use Swift documentation markup (Parameters, Returns, Throws)

### Concurrency

- Use Swift Concurrency (`async`/`await`)
- Mark types as `Sendable`
- Use `@MainActor` for UI code

## Testing

- Use Swift Testing framework (not XCTest)
- Use parameterized tests when testing multiple inputs with the same logic
- For parameterized tests requiring tuples, define a `struct TestCase` with `static let allCases` containing all test cases
- Test/suite descriptions: only add when necessary, write concise English descriptions that explain what is being tested
- Thoroughly identify edge cases; eliminate redundant test cases that verify the same behavior
- Cover edge cases: invalid URLs, missing meta tags, network errors
- Use mock network responses

### Parameterized Test Pattern

Use `CustomTestStringConvertible` protocol to provide custom descriptions for test cases:

```swift
@Suite
struct MyFeatureTests {
    @Test(arguments: TestCase.allCases)
    func transform(_ testCase: TestCase) {
        #expect(transform(testCase.input) == testCase.expected)
    }

    struct TestCase: CustomTestStringConvertible {
        let input: String
        let expected: String
        let testDescription: String

        static let allCases: [TestCase] = [
            TestCase(input: "a", expected: "A", testDescription: "lowercase to uppercase"),
            TestCase(input: "", expected: "", testDescription: "empty string"),
        ]
    }
}
```
