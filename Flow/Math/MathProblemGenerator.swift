import Foundation

/// Creates random mental-math tasks with four answer options.
///
/// Wrong options are modelled on typical calculation mistakes (off by 10 or 1,
/// swapped digits, forgotten carry/borrow, one row too many or too few in a
/// multiplication, ...), so they look plausible.
struct MathProblemGenerator: Sendable {
    let difficulty: Difficulty

    static let optionCount = 4

    /// A new task whose `key` is not in `usedKeys` (no repeats within a round).
    /// Falls back to a repeat only if no unused task was found after many tries.
    func makeProblem(avoiding usedKeys: Set<String> = [], using rng: inout some RandomNumberGenerator) -> MathProblem {
        var problem = makeAnyProblem(using: &rng)
        var attempts = 0
        while usedKeys.contains(problem.key) && attempts < 500 {
            problem = makeAnyProblem(using: &rng)
            attempts += 1
        }
        return problem
    }

    /// Operations used on each level.
    static func operations(for difficulty: Difficulty) -> [MathOperation] {
        switch difficulty {
        case .level1: [.addition, .subtraction]
        case .level2: [.multiplication, .addition, .subtraction]
        case .level3: [.multiplication, .percentage]
        case .level4: [.multiplication, .square, .division]
        }
    }

    static let percentages = [10, 20, 25, 30, 40, 50, 75]

    // MARK: - Tasks

    private func makeAnyProblem(using rng: inout some RandomNumberGenerator) -> MathProblem {
        let operation = Self.operations(for: difficulty).randomElement(using: &rng)!
        let operands = makeOperands(for: operation, using: &rng)
        let answer = Self.solve(operation, operands)
        let wrong = Self.distractors(for: operation, operands: operands, answer: answer, using: &rng)
        let options = ([answer] + wrong).shuffled(using: &rng)
        return MathProblem(operation: operation, operands: operands, answer: answer, options: options)
    }

    private func makeOperands(for operation: MathOperation, using rng: inout some RandomNumberGenerator) -> [Int] {
        switch (difficulty, operation) {
        case (.level1, .addition):
            return [Int.random(in: 10...99, using: &rng), Int.random(in: 10...99, using: &rng)]
        case (.level1, .subtraction):
            let a = Int.random(in: 20...99, using: &rng)
            return [a, Int.random(in: 10...(a - 1), using: &rng)]
        case (.level2, .multiplication):
            return [Int.random(in: 12...99, using: &rng), Int.random(in: 3...9, using: &rng)]
        case (.level2, .addition):
            return [Int.random(in: 100...999, using: &rng), Int.random(in: 100...999, using: &rng)]
        case (.level2, .subtraction):
            let a = Int.random(in: 200...999, using: &rng)
            return [a, Int.random(in: 100...(a - 1), using: &rng)]
        case (.level3, .multiplication):
            return [Self.randomNonRound(in: 11...99, using: &rng), Self.randomNonRound(in: 11...99, using: &rng)]
        case (.level3, .percentage):
            let percent = Self.percentages.randomElement(using: &rng)!
            // Smallest base step that makes "percent % of base" a whole number.
            let step = 100 / Self.gcd(percent, 100)
            let base = step * Int.random(in: max(1, 20 / step)...(400 / step), using: &rng)
            return [percent, base]
        case (.level4, .multiplication):
            return [Self.randomNonRound(in: 101...999, using: &rng), Self.randomNonRound(in: 11...99, using: &rng)]
        case (.level4, .square):
            return [Int.random(in: 11...30, using: &rng)]
        case (.level4, .division):
            let divisor = [3, 4, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15, 16, 17, 18, 19].randomElement(using: &rng)!
            let quotient = Int.random(in: 12...99, using: &rng)
            return [divisor * quotient, divisor]
        default:
            preconditionFailure("Operation \(operation) is not used on \(difficulty)")
        }
    }

    static func solve(_ operation: MathOperation, _ operands: [Int]) -> Int {
        switch operation {
        case .addition: operands[0] + operands[1]
        case .subtraction: operands[0] - operands[1]
        case .multiplication: operands[0] * operands[1]
        case .percentage: operands[0] * operands[1] / 100
        case .square: operands[0] * operands[0]
        case .division: operands[0] / operands[1]
        }
    }

