// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "realNTFS",
    platforms: [
        .macOS(.v11)
    ],
    targets: [
        .executableTarget(
            name: "realNTFS",
            path: "Sources"
        ),
    ]
)
