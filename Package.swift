// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftXAtlas",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SwiftXAtlas",
            targets: ["SwiftXAtlas"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/tatsuya-ogawa/SwiftStanfordBunny.git", from: "1.0.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "XAtlasCpp",
            dependencies: [],
            path: "xatlas/source/xatlas",
            publicHeadersPath: "",
            cxxSettings: [
            ]
        ),
        .target(
            name: "XAtlasObjc",
            dependencies: ["XAtlasCpp"],
            path: "XAtlasObjc",
            publicHeadersPath: ""),
        .target(
            name: "SwiftXAtlas",
            dependencies: ["XAtlasObjc"],
            path: "SwiftXAtlas",
            resources: [
//                .process("Resources")
            ]
        ),
        .testTarget(
            name: "SwiftXAtlasTests",
            dependencies: ["SwiftXAtlas",
                          "SwiftStanfordBunny"]),
    ],
    cxxLanguageStandard: .cxx14
)
