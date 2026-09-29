import Foundation

/// Presets for common apps. None of these schemes is officially documented by
/// the app vendor for launching the app; all are UNVERIFIED until tested on a device.
struct AppTemplate: Identifiable, Hashable, Sendable {
    let name: String
    let urlScheme: String

    var id: String { name }

    static let all: [AppTemplate] = [
        AppTemplate(name: "Instagram", urlScheme: "instagram://"),
        AppTemplate(name: "YouTube", urlScheme: "youtube://"),
        // TikTok's SDK docs list "snssdk1233" to detect the app; no evidence for "tiktok://".
        AppTemplate(name: "TikTok", urlScheme: "snssdk1233://"),
        // No evidence found for "x://".
        AppTemplate(name: "X", urlScheme: "twitter://"),
        AppTemplate(name: "Facebook", urlScheme: "fb://"),
        // Lowest confidence of the list.
        AppTemplate(name: "Reddit", urlScheme: "reddit://"),
        AppTemplate(name: "Snapchat", urlScheme: "snapchat://"),
        AppTemplate(name: "WhatsApp", urlScheme: "whatsapp://"),
    ]
}
