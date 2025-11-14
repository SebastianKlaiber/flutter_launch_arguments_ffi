// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "flutter_launch_arguments_ffi",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "flutter_launch_arguments_ffi",
            targets: ["flutter_launch_arguments_ffi"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "flutter_launch_arguments_ffi",
            dependencies: [],
            path: "Sources/flutter_launch_arguments_ffi",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include"),
            ]
        )
    ],
    cLanguageStandard: .c11
)
