// swift-tools-version: 6.0
import PackageDescription

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
            from: "2.4.3"
        ),
        .package(
            url: "https://github.com/stephencelis/SQLite.swift.git",
            from: "0.15.4"
        )
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
            dependencies: ["CoreModelSQLite"]
        )
    ]
)
