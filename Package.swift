// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "Lift",
    products: [
        .library(
            name: "Lift",
            targets: ["Lift"]),
    ],
    targets: [
        .target(
            name: "Lift",
            dependencies: [],
            path: "Lift"),
        .testTarget(
            name: "LiftTests",
            dependencies: ["Lift"]),
    ]
)
