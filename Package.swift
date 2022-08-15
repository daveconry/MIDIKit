// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "MIDIKit",
    
    platforms: [
        .macOS(.v10_12), .iOS(.v10)
    ],
    
    products: [
        .library(
            name: "MIDIKit",
            type: .static,
            targets: ["MIDIKit"]
        )
    ],
    
    dependencies: [
        .package(url: "https://github.com/orchetect/SwiftRadix", from: "1.2.0"),
        
        // testing-only:
        .package(url: "https://github.com/orchetect/XCTestUtils", from: "1.0.1")
    ],
    
    targets: [
        .target(
            name: "MIDIKit",
            dependencies: [
                .product(name: "SwiftRadix", package: "SwiftRadix")
            ]
        ),
        
        .testTarget(
            name: "MIDIKitTests",
            dependencies: [
                .target(name: "MIDIKit"),
                .product(name: "SwiftRadix", package: "SwiftRadix"),
                .product(name: "XCTestUtils", package: "XCTestUtils")
            ]
        )
    ],
    
    swiftLanguageVersions: [.v5]
)

func addShouldTestFlag() {
    // swiftSettings may be nil so we can't directly append to it
    
    var swiftSettings = package.targets
        .first(where: { $0.name == "MIDIKitTests" })?
        .swiftSettings ?? []
    
    swiftSettings.append(.define("shouldTestCurrentPlatform"))
    
    package.targets
        .first(where: { $0.name == "MIDIKitTests" })?
        .swiftSettings = swiftSettings
}

// Swift version in Xcode 12.5.1 which introduced watchOS testing
#if os(watchOS) && swift(>=5.4.2)
addShouldTestFlag()
#elseif os(watchOS)
// don't add flag
#else
addShouldTestFlag()
#endif
