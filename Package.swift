// swift-tools-version:5.6
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import PackageDescription

let package = Package(
  name: "swift-format",
  platforms: [
    .macOS("10.15")
  ],
  products: [
    .executable(
      name: "swift-format",
      targets: ["swift-format"]
    ),
    .library(
      name: "AppleSwiftFormat",
      targets: ["SwiftFormat", "SwiftFormatConfiguration"]
    ),
    .library(
      name: "SwiftFormatConfiguration",
      targets: ["SwiftFormatConfiguration"]
    ),
  ],
  dependencies: [
    // See the "Dependencies" section below.
  ],
  targets: [
    .target(
      name: "SwiftFormat",
      dependencies: [
        "SwiftFormatConfiguration",
        "SwiftFormatCore",
        "SwiftFormatPrettyPrint",
        "SwiftFormatRules",
        "SwiftFormatWhitespaceLinter",
        .product(name: "AppleSwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxParser", package: "swift-syntax"),
      ]
    ),
    .target(
      name: "SwiftFormatConfiguration"
    ),
    .target(
      name: "SwiftFormatCore",
      dependencies: [
        "SwiftFormatConfiguration",
        .product(name: "AppleSwiftSyntax", package: "swift-syntax"),
      ]
    ),
    .target(
      name: "SwiftFormatRules",
      dependencies: ["SwiftFormatCore", "SwiftFormatConfiguration"]
    ),
    .target(
      name: "SwiftFormatPrettyPrint",
      dependencies: ["SwiftFormatCore", "SwiftFormatConfiguration"]
    ),
    .target(
      name: "SwiftFormatTestSupport",
      dependencies: [
        "SwiftFormatCore",
        "SwiftFormatRules",
        "SwiftFormatConfiguration",
      ]
    ),
    .target(
      name: "SwiftFormatWhitespaceLinter",
      dependencies: [
        "SwiftFormatCore",
        .product(name: "AppleSwiftSyntax", package: "swift-syntax"),
      ]
    ),

    .executableTarget(
      name: "generate-pipeline",
      dependencies: [
        "SwiftFormatCore",
        "SwiftFormatRules",
        .product(name: "AppleSwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxParser", package: "swift-syntax"),
      ]
    ),
    .executableTarget(
      name: "swift-format",
      dependencies: [
        "SwiftFormat",
        "SwiftFormatConfiguration",
        "SwiftFormatCore",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "AppleSwiftSyntax", package: "swift-syntax"),
        .product(name: "TSCBasic", package: "swift-tools-support-core"),
      ]
    ),

    .testTarget(
      name: "SwiftFormatTests",
      dependencies: [
        "SwiftFormat",
        .product(name: "AppleSwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxParser", package: "swift-syntax"),
      ]
    ),
    .testTarget(
      name: "SwiftFormatConfigurationTests",
      dependencies: ["SwiftFormatConfiguration"]
    ),
    .testTarget(
      name: "SwiftFormatCoreTests",
      dependencies: [
        "SwiftFormatConfiguration",
        "SwiftFormatCore",
        .product(name: "AppleSwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxParser", package: "swift-syntax"),
      ]
    ),
    .testTarget(
      name: "SwiftFormatPerformanceTests",
      dependencies: [
        "SwiftFormatTestSupport",
        "SwiftFormatWhitespaceLinter",
        .product(name: "AppleSwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxParser", package: "swift-syntax"),
      ]
    ),
    .testTarget(
      name: "SwiftFormatPrettyPrintTests",
      dependencies: [
        "SwiftFormatConfiguration",
        "SwiftFormatCore",
        "SwiftFormatPrettyPrint",
        "SwiftFormatRules",
        "SwiftFormatTestSupport",
        .product(name: "AppleSwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxParser", package: "swift-syntax"),
      ]
    ),
    .testTarget(
      name: "SwiftFormatRulesTests",
      dependencies: [
        "SwiftFormatConfiguration",
        "SwiftFormatCore",
        "SwiftFormatPrettyPrint",
        "SwiftFormatRules",
        "SwiftFormatTestSupport",
        .product(name: "AppleSwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxParser", package: "swift-syntax"),
      ]
    ),
    .testTarget(
      name: "SwiftFormatWhitespaceLinterTests",
      dependencies: [
        "SwiftFormatConfiguration",
        "SwiftFormatCore",
        "SwiftFormatTestSupport",
        "SwiftFormatWhitespaceLinter",
        .product(name: "AppleSwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxParser", package: "swift-syntax"),
      ]
    ),
  ]
)

// MARK: Dependencies

if ProcessInfo.processInfo.environment["SWIFTCI_USE_LOCAL_DEPS"] == nil {
  // Building standalone.
  package.dependencies += [
    .package(
      url: "https://github.com/apple/swift-argument-parser.git",
      branch: "main"
    ),
    .package(
      url: "https://github.com/apple/swift-syntax",
      branch: "main"
    ),
    .package(
      url: "https://github.com/apple/swift-tools-support-core.git",
      branch: "main"
    ),
  ]
} else {
  package.dependencies += [
    .package(path: "../swift-argument-parser"),
    .package(path: "../swift-syntax"),
    .package(path: "../swift-tools-support-core"),
  ]
}
