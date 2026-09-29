import Foundation
import Testing
@testable import Flow

struct MathProblemGeneratorTests {
    private func problems(_ difficulty: Difficulty, count: Int = 2000, seed: UInt64 = 42) -> [MathProblem] {
        var rng = SplitMix64(seed: seed)
        let generator = MathProblemGenerator(difficulty: difficulty)
        return (0..<count).map { _ in generator.makeProblem(using: &rng) }
    }

    @Test(arguments: Difficulty.allCases)
    func exactlyOneCorrectAndFourDistinctOptions(difficulty: Difficulty) {
        for problem in problems(difficulty) {
            #expect(problem.options.count == 4, "\(problem.question)")
            #expect(Set(problem.options).count == 4, "\(problem.question): \(problem.options)")
            #expect(problem.options.filter { $0 == problem.answer }.count == 1, "\(problem.question)")
            #expect(problem.options[problem.correctIndex] == problem.answer)
        }
    }

    @Test(arguments: Difficulty.allCases)
    func answerMatchesQuestion(difficulty: Difficulty) {
        for problem in problems(difficulty) {
            let (x, y) = (problem.operands[0], problem.operands.count > 1 ? problem.operands[1] : 0)
            let expected: Int = switch problem.operation {
            case .addition: x + y
            case .subtraction: x - y
            case .multiplication: x * y
            case .percentage: x * y / 100
            case .square: x * x
            case .division: x / y
            }
            #expect(problem.answer == expected, "\(problem.question)")
            if problem.operation == .percentage { #expect(x * y % 100 == 0, "\(problem.question) is not whole") }
            if problem.operation == .division { #expect(x % y == 0, "\(problem.question) is not whole") }
        }
    }

    @Test(arguments: Difficulty.allCases)
    func wrongOptionsArePositiveAndPlausible(difficulty: Difficulty) {
        for problem in problems(difficulty) {
            for option in problem.options where option != problem.answer {
                #expect(option > 0, "\(problem.question): \(problem.options)")
                #expect(abs(option - problem.answer) <= max(20, problem.answer / 2), "\(problem.question): \(problem.options)")
            }
        }
    }

    @Test func level1Ranges() {
        for p in problems(.level1) {
            #expect([.addition, .subtraction].contains(p.operation))
            #expect(p.operands.allSatisfy { (10...99).contains($0) }, "\(p.question)")
            #expect(p.answer > 0)
        }
    }

    @Test func level2Ranges() {
        for p in problems(.level2) {
            switch p.operation {
            case .multiplication:
                #expect((10...99).contains(p.operands[0]) && (2...9).contains(p.operands[1]), "\(p.question)")
            case .addition, .subtraction:
                #expect(p.operands.allSatisfy { (100...999).contains($0) }, "\(p.question)")
                #expect(p.answer > 0)
            default:
                Issue.record("Unexpected operation \(p.operation) on level 2")
            }
        }
    }

    @Test func level3Ranges() {
        for p in problems(.level3) {
            switch p.operation {
            case .multiplication:
                #expect(p.operands.allSatisfy { (10...99).contains($0) }, "\(p.question)")
            case .percentage:
                #expect(MathProblemGenerator.percentages.contains(p.operands[0]), "\(p.question)")
                #expect((10...400).contains(p.operands[1]), "\(p.question)")
            default:
                Issue.record("Unexpected operation \(p.operation) on level 3")
            }
        }
    }

    @Test func level4Ranges() {
        for p in problems(.level4) {
            switch p.operation {
            case .multiplication:
                #expect((100...999).contains(p.operands[0]) && (10...99).contains(p.operands[1]), "\(p.question)")
            case .square:
                #expect((11...30).contains(p.operands[0]), "\(p.question)")
                #expect(p.answer <= 900)
            case .division:
                #expect((2...19).contains(p.operands[1]) && p.answer >= 10, "\(p.question)")
            default:
                Issue.record("Unexpected operation \(p.operation) on level 4")
            }
        }
    }

    @Test(arguments: Difficulty.allCases)
    func noRepeatsWithinARound(difficulty: Difficulty) {
        var rng = SplitMix64(seed: 7)
        let generator = MathProblemGenerator(difficulty: difficulty)
        var used: Set<String> = []
        for _ in 0..<ChallengeSettings.taskCountRange.upperBound {
            let problem = generator.makeProblem(avoiding: used, using: &rng)
            #expect(!used.contains(problem.key), "Repeated \(problem.question)")
            used.insert(problem.key)
        }
    }

    @Test func correctAnswerPositionIsSpreadOverAllButtons() {
        var counts = [0, 0, 0, 0]
        for problem in problems(.level2, count: 4000) { counts[problem.correctIndex] += 1 }
        for count in counts { #expect(count > 800, "Positions: \(counts)") }
    }

    @Test func sameSeedGivesSameProblems() {
        #expect(problems(.level3, count: 50, seed: 99) == problems(.level3, count: 50, seed: 99))
    }

    @Test func typicalMistakeHelpers() {
        #expect(MathProblemGenerator.swappingLastTwoDigits(of: 85) == 58)
        #expect(MathProblemGenerator.swappingLastTwoDigits(of: 123) == 132)
        #expect(MathProblemGenerator.swappingLastTwoDigits(of: 77) == nil)
        #expect(MathProblemGenerator.swappingLastTwoDigits(of: 7) == nil)
        #expect(MathProblemGenerator.sumWithoutCarry(47, 38) == 75)
        #expect(MathProblemGenerator.differenceWithoutBorrow(52, 38) == 26)
    }
}
