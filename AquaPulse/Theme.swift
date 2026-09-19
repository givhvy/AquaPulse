import SwiftUI

enum Aqua {
    static let mint = Color(red: 0.48, green: 0.94, blue: 0.85)
    static let muted = Color(red: 0.51, green: 0.59, blue: 0.63)
    static let panel = Color(red: 0.075, green: 0.13, blue: 0.17)
    static let bgTop = Color(red: 0.012, green: 0.06, blue: 0.095)
    static let bgMid = Color(red: 0.018, green: 0.075, blue: 0.11)
    static let bgBottom = Color(red: 0.09, green: 0.25, blue: 0.27)
    static let lime = Color(red: 0.65, green: 0.68, blue: 0.02)
    static let tealFill = Color(red: 0.02, green: 0.32, blue: 0.3)
    static let avatar = Color(red: 0.29, green: 0.19, blue: 0.13)
    static let avatarIcon = Color(red: 0.64, green: 0.44, blue: 0.3)
}

enum AquaMotion {
    static let ui = Animation.spring(response: 0.38, dampingFraction: 0.9)
    static let snappy = Animation.spring(response: 0.28, dampingFraction: 0.82)
    static let bounce = Animation.spring(response: 0.44, dampingFraction: 0.68)
    static let press = Animation.spring(response: 0.22, dampingFraction: 0.72)
}

enum MainTab: Hashable {
    case home, rituals, week
}

enum AquaRoute: Hashable {
    case glasses(UUID)
}

struct GlowButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 47)
            .background(
                LinearGradient(
                    stops: [
                        .init(color: Color(red: 0.015, green: 0.23, blue: 0.23), location: 0),
                        .init(color: Color(red: 0.025, green: 0.17, blue: 0.19), location: 0.4),
                        .init(color: Color(red: 0.02, green: 0.41, blue: 0.38), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                in: Capsule()
            )
            .overlay(
                Capsule().stroke(
                    LinearGradient(colors: [Aqua.mint.opacity(0.08), Aqua.mint], startPoint: .top, endPoint: .bottom),
                    lineWidth: 0.8
                )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(AquaMotion.press, value: configuration.isPressed)
    }
}

struct AquaPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(AquaMotion.press, value: configuration.isPressed)
    }
}

extension View {
    func aquaCard() -> some View {
        background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.043)))
            .overlay(
                RoundedRectangle(cornerRadius: 16).stroke(
                    LinearGradient(colors: [.white.opacity(0.035), .white.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 0.7
                )
            )
    }

    func featuredCard() -> some View {
        background(
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.09, green: 0.23, blue: 0.24), location: 0),
                    .init(color: Color(red: 0.25, green: 0.37, blue: 0.15), location: 0.45),
                    .init(color: Color(red: 0.65, green: 0.68, blue: 0.02), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            ),
            in: RoundedRectangle(cornerRadius: 17)
        )
        .overlay(RoundedRectangle(cornerRadius: 17).stroke(.white.opacity(0.27), lineWidth: 0.7))
    }

    @ViewBuilder
    func aquaTabMinimize() -> some View {
        if #available(iOS 26, *) {
            tabBarMinimizeBehavior(.onScrollDown)
        } else {
            self
        }
    }

    func aquaScreen() -> some View {
        font(.system(size: 14, weight: .regular))
            .foregroundStyle(.white)
            .toolbarBackground(.hidden, for: .navigationBar)
    }
}

struct CircleIconButton: View {
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if #available(iOS 26, *) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .light))
                    .frame(width: 44, height: 44)
                    .glassEffect(.regular.interactive(), in: .circle)
            } else {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .light))
                    .frame(width: 44, height: 44)
                    .background(Aqua.panel.opacity(0.5), in: Circle())
                    .overlay(
                        Circle().stroke(
                            LinearGradient(colors: [.white.opacity(0.015), .white.opacity(0.18)], startPoint: .top, endPoint: .bottom),
                            lineWidth: 0.6
                        )
                    )
            }
        }
        .buttonStyle(AquaPressStyle())
    }
}

struct OrbitingDrop: View {
    var reduceMotion = false

    var body: some View {
        if reduceMotion {
            staticDrop
        } else {
            TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
                let t = (sin(timeline.date.timeIntervalSinceReferenceDate * 1.35) + 1) / 2
                drop
                    .offset(x: (t - 0.5) * 54, y: -sin(t * .pi) * 11)
                    .shadow(color: Aqua.mint.opacity(0.35), radius: 6)
            }
        }
    }

    private var staticDrop: some View { drop }

    private var drop: some View {
        Image(systemName: "drop.fill")
            .font(.system(size: 10))
            .foregroundStyle(Aqua.mint)
            .frame(width: 22, height: 22)
            .background(Aqua.tealFill, in: Circle())
            .overlay(Circle().stroke(Aqua.mint.opacity(0.24)))
    }
}

struct SipArc: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.midX, y: -rect.height * 0.35))
        return p
    }
}

struct CupShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 8, y: 0))
        p.addLine(to: CGPoint(x: rect.maxX - 8, y: 0))
        p.addLine(to: CGPoint(x: rect.maxX - 2, y: rect.maxY - 8))
        p.addQuadCurve(to: CGPoint(x: rect.maxX - 8, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: 8, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: 2, y: rect.maxY - 8), control: CGPoint(x: 0, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

struct Hatch: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        for y in stride(from: -rect.width, through: rect.height + rect.width, by: 4.0) {
            p.move(to: CGPoint(x: 0, y: y))
            p.addLine(to: CGPoint(x: rect.width, y: y + 18))
        }
        return p
    }
}

func aquaAccent(_ name: String) -> Color {
    switch name {
    case "red": return .red
    case "blue": return .blue
    case "orange": return .orange
    case "purple": return .purple
    default: return Color(red: 0.0, green: 0.55, blue: 0.5)
    }
}

struct JourneyRow: View {
    let leftTime: String
    let leftCode: String
    let leftCity: String
    let rightTime: String
    let rightCode: String
    let rightCity: String
    let duration: String
    var animated: Bool = false
    var reduceMotion: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            VStack(alignment: .leading, spacing: 4) {
                Text(leftTime).font(.system(size: 11)).foregroundStyle(Aqua.muted)
                Text(leftCode).font(.system(size: 22, weight: .light))
                Text(leftCity).font(.system(size: 11)).foregroundStyle(Aqua.muted)
            }
            Spacer(minLength: 0)
            VStack(spacing: 1) {
                ZStack {
                    SipArc()
                        .stroke(Aqua.muted.opacity(0.85), style: StrokeStyle(lineWidth: 0.8, dash: [1, 3]))
                        .frame(height: 26)
                        .offset(y: 9)
                    if animated && !reduceMotion {
                        OrbitingDrop()
                    } else {
                        OrbitingDrop(reduceMotion: true)
                    }
                }
                .frame(height: 34)
                Text(duration).font(.system(size: 8)).foregroundStyle(Aqua.muted)
            }
            .frame(maxWidth: 140)
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 4) {
                Text(rightTime).font(.system(size: 11)).foregroundStyle(Aqua.muted)
                Text(rightCode).font(.system(size: 22, weight: .light))
                Text(rightCity).lineLimit(1).font(.system(size: 11)).foregroundStyle(Aqua.muted)
            }
        }
    }
}

struct AquaBackground: View {
    var body: some View {
        LinearGradient(colors: [Aqua.bgTop, Aqua.bgMid, Aqua.bgBottom], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
}
