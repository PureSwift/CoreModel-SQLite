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
