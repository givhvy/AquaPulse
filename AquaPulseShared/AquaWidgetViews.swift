import AppIntents
import SwiftUI
import WidgetKit

struct AquaSmallWidget: View {
    var snap: AquaSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "drop.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Aqua.mint)
                Text("AquaPulse")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Aqua.muted)
                Spacer(minLength: 0)
            }
            Spacer(minLength: 4)
            HStack(alignment: .center, spacing: 10) {
                AquaRing(progress: snap.progress, size: 54, line: 6)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(snap.litersDrunk) L")
                        .font(.system(size: 22, weight: .light))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    Text("\(snap.glassesDrunk)/\(snap.glassesGoal)")
                        .font(.system(size: 11))
                        .foregroundStyle(Aqua.muted)
                }
                Spacer(minLength: 0)
            }
            Spacer(minLength: 8)
            Button(intent: LogGlassIntent()) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Log \(snap.glassML) ml")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(Aqua.glow, in: Capsule())
                .overlay(
                    Capsule().stroke(
                        LinearGradient(colors: [Aqua.mint.opacity(0.08), Aqua.mint], startPoint: .top, endPoint: .bottom),
                        lineWidth: 0.7
                    )
                )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .widgetURL(URL(string: "aquapulse://home"))
    }
}

struct AquaMediumWidget: View {
    var snap: AquaSnapshot
    private var ritual: Ritual? { snap.nextOpenRitual }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 14) {
                AquaRing(progress: snap.progress, size: 72, line: 7)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Hi \(snap.firstName)")
                        .font(.system(size: 12))
                        .foregroundStyle(Aqua.muted)
                    Text(snap.isGoalMet ? "Goal met" : "Ready to hydrate?")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(.white)
                    Text("\(snap.litersDrunk) L  ·  \(snap.litersGoal) L goal")
                        .font(.system(size: 12))
                        .foregroundStyle(Aqua.mint.opacity(0.85))
                    Text(snap.remainingLabel)
                        .font(.system(size: 11))
                        .foregroundStyle(Aqua.muted)
                }
                Spacer(minLength: 0)
            }
            Spacer(minLength: 10)
            HStack(spacing: 8) {
                Button(intent: LogGlassIntent()) {
                    WidgetCTA(title: "Log \(snap.glassML) ml", symbol: "drop.fill", glow: true)
                }
                .buttonStyle(.plain)
                Button(intent: CheckInRitualIntent()) {
                    if let ritual {
                        WidgetCTA(title: ritual.name, symbol: ritual.symbol, glow: false)
                    } else {
                        WidgetCTA(title: "All rituals in", symbol: "checkmark", glow: false)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .widgetURL(URL(string: "aquapulse://home"))
    }
}

struct AquaLargeWidget: View {
    var snap: AquaSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Hi \(snap.firstName)! Ready to\nhydrate?")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Spacer(minLength: 0)
                AquaRing(progress: snap.progress, size: 58, line: 6)
            }
            .padding(.bottom, 14)

            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    labeled("Goal", value: "\(snap.litersGoal) L", icon: "drop")
                    Rectangle().fill(.white.opacity(0.12)).frame(height: 0.5)
                    labeled("Drunk", value: "\(snap.litersDrunk) L", icon: "drop.fill")
                }
                Spacer(minLength: 8)
                Button(intent: LogGlassIntent()) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Aqua.limeOrb, in: Circle())
                        .overlay(Circle().stroke(.white.opacity(0.26)))
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.043)))
            .overlay(
                RoundedRectangle(cornerRadius: 16).stroke(
                    LinearGradient(colors: [.white.opacity(0.035), .white.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 0.7
                )
            )
            .padding(.bottom, 10)

            HStack(spacing: 8) {
                ForEach(0..<min(snap.glassesGoal, 8), id: \.self) { i in
                    Image(systemName: i < snap.glassesDrunk ? "drop.fill" : "drop")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(i < snap.glassesDrunk ? Aqua.mint : Aqua.mint.opacity(0.28))
                }
                Spacer(minLength: 0)
            }
            .padding(.bottom, 12)

            Button(intent: LogGlassIntent()) {
                Text("Log \(snap.glassML) ml")
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Aqua.glow, in: Capsule())
                    .overlay(
                        Capsule().stroke(
                            LinearGradient(colors: [Aqua.mint.opacity(0.08), Aqua.mint], startPoint: .top, endPoint: .bottom),
                            lineWidth: 0.8
                        )
                    )
            }
            .buttonStyle(.plain)
            .padding(.bottom, 10)

            if let ritual = snap.nextOpenRitual {
                Button(intent: CheckInRitualIntent()) {
                    HStack(spacing: 8) {
                        Image(systemName: ritual.symbol)
                            .font(.system(size: 13))
                            .foregroundStyle(Aqua.mint)
                        Text(ritual.name)
                            .font(.system(size: 13))
                            .foregroundStyle(.white)
                        Spacer()
                        Text("Check in")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Aqua.mint)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 40)
                    .background(RoundedRectangle(cornerRadius: 14).fill(.white.opacity(0.043)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.12), lineWidth: 0.6)
                    )
                }
                .buttonStyle(.plain)
            } else {
                Text(snap.isGoalMet ? "All caught up for today." : "\(snap.remainingLabel) · remind every \(snap.reminderHours)h")
                    .font(.system(size: 12))
                    .foregroundStyle(Aqua.muted)
            }
        }
        .padding(16)
        .widgetURL(URL(string: "aquapulse://home"))
    }

    private func labeled(_ title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 12)).foregroundStyle(Aqua.muted.opacity(0.8))
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 12))
                    .foregroundStyle(.white)
                Text(value).font(.system(size: 15)).foregroundStyle(.white)
            }
        }
    }
}

