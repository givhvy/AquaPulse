import SwiftUI

struct WeekView: View {
    @Environment(AquaStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showNotice = false

    private var motion: Animation { reduceMotion ? .easeInOut(duration: 0.2) : AquaMotion.ui }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Consistency\nboard")
                        .font(.system(size: 30, weight: .light))
                        .padding(.bottom, 14)
                    HStack {
                        ForEach(Array(["M", "T", "W", "T", "F", "S", "S"].enumerated()), id: \.offset) { _, day in
                            Text(day)
                                .font(.system(size: 13, weight: .light))
                                .foregroundStyle(Aqua.muted)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.leading, 46)
                    .padding(.bottom, 12)
                    VStack(spacing: 12) {
                        ForEach(Array(store.rituals.enumerated()), id: \.element.id) { row, ritual in
                            HStack(spacing: 8) {
                                Image(systemName: ritual.symbol)
                                    .font(.system(size: 12))
                                    .frame(width: 38, height: 38)
                                    .background(Aqua.panel.opacity(0.7), in: Circle())
                                    .symbolEffect(.bounce, value: ritual.isComplete)
                                HStack(spacing: 6) {
                                    ForEach(0..<7, id: \.self) { day in
                                        let on = store.weekMarks[ritual.id.uuidString]?[day] ?? false
                                        Circle()
                                            .fill(on ? Aqua.tealFill : Color.white.opacity(0.03))
                                            .overlay(Circle().stroke(on ? Aqua.mint.opacity(0.7) : Aqua.muted.opacity(0.35), lineWidth: 0.6))
                                            .frame(width: 28, height: 28)
                                            .scaleEffect(on ? 1 : 0.88)
                                            .animation(motion.delay(Double(row) * 0.04 + Double(day) * 0.03), value: on)
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                            }
                            .padding(10)
                            .aquaCard()
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(AquaBackground())
            .aquaScreen()
            .navigationTitle("This week")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNotice = true } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
            .alert("You're all caught up", isPresented: $showNotice) {
                Button("Enable reminders") { store.requestReminders() }
                Button("Done", role: .cancel) {}
            } message: {
                Text(store.notificationsOn ? "Water and ritual pings are on." : "Turn on reminders to keep every consistency task alive.")
            }
        }
    }
}
