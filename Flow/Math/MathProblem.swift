import Foundation

enum MathOperation: String, Codable, Sendable, CaseIterable {
    case addition
    case subtraction
    case multiplication
    case percentage
    case square
    case division
}

/// One multiple-choice task. `options` always has 4 distinct values, exactly
/// one of them equals `answer`.
struct MathProblem: Hashable, Sendable {
    let operation: MathOperation
    /// Operands in reading order, e.g. [47, 38] for "47 + 38",
    /// [25, 80] for "25 % von 80", [17] for "17²".
    let operands: [Int]
    let answer: Int
    let options: [Int]

    var correctIndex: Int {
        options.firstIndex(of: answer) ?? 0
    }

    /// Identifies the task independent of option order (used to avoid repeats).
    var key: String {
        "\(operation.rawValue):\(operands.map(String.init).joined(separator: ","))"
    }

    /// Question as shown on screen.
    var question: String {
        switch operation {
        case .addition: "\(operands[0]) + \(operands[1])"
        case .subtraction: "\(operands[0]) − \(operands[1])"
        case .multiplication: "\(operands[0]) × \(operands[1])"
        case .percentage: "\(operands[0]) % " + String(localized: "von") + " \(operands[1])"
        case .square: "\(operands[0])²"
        case .division: "\(operands[0]) ÷ \(operands[1])"
        }
    }

    /// Question for VoiceOver ("47 plus 38").
    var spokenQuestion: String {
        switch operation {
        case .addition: String(localized: "\(operands[0]) plus \(operands[1])")
        case .subtraction: String(localized: "\(operands[0]) minus \(operands[1])")
        case .multiplication: String(localized: "\(operands[0]) mal \(operands[1])")
        case .percentage: String(localized: "\(operands[0]) Prozent von \(operands[1])")
        case .square: String(localized: "\(operands[0]) zum Quadrat")
        case .division: String(localized: "\(operands[0]) geteilt durch \(operands[1])")
        }
    }
}
