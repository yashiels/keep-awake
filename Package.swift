// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "KeepAwake",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "KeepAwake",
            path: "Sources/KeepAwake",
            exclude: ["Resources/Info.plist", "Resources/AppIcon.icns"],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/KeepAwake/Resources/Info.plist",
                ])
            ]
        ),
        .testTarget(
            name: "KeepAwakeTests",
            dependencies: ["KeepAwake"],
            path: "Tests/KeepAwakeTests"
        ),
    ]
)
