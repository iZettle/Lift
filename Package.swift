// swift-tools-version:5.3

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
            path: "Lift",
            exclude: ["Lift/Info.plist"]),
        .testTarget(
            name: "LiftTests",
            dependencies: ["Lift"]),
    ]
)
