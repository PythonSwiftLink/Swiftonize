public struct PythonSwiftLinkParser {
    public private(set) var text = "Hello, World!"

    public init() {
    }
}

public extension String {
    func titleCase() -> String {
        return self
            .replacingOccurrences(of: "([A-Z])",
                                  with: "_$1",
                                  options: .regularExpression,
                                  range: range(of: self))
        // If input is in llamaCase
            .lowercased()
    }

    func lowercaseFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
    
    mutating func lowercaseFirstLetter() {
        self = self.lowercaseFirstLetter()
    }
    
    func addTabs() -> Self {
        replacingOccurrences(of: newLine, with: newLineTab)
    }
    var newLineTabbed: String { replacingOccurrences(of: newLine, with: newLineTab) }
    
    static let _nil = "nil"
}


