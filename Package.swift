// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AIMeter",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "AIMeterDomain", targets: ["AIMeterDomain"]),
        .library(name: "AIMeterApplication", targets: ["AIMeterApplication"]),
        .library(name: "AIMeterInfrastructure", targets: ["AIMeterInfrastructure"]),
        .library(name: "AIMeterPresentation", targets: ["AIMeterPresentation"]),
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.8.0"),
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.0.0"),
    ],
    targets: [
        // Domain - NO dependencies (Foundation only)
        .target(
            name: "AIMeterDomain",
            dependencies: [],
            path: "Sources/AIMeterDomain"
        ),

        // Application - depends on Domain
        .target(
            name: "AIMeterApplication",
            dependencies: ["AIMeterDomain"],
            path: "Sources/AIMeterApplication"
        ),

        // Infrastructure - depends on Domain, Application, KeyboardShortcuts
        .target(
            name: "AIMeterInfrastructure",
            dependencies: [
                "AIMeterDomain",
                "AIMeterApplication",
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
            ],
            path: "Sources/AIMeterInfrastructure"
        ),

        // Presentation - depends on Domain, Application, Sparkle, KeyboardShortcuts
        .target(
            name: "AIMeterPresentation",
            dependencies: [
                "AIMeterDomain",
                "AIMeterApplication",
                .product(name: "Sparkle", package: "Sparkle"),
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
            ],
            path: "Sources/AIMeterPresentation"
        ),

        // Tests
        .testTarget(
            name: "AIMeterDomainTests",
            dependencies: ["AIMeterDomain"],
            path: "Tests/AIMeterDomainTests"
        ),
        .testTarget(
            name: "AIMeterApplicationTests",
            dependencies: ["AIMeterApplication", "AIMeterDomain"],
            path: "Tests/AIMeterApplicationTests"
        ),
        .testTarget(
            name: "AIMeterInfrastructureTests",
            dependencies: ["AIMeterInfrastructure", "AIMeterDomain"],
            path: "Tests/AIMeterInfrastructureTests"
        ),
        .testTarget(
            name: "AIMeterPresentationTests",
            dependencies: ["AIMeterPresentation", "AIMeterApplication", "AIMeterDomain"],
            path: "Tests/AIMeterPresentationTests"
        ),
    ]
)
