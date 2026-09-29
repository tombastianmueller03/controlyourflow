import SwiftUI

/// Switches between the math pause, a notice and the normal app content.
struct RootView: View {
    @Environment(FlowRouter.self) private var router
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if let session = router.activeSession {
                ChallengeView(
                    session: session,
                    onPassed: { Task { await router.challengePassed() } },
                    onCancel: { router.cancelChallenge() }
                )
                .id(session.id)
            } else if let notice = router.notice {
                NoticeView(notice: notice) { router.notice = nil }
            } else {
                HomeView()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            // A notice is only meaningful right after the pause.
            if phase == .background { router.notice = nil }
        }
    }
}
