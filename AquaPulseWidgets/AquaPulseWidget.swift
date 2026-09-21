import SwiftUI
import WidgetKit

struct AquaEntry: TimelineEntry {
    let date: Date
    let snapshot: AquaSnapshot
}

struct AquaProvider: TimelineProvider {
    func placeholder(in context: Context) -> AquaEntry {
        AquaEntry(date: Date(), snapshot: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (AquaEntry) -> Void) {
        let snap = context.isPreview ? AquaSnapshot.preview : AquaPulseData.load()
        completion(AquaEntry(date: Date(), snapshot: snap))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AquaEntry>) -> Void) {
        let snap = AquaPulseData.load()
        let now = Date()
        let midnight = Calendar.current.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 1),
            matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(3600)
        completion(Timeline(entries: [AquaEntry(date: now, snapshot: snap)], policy: .after(midnight)))
    }
}

struct AquaPulseWidget: Widget {
    let kind = "AquaPulseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AquaProvider()) { entry in
            AquaPulseWidgetView(entry: entry)
        }
        .configurationDisplayName("AquaPulse")
        .description("See today’s water and log a glass from the Home Screen.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
        .contentMarginsDisabled()
    }
}

struct AquaPulseWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: AquaEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                AquaSmallWidget(snap: entry.snapshot)
            case .systemMedium:
                AquaMediumWidget(snap: entry.snapshot)
            case .systemLarge:
                AquaLargeWidget(snap: entry.snapshot)
            case .accessoryCircular:
                AquaLockCircle(snap: entry.snapshot)
            case .accessoryRectangular:
                AquaLockRect(snap: entry.snapshot)
            case .accessoryInline:
                Text("AquaPulse \(entry.snapshot.litersDrunk)L · \(entry.snapshot.remainingLabel)")
            default:
                AquaSmallWidget(snap: entry.snapshot)
            }
        }
        .containerBackground(for: .widget) {
            switch family {
            case .accessoryCircular, .accessoryRectangular, .accessoryInline:
                AccessoryWidgetBackground()
            default:
                Aqua.night
            }
        }
    }
}

#Preview("Small", as: .systemSmall) {
    AquaPulseWidget()
} timeline: {
    AquaEntry(date: .now, snapshot: .preview)
}

#Preview("Medium", as: .systemMedium) {
    AquaPulseWidget()
} timeline: {
    AquaEntry(date: .now, snapshot: .preview)
}

#Preview("Large", as: .systemLarge) {
    AquaPulseWidget()
} timeline: {
    AquaEntry(date: .now, snapshot: .preview)
}
