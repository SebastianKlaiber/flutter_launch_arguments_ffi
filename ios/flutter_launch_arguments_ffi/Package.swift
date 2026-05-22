// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flutter_launch_arguments_ffi",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "flutter-launch-arguments-ffi", targets: ["flutter_launch_arguments_ffi"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "flutter_launch_arguments_ffi",
            dependencies: [
                .target(name: "flutter_launch_arguments_ffi_native"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                // If this plugin requires a privacy manifest, update
                // PrivacyInfo.xcprivacy and uncomment the resource below.
                // .process("PrivacyInfo.xcprivacy"),
            ]
        ),
        .target(
            name: "flutter_launch_arguments_ffi_native",
            path: "Sources/flutter_launch_arguments_ffi_native",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include")
            ]
        )
    ],
    cLanguageStandard: .c11
)
