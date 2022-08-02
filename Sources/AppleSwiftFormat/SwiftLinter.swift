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
import SwiftFormatConfiguration
import SwiftFormatCore
import SwiftFormatPrettyPrint
import SwiftFormatRules
import SwiftFormatWhitespaceLinter
import SwiftSyntax
import SwiftSyntaxParser

/// Diagnoses and reports problems in Swift source code or syntax trees according to the Swift style
/// guidelines.
public final class SwiftLinter {

  /// The configuration settings that control the linter's behavior.
  public let configuration: Configuration

  /// A callback that will be notified with any findings encountered during linting.
  public let findingConsumer: (Finding) -> Void

  /// Advanced options that are useful when debugging the linter's behavior but are not meant for
  /// general use.
  public var debugOptions: DebugOptions = []

  /// Creates a new Swift code linter with the given configuration.
  ///
  /// - Parameters:
  ///   - configuration: The configuration settings that control the linter's behavior.
  ///   - findingConsumer: A callback that will be notified with any findings encountered during
  ///     linting.
  public init(configuration: Configuration, findingConsumer: @escaping (Finding) -> Void) {
    self.configuration = configuration
    self.findingConsumer = findingConsumer
  }

  /// Lints the Swift code at the given file URL.
  ///
  /// - Parameters:
  ///   - url: The URL of the file containing the code to format.
  ///   - parsingDiagnosticHandler: An optional callback that will be notified if there are any
  ///     errors when parsing the source code.
  /// - Throws: If an unrecoverable error occurs when formatting the code.
  public func lint(
    contentsOf url: URL,
    parsingDiagnosticHandler: ((Diagnostic) -> Void)? = nil
  ) throws {
    guard FileManager.default.isReadableFile(atPath: url.path) else {
      throw SwiftFormatError.fileNotReadable
    }
    var isDir: ObjCBool = false
    if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
      throw SwiftFormatError.isDirectory
    }
    let sourceFile = try SyntaxParser.parse(url, diagnosticHandler: parsingDiagnosticHandler)
    let source = try String(contentsOf: url, encoding: .utf8)
    try lint(syntax: sourceFile, assumingFileURL: url, source: source)
  }

  /// Lints the given Swift source code.
  ///
  /// - Parameters:
  ///   - source: The Swift source code to be linted.
  ///   - url: A file URL denoting the filename/path that should be assumed for this source code.
  ///   - parsingDiagnosticHandler: An optional callback that will be notified if there are any
  ///     errors when parsing the source code.
  /// - Throws: If an unrecoverable error occurs when formatting the code.
  public func lint(
    source: String,
    assumingFileURL url: URL,
    parsingDiagnosticHandler: ((Diagnostic) -> Void)? = nil
  ) throws {
    let sourceFile =
      try SyntaxParser.parse(source: source, diagnosticHandler: parsingDiagnosticHandler)
    try lint(syntax: sourceFile, assumingFileURL: url, source: source)
  }

  /// Lints the given Swift syntax tree.
  ///
  /// - Note: The linter may be faster using the source text, if it's available.
  ///
  /// - Parameters:
  ///   - syntax: The Swift syntax tree to be converted to be linted.
  ///   - url: A file URL denoting the filename/path that should be assumed for this syntax tree.
  /// - Throws: If an unrecoverable error occurs when formatting the code.
  public func lint(syntax: SourceFileSyntax, assumingFileURL url: URL) throws {
    try lint(syntax: syntax, assumingFileURL: url, source: nil)
  }

  private func lint(syntax: SourceFileSyntax, assumingFileURL url: URL, source: String?) throws {
    if let position = _firstInvalidSyntaxPosition(in: Syntax(syntax)) {
      throw SwiftFormatError.fileContainsInvalidSyntax(position: position)
    }

    let context = Context(
      configuration: configuration, findingConsumer: findingConsumer, fileURL: url,
      sourceFileSyntax: syntax, source: source, ruleNameCache: ruleNameCache)
    let pipeline = LintPipeline(context: context)
    pipeline.walk(Syntax(syntax))

    if debugOptions.contains(.disablePrettyPrint) {
      return
    }

    // Perform whitespace linting by comparing the input source text with the output of the
    // pretty-printer.
    let operatorContext = OperatorContext.makeBuiltinOperatorContext()
    let printer = PrettyPrinter(
      context: context,
      operatorContext: operatorContext,
      node: Syntax(syntax),
      printTokenStream: debugOptions.contains(.dumpTokenStream),
      whitespaceOnly: true)
    let formatted = printer.prettyPrint()
    let ws = WhitespaceLinter(user: syntax.description, formatted: formatted, context: context)
    ws.lint()
  }
}
