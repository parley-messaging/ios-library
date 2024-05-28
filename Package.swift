// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "Parley",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "Parley",
            targets: ["Parley"]
        ),
        .library(
            name: "ParleyNetwork",
            targets: ["ParleyNetwork"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.8.1")),
        .package(url: "https://github.com/Alamofire/AlamofireImage.git", .upToNextMajor(from: "4.3.0")),
        .package(url: "https://github.com/ashleymills/Reachability.swift.git", .upToNextMajor(from: "5.1.0")),
        .package(url: "https://github.com/bmoliveira/MarkdownKit.git", .upToNextMajor(from: "1.7.0")),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.16.0"),
    ],
    targets: [
        .target(
            name: "Parley",
            dependencies: [
                .product(name: "Reachability", package: "Reachability.swift"),
                "MarkdownKit",
            ]
        ),
        .target(
            name: "ParleyNetwork",
            dependencies: [
                "Parley",
                "Alamofire",
                "AlamofireImage",
            ]
        ),
        .testTarget(
            name: "ParleyTests",
            dependencies: [
                "Parley",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            resources: [.process("Media.xcassets")]
        ),
        .testTarget(
            name: "ParleyNetworkTests",
            dependencies: ["ParleyNetwork"]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
