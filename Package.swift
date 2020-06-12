// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "XCTestJSONObserver",
    platforms: [.macOS(.v10_13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "XCTestJSONObserver",
            targets: ["XCTestJSONObserver"]
        ),
    ],
    dependencies: [
        .package(
            name: "SnapshotTesting",
            url: "https://github.com/pointfreeco/swift-snapshot-testing.git",
            from: "1.8.0"
        ),
        .package(url: "https://github.com/typelift/SwiftCheck.git", from: "0.8.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "XCTestJSONObserver",
            dependencies: []
        ),
        .testTarget(
            name: "JSONObserverTests",
            dependencies: ["SnapshotTesting", "SwiftCheck", "XCTestJSONObserver"]
        ),
    ]
)