    // MARK: - Wrong answers

    /// Three distinct, positive, plausible wrong answers.
    static func distractors(
        for operation: MathOperation,
        operands: [Int],
        answer: Int,
        using rng: inout some RandomNumberGenerator
    ) -> [Int] {
        var candidates = typicalMistakes(for: operation, operands: operands, answer: answer)
        candidates.shuffle(using: &rng)
        // Generic near misses as a fallback, tried in this order.
        candidates += [2, -2, 3, -3, 20, -20, 11, -11, 9, -9, 5, -5, 4, -4, 6, -6].map { answer + $0 }

        var result: [Int] = []
        for candidate in candidates where result.count < optionCount - 1 {
            if isPlausible(candidate, for: answer) && !result.contains(candidate) {
                result.append(candidate)
            }
        }
        return result
    }

    static func isPlausible(_ candidate: Int, for answer: Int) -> Bool {
        candidate > 0 && candidate != answer && abs(candidate - answer) <= max(20, answer / 2)
    }

    static func typicalMistakes(for operation: MathOperation, operands: [Int], answer: Int) -> [Int] {
        var mistakes = [answer + 10, answer - 10, answer + 1, answer - 1]
        if let swapped = swappingLastTwoDigits(of: answer) { mistakes.append(swapped) }
        if answer >= 200 { mistakes += [answer + 100, answer - 100] }

        switch operation {
        case .addition:
            mistakes.append(sumWithoutCarry(operands[0], operands[1]))
        case .subtraction:
            mistakes.append(differenceWithoutBorrow(operands[0], operands[1]))
        case .multiplication:
            // One row too many or too few: a × (b ± 1), (a ± 1) × b.
            let (a, b) = (operands[0], operands[1])
            mistakes += [answer + a, answer - a, answer + b, answer - b]
        case .percentage:
            let (percent, base) = (operands[0], operands[1])
            for other in [percent - 5, percent + 5, percent - 10, percent + 10] where other > 0 && other * base % 100 == 0 {
                mistakes.append(other * base / 100)
            }
        case .square:
            let n = operands[0]
            mistakes += [(n - 1) * (n - 1), (n + 1) * (n + 1), n * (n + 1), n * (n - 1)]
        case .division:
            let (dividend, divisor) = (operands[0], operands[1])
            mistakes += [answer + 2, answer - 2]
            for other in [divisor - 1, divisor + 1] where other > 1 && dividend % other == 0 {
                mistakes.append(dividend / other)
            }
        }
        return mistakes
    }

    // MARK: - Helpers

    /// 85 → 58, 123 → 132. Nil if the last two digits are equal or there is only one digit.
    static func swappingLastTwoDigits(of value: Int) -> Int? {
        guard value >= 10 else { return nil }
        let units = value % 10
        let tens = value / 10 % 10
        guard units != tens else { return nil }
        return value - tens * 10 - units + units * 10 + tens
    }

    /// Column-wise addition that drops every carry: 47 + 38 → 75.
    static func sumWithoutCarry(_ a: Int, _ b: Int) -> Int {
        columnWise(a, b) { ($0 + $1) % 10 }
    }

    /// Column-wise "smaller from larger" subtraction: 52 − 38 → 26.
    static func differenceWithoutBorrow(_ a: Int, _ b: Int) -> Int {
        columnWise(a, b) { abs($0 - $1) }
    }

    private static func columnWise(_ a: Int, _ b: Int, digit combine: (Int, Int) -> Int) -> Int {
        var (a, b, result, place) = (a, b, 0, 1)
        while a > 0 || b > 0 {
            result += combine(a % 10, b % 10) * place
            a /= 10
            b /= 10
            place *= 10
        }
        return result
    }

    private static func randomNonRound(in range: ClosedRange<Int>, using rng: inout some RandomNumberGenerator) -> Int {
        var value = Int.random(in: range, using: &rng)
        while value % 10 == 0 { value = Int.random(in: range, using: &rng) }
        return value
    }

    private static func gcd(_ a: Int, _ b: Int) -> Int {
        b == 0 ? a : gcd(b, a % b)
    }
}
