// swift-tools-version: 6.1
import PackageDescription
import Foundation

let package = Package(
    name: "CoreModel-SQLite",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    products: [
        .library(
            name: "CoreModelSQLite",
            targets: ["CoreModelSQLite"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/PureSwift/CoreModel",
            from: "2.8.0"
        ),
        // PureSwift/SQLite wraps the system SQLite3 on Apple platforms and links
        // an embedded SQLite (via swift-sqlcipher) everywhere else, so no separate
        // C SQLite dependency or per-platform branching is needed here.
        .package(
            url: "https://github.com/PureSwift/SQLite",
            branch: "master"
        )
    ],
    targets: [
        .target(
            name: "CoreModelSQLite",
            dependencies: [
                "CoreModel",
                .product(
                    name: "SQLite",
                    package: "SQLite"
                )
            ]
        ),
        .testTarget(
            name: "CoreModelSQLiteTests",
            dependencies: ["CoreModelSQLite"],
            resources: [
                .copy("TestFiles")
            ]
        )
    ]
)

// Skip (skip.dev) Fuse (native) transpilation support
let enableSkipFuse = ProcessInfo.processInfo.environment["SKIP_FUSE"] == "1"
if enableSkipFuse {
    // Skip requires higher minimum deployment targets
    package.platforms = [
        .macOS(.v13),
        .iOS(.v16),
        .watchOS(.v9),
        .tvOS(.v16),
        .macCatalyst(.v16),
    ]
    package.dependencies += [
        .package(url: "https://source.skip.tools/skip.git", from: "1.9.0"),
        .package(url: "https://source.skip.tools/skip-fuse.git", from: "1.0.0"),
    ]
    package.targets[0].dependencies += [
        .product(name: "SkipFuse", package: "skip-fuse")
    ]
    package.targets[0].plugins = (package.targets[0].plugins ?? []) + [
        .plugin(name: "skipstone", package: "skip")
    ]
}
