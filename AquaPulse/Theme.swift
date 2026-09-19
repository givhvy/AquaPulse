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
            .opacity(configuration.isPressed ? 0.7 : 1)
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
}

struct CircleIconButton: View {
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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
        .buttonStyle(.plain)
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

struct GlassShape: Shape {
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
