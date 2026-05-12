// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "KeepAwake",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "KeepAwake",
            path: "Sources/KeepAwake",
            exclude: ["Resources/Info.plist"],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/KeepAwake/Resources/Info.plist",
                ])
            ]
        )
    ]
)
