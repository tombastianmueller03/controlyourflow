import AppIntents
import Foundation

/// A configured app rule as a Shortcuts parameter ("Ziel-App").
struct RuleEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Ziel-App"
    static let defaultQuery = RuleEntityQuery()

    let id: UUID
    let name: String

    init(rule: AppRule) {
        id = rule.id
        name = rule.name
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

/// Offers the rules created in Flow as choices in Shortcuts.
struct RuleEntityQuery: EnumerableEntityQuery {
    func allEntities() async throws -> [RuleEntity] {
        await MainActor.run { RuleStore.shared.rules.map(RuleEntity.init(rule:)) }
    }

    func entities(for identifiers: [RuleEntity.ID]) async throws -> [RuleEntity] {
        try await allEntities().filter { identifiers.contains($0.id) }
    }
}
