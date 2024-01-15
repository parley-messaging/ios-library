// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Parley",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "Parley",
            targets: ["Parley"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.8.1")),
        .package(url: "https://github.com/Alamofire/AlamofireImage.git", .upToNextMajor(from: "4.3.0")),
        .package(url: "https://github.com/tristanhimmelman/ObjectMapper.git", .upToNextMajor(from: "4.2.0")),
        .package(name: "Reachability", url: "https://github.com/ashleymills/Reachability.swift.git", .upToNextMajor(from: "5.1.0")),
        .package(url: "https://github.com/bmoliveira/MarkdownKit.git", .upToNextMajor(from: "1.7.0"))
    ],
    targets: [
        .target(
            name: "Parley",
            dependencies: [
                "Alamofire",
                "AlamofireImage",
                "ObjectMapper",
                "Reachability",
                "MarkdownKit"
            ],
            path: "Source"
        ),
        .testTarget(
            name: "ParleyTests",
            dependencies: ["Parley"],
            path: "Tests"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