struct AquaLockCircle: View {
    var snap: AquaSnapshot

    var body: some View {
        ZStack {
            AquaRing(progress: snap.progress, size: 54, line: 5, track: .white.opacity(0.22), fill: .white, showDrop: false)
            VStack(spacing: 0) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 10, weight: .semibold))
                Text(snap.litersDrunk)
                    .font(.system(size: 12, weight: .medium))
                    .minimumScaleFactor(0.6)
            }
        }
        .widgetURL(URL(string: "aquapulse://log"))
    }
}

struct AquaLockRect: View {
    var snap: AquaSnapshot

    var body: some View {
        HStack(spacing: 10) {
            AquaRing(progress: snap.progress, size: 36, line: 4, track: .white.opacity(0.22), fill: .white)
            VStack(alignment: .leading, spacing: 1) {
                Text("AquaPulse")
                    .font(.system(size: 11, weight: .semibold))
                Text("\(snap.litersDrunk) L · \(snap.remainingLabel)")
                    .font(.system(size: 12))
            }
            Spacer(minLength: 0)
        }
        .widgetURL(URL(string: "aquapulse://log"))
    }
}

struct AquaRing: View {
    var progress: Double
    var size: CGFloat
    var line: CGFloat
    var track: Color = Aqua.mint.opacity(0.16)
    var fill: Color = Aqua.mint
    var showDrop = true

    var body: some View {
        ZStack {
            Circle().stroke(track, lineWidth: line)
            Circle()
                .trim(from: 0, to: max(progress, 0.02))
                .stroke(fill, style: StrokeStyle(lineWidth: line, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if showDrop {
                Image(systemName: "drop.fill")
                    .font(.system(size: size * 0.22, weight: .semibold))
                    .foregroundStyle(fill)
            }
        }
        .frame(width: size, height: size)
    }
}

private struct WidgetCTA: View {
    var title: String
    var symbol: String
    var glow: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 36)
        .background(glow ? AnyShapeStyle(Aqua.glow) : AnyShapeStyle(Color.white.opacity(0.06)), in: Capsule())
        .overlay {
            if glow {
                Capsule().stroke(
                    LinearGradient(colors: [Aqua.mint.opacity(0.08), Aqua.mint], startPoint: .top, endPoint: .bottom),
                    lineWidth: 0.7
                )
            } else {
                Capsule().stroke(Color.white.opacity(0.14), lineWidth: 0.7)
            }
        }
    }
}
