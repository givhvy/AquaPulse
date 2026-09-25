import SwiftUI
import UIKit
import UserNotifications

@main
struct AquaPulseApp: App {
    @UIApplicationDelegateAdaptor(AquaAppDelegate.self) private var appDelegate
    @State private var store = AquaStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("-widgets") {
                    WidgetGalleryView()
                } else if store.didOnboard {
                    AquaRoot()
                } else {
                    OnboardingView()
                }
                #else
                if store.didOnboard {
                    AquaRoot()
                } else {
                    OnboardingView()
                }
                #endif
            }
            .environment(store)
            .preferredColorScheme(.dark)
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                Task { @MainActor in
                    store.reloadFromDisk()
                }
            }
            .onAppear {
                #if DEBUG
                applyDebugLaunchSeed(store)
                scheduleDebugNotificationIfNeeded()
                #endif
            }
            .onOpenURL { url in
                store.reloadFromDisk()
                if url.host == "log" {
                    store.logGlass()
                }
            }
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

final class AquaAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        AquaNotifyCenter.bootstrap()
        return true
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

private func scheduleDebugNotificationIfNeeded() {
    guard ProcessInfo.processInfo.arguments.contains("-debugNotification") else { return }
    let content = UNMutableNotificationContent()
    content.title = "Time to hydrate"
    content.body = "500 ml left to hit 2.0 L (6/8 glasses)."
    content.sound = .default
    content.categoryIdentifier = AquaNotifications.waterCategory
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
    let request = UNNotificationRequest(identifier: "debug.tap", content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request)
}
#endif
