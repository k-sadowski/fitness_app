// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FitnessCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
    ],
    products: [
        .library(name: "FitnessCore", targets: ["FitnessCore"]),
    ],
    targets: [
        .target(
            name: "FitnessCore",
            path: "Sources/FitnessCore"
        ),
        .testTarget(
            name: "FitnessCoreTests",
            dependencies: ["FitnessCore"],
            path: "Tests/FitnessCoreTests"
        ),
    ]
)
