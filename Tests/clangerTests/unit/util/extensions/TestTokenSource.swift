@testable import clanger

/** Test helper which represents a stream of C Tokens similar to what you'd get
    from a TokeStream.
*/
public class TestTokenStream: TokenSource {
  public init(_ tokens: [CToken]) {
    self.tokens = tokens
  }

  public func next() -> CToken? {
    defer { self.currentTokenIdx += 1 }
    if self.currentTokenIdx >= self.tokens.count {
      return nil
    }
    return self.tokens[self.currentTokenIdx]
  }

  public var current: CToken? {
    return self.tokens[self.currentTokenIdx - 1]
  }

  public var line = 0, column = 0

  // MARK: - Internal
  internal let tokens: [CToken]
  internal var currentTokenIdx = 0
}