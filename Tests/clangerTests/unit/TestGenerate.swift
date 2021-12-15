import Foundation
import XCTest

@testable import clanger

/// Tests the contract between the Parser and the assembly Generator
/// Takes ASTs and tests that they're correctly transformed into assembly.
class TestGenerator: XCTestCase {
  // MARK: Expressions
  func testConstants() {
    testExpression( .integerConstant(9001), "movl  $9001, %eax" )
  }

  func testUnaryOps() {
    // -3
    testExpression(
      .unaryOp(.negation, .integerConstant(3)),
      """
      movl    $3, %eax
      neg     %eax
      """
    )
    // ~7
    testExpression(
      .unaryOp(.bitwiseComplement, .integerConstant(7)),
      """
      movl    $7, %eax
      not     %eax
      """
    )
    // !1
    testExpression(
      .unaryOp(.logicalNegation, .integerConstant(1)),
      """
      movl    $1, %eax
      cmpl    $0, %eax
      movl    $0, %eax
      sete    %al
      """
    )

    // Nested
    // --842
    testExpression(
      .unaryOp(.negation, .unaryOp(.negation, .integerConstant(842))),
      """
      movl    $842, %eax
      neg     %eax
      neg     %eax
      """
    )
    // !!1337
    testExpression(
      .unaryOp(
        .logicalNegation,
        .unaryOp(
          .logicalNegation,
          .integerConstant(1337)
        )
      ),
      """
      movl    $1337, %eax
      cmpl    $0, %eax
      movl    $0, %eax
      sete    %al
      cmpl    $0, %eax
      movl    $0, %eax
      sete    %al
      """
    )
  }

  // MARK: Statements
  func testReturn() {
    // return 42
    testStatement(
      Statement.return( Expression.integerConstant(42)),
      """
      movl    $42, %eax
      ret
      """
    )
  }

  // MARK: Functions
  func testFunctionSimpleReturn() {
    testFunction(
      Function(
        "meaning_of_life",
        Statement.return( Expression.integerConstant(42))
      ),
      """
          .globl _meaning_of_life
      _meaning_of_life:
          movl    $42, %eax
          ret
      """
    )
  }

  // Programs
  func testReturn0() {
    testProgram(
      Program(
        Function(
          "main",
          Statement.return( Expression.integerConstant(0))
        )
      ),
      """
          .globl _main
      _main:
          movl    $0, %eax
          ret
      """
    )
  }

  // MARK: - Private
  private func testProgram(_ program: Program, _ expected: String) {
    test({ $0.genProgram(program) }, expected)
  }

  private func testFunction(_ function: Function, _ expected: String) {
    test({ $0.genFunction(function) }, expected)
  }

  private func testStatement(_ statement: Statement, _ expected: String) {
    test({ $0.genStatement(statement) }, expected)
  }

  private func testExpression(_ expression: Expression, _ expected: String) {
    test({ $0.genExpression(expression) }, expected)
  }

  private func test(_ genFunction: (Generator) -> (), _ expected: String) {
    let out = TestOutputHandler()
    let gen = Generator(out)
    genFunction(gen)
    AssertAssemblyEqual(out.value, expected)
  }
}

fileprivate func AssertAssemblyEqual(
  _ actual: String,
  _ expected: String,
  file: StaticString = #filePath,
  line: UInt = #line
) {
  let actualTokens = AssemblyTokenSequence(CharacterStream(InputStream(string: actual)))
  let expectedTokens = AssemblyTokenSequence(CharacterStream(InputStream(string: expected)))
  for (actualToken, expectedToken) in zip(actualTokens, expectedTokens) {
    if actualToken != expectedToken {
      XCTFail("""
        XCTAssertion fail: assembly not equal at \(actualToken) (expected \(expectedToken)):

        \(actual)

        does not equal expected:

        \(expected)\n
        """,
        file: file,
        line: line
      )
    }
  }
}
