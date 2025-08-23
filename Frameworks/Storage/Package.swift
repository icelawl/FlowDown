// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Storage",
    platforms: [
        .iOS(.v15),
        .macCatalyst(.v15),
        .macOS(.v11),
    ],
    products: [
        .library(name: "Storage", targets: ["Storage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Lakr233/MarkdownView", from: "3.4.2"),
        .package(url: "https://github.com/Tencent/wcdb", from: "2.1.11"),
    ],
    targets: [
        .target(name: "Storage", dependencies: [
            .product(name: "MarkdownParser", package: "MarkdownView"),
            .product(name: "WCDBSwift", package: "wcdb"),
        ]),
    ]
)
