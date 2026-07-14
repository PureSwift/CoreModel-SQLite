// swift-tools-version: 6.1
import PackageDescription
import Foundation

// Android has no system libsqlite3, so it needs SQLite.swift's embedded
// copy. macOS and Linux keep SQLite.swift's own default for the platform.
let isAndroid = ProcessInfo.processInfo.environment["TARGET_OS_ANDROID"] == "1"

let sqliteDependency: Package.Dependency = isAndroid
    ? .package(
        url: "https://github.com/stephencelis/SQLite.swift.git",
        from: "0.16.0",
        traits: ["SQLiteSwiftCSQLite"]
    )
    : .package(
        url: "https://github.com/stephencelis/SQLite.swift.git",
        from: "0.16.0"
    )

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
            from: "2.7.1"
        ),
        sqliteDependency
    ],
    targets: [
        .target(
            name: "CoreModelSQLite",
            dependencies: [
                "CoreModel",
                .product(
                    name: "SQLite",
                    package: "SQLite.swift"
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
