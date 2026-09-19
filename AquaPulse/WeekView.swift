import SwiftUI

struct WeekView: View {
    @Environment(AquaStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showRemind = false
    @State private var showNotice = false

    private var motion: Animation { reduceMotion ? .easeInOut(duration: 0.2) : AquaMotion.ui }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Consistency\nboard")
                        .font(.system(size: 30, weight: .light))
                        .padding(.bottom, 6)
                    Text("Dots fill only on days you complete a ritual. Nothing is backfilled.")
                        .font(.system(size: 13))
                        .foregroundStyle(Aqua.muted)
                        .padding(.bottom, 14)
                    if store.rituals.isEmpty {
                        Text("Add a ritual to see this week.")
                            .font(.system(size: 13))
                            .foregroundStyle(Aqua.muted)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .aquaCard()
                    } else {
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
                    Menu {
                        Button("Reminders") { showRemind = true }
                        Button("Notification status") { showNotice = true }
                        Link("Privacy Policy", destination: AquaLegal.privacy)
                        Link("Terms of Use", destination: AquaLegal.terms)
                        Link("Support", destination: AquaLegal.support)
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
            .sheet(isPresented: $showRemind) {
                VStack(spacing: 24) {
                    Text("When should we nudge you?").font(.title2)
                    Picker("Every", selection: Bindable(store).reminderHours) {
                        ForEach([1, 2, 3, 4], id: \.self) { Text("Every \($0)h").tag($0) }
                    }
                    .pickerStyle(.wheel)
                    .tint(Aqua.mint)
                    Button("Save reminders") {
                        store.requestReminders()
                        showRemind = false
                    }
                    .buttonStyle(GlowButton())
                }
                .padding(24)
                .presentationDetents([.medium])
            }
            .alert("Reminders", isPresented: $showNotice) {
                Button("Enable reminders") { store.requestReminders() }
                Button("Done", role: .cancel) {}
            } message: {
                Text(store.notificationsOn ? "Water and ritual pings are on." : "Turn on reminders to keep rituals on this phone. AquaPulse is not medical advice.")
            }
        }
    }
}
