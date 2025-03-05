// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "MetalKernels",
    platforms: [
        .macOS(.v15), .iOS(.v18)
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
