import AppIntents
import SwiftUI
import WidgetKit

@main
struct AquaPulseWidgetsBundle: WidgetBundle {
    var body: some Widget {
        AquaPulseWidget()
        LogGlassControl()
    }
}

struct LogGlassControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "global.huy.AquaPulse.logGlass") {
            ControlWidgetButton(action: LogGlassIntent()) {
                Label("Log glass", systemImage: "drop.fill")
            }
        }
        .displayName("Log water")
        .description("Add one glass to today’s AquaPulse total.")
    }
}
