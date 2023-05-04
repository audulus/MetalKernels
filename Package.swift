// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "MetalKernels",
    platforms: [
        .macOS(.v11), .iOS(.v14)
    ],
    products: [
        .library(
            name: "MetalKernels",
            targets: ["MetalKernels"]),
    ],
    targets: [
        .target(
            name: "MetalKernels",
            dependencies: []),
        .testTarget(
            name: "MetalKernelsTests",
            dependencies: ["MetalKernels"]),
    ],
    cxxLanguageStandard: .cxx14
)
