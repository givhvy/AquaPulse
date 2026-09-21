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

    static var night: LinearGradient {
        LinearGradient(colors: [bgTop, bgMid, bgBottom], startPoint: .top, endPoint: .bottom)
    }

    static var glow: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(red: 0.015, green: 0.23, blue: 0.23), location: 0),
                .init(color: Color(red: 0.025, green: 0.17, blue: 0.19), location: 0.4),
                .init(color: Color(red: 0.02, green: 0.41, blue: 0.38), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var limeOrb: LinearGradient {
        LinearGradient(colors: [Color.clear, lime], startPoint: .top, endPoint: .bottom)
    }
}
