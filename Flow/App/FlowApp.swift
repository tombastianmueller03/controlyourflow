import AppIntents
import SwiftUI

@main
struct FlowApp: App {
    @State private var router: FlowRouter
    @State private var ruleStore = RuleStore.shared
    @State private var stats = StatsStore.shared
    @State private var passes = LaunchPassStore.shared

    init() {
        let router = FlowRouter()
        _router = State(initialValue: router)
        // Makes the router available to StartFlowIntent via @Dependency.
        // UNVERIFIED on device: that App.init also runs when the system launches
        // the app in the background just to perform the intent.
        AppDependencyManager.shared.add(dependency: router)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(router)
                .environment(ruleStore)
                .environment(stats)
                .environment(passes)
        }
    }
}
