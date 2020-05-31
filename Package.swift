// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Cassowary",
    products: [
        .library(
            name: "Cassowary",
            targets: ["Cassowary"]
        )
    ],
    targets: [
        .target(
            name: "Cassowary",
            path: "Cassowary/Sources"
        ),
        .testTarget(
            name: "CassowaryTests",
            dependencies: ["Cassowary"],
            path: "CassowaryTests"
        )
    ]
)
