import Foundation

/// One app that gets a math pause before it opens.
struct AppRule: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    /// Name shown in Flow and in the Shortcuts parameter picker.
    var name: String
    /// URL used to open the target app, e.g. "instagram://". A bare scheme
    /// like "instagram" is accepted too.
    var urlScheme: String
    var settings: ChallengeSettings

    init(id: UUID = UUID(), name: String, urlScheme: String, settings: ChallengeSettings = ChallengeSettings()) {
        self.id = id
        self.name = name
        self.urlScheme = urlScheme
        self.settings = settings
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        urlScheme = try container.decodeIfPresent(String.self, forKey: .urlScheme) ?? ""
        settings = try container.decodeIfPresent(ChallengeSettings.self, forKey: .settings) ?? ChallengeSettings()
    }

    /// Settings that apply at the given moment.
    ///
    /// Phase 2 hook: weekday/time-based overrides (e.g. stricter on workdays)
    /// will be evaluated here. Callers already pass the current date.
    func effectiveSettings(at date: Date) -> ChallengeSettings {
        settings
    }

    /// URL that opens the target app, or nil if the scheme is unusable.
    var launchURL: URL? {
        Self.launchURL(for: urlScheme)
    }

    static func launchURL(for scheme: String) -> URL? {
        let trimmed = scheme.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let text = trimmed.contains(":") ? trimmed : trimmed + "://"
        guard let url = URL(string: text), let scheme = url.scheme, !scheme.isEmpty else { return nil }
        return url
    }
}
