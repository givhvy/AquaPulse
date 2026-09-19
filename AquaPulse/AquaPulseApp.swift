import SwiftUI

@main
struct AquaPulseApp: App {
    @State private var store = AquaStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if store.didOnboard {
                    AquaRoot()
                } else {
                    OnboardingView()
                }
            }
            .environment(store)
            .preferredColorScheme(.dark)
            #if DEBUG
            .onAppear { applyDebugLaunchSeed(store) }
            #endif
        }
    }
}

struct AquaRoot: View {
    @State private var tab: MainTab = {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-screen"), args.indices.contains(i + 1) {
            switch args[i + 1] {
            case "rituals": return .rituals
            case "week": return .week
            default: return .home
            }
        }
        return .home
    }()

    var body: some View {
        TabView(selection: $tab) {
            Tab("Home", systemImage: "house.fill", value: MainTab.home) {
                HomeView(tab: $tab)
            }
            Tab("Rituals", systemImage: "calendar", value: MainTab.rituals) {
                RitualsView()
            }
            Tab("Board", systemImage: "circle.grid.2x2", value: MainTab.week) {
                WeekView()
            }
        }
        .tint(Aqua.mint)
        .aquaTabMinimize()
    }
}

#if DEBUG
@MainActor
private func applyDebugLaunchSeed(_ store: AquaStore) {
    let args = ProcessInfo.processInfo.arguments
    guard args.contains("-seedSession"), !store.didOnboard else { return }
    store.finishOnboarding(name: "Huy", goalML: 2000, glassML: 250, extraKinds: ["stretch"])
    store.setGlasses(3)
}
#endif
