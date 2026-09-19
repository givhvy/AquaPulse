import SwiftUI

struct RitualsView: View {
    @Environment(AquaStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var path = NavigationPath()
    @State private var sorted = false
    @State private var showAdd = false

    private var motion: Animation { reduceMotion ? .easeInOut(duration: 0.2) : AquaMotion.ui }

    private var sortedRituals: [Ritual] {
        sorted
            ? store.rituals.sorted { $0.streak > $1.streak }
            : store.rituals.sorted { ($0.isComplete ? 1 : 0) < ($1.isComplete ? 1 : 0) }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(store.rituals.count) Rituals\nactive")
                        .font(.system(size: 30, weight: .light))
                        .padding(.bottom, 6)
                    Text(sorted ? "Sorted by longest streak" : "Due first")
                        .font(.system(size: 13))
                        .foregroundStyle(Aqua.muted)
                        .padding(.bottom, 14)

                    VStack(spacing: 15) {
                        ForEach(Array(sortedRituals.enumerated()), id: \.element.id) { index, ritual in
                            Button {
                                path.append(AquaRoute.glasses(ritual.id))
                            } label: {
                                ritualCard(ritual)
                            }
                            .buttonStyle(AquaPressStyle())
                            .transition(.opacity)
                            .animation(motion.delay(Double(index) * 0.05), value: sorted)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(AquaBackground())
            .aquaScreen()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text(Date().formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).year()))
                            .font(.system(size: 9))
                            .foregroundStyle(Aqua.muted)
                        Text("TODAY → GOAL").font(.system(size: 13))
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation(AquaMotion.snappy) { sorted.toggle() }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                    .accessibilityLabel(sorted ? "Sort by longest streak" : "Sort due first")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(for: AquaRoute.self) { route in
                if case .glasses(let id) = route {
                    GlassesView(ritualID: id)
                }
            }
            .sheet(isPresented: $showAdd) {
                AddRitualSheet()
                    .environment(store)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private func ritualCard(_ ritual: Ritual) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Ritual")
                Spacer()
                Text("Type")
            }
            .font(.system(size: 13))
            .foregroundStyle(Aqua.muted.opacity(0.8))
            .padding(.bottom, 8)
            HStack(spacing: 8) {
                Text(ritual.logo)
                    .font(.system(size: 6, weight: .bold))
                    .italic()
                    .frame(width: 22, height: 22)
                    .background(aquaAccent(ritual.accent).opacity(0.7), in: Circle())
                Text(ritual.name).font(.system(size: 13))
                Spacer()
                Text(ritual.timesPerDay == 1 ? "Daily" : "\(ritual.timesPerDay)x")
                    .font(.system(size: 13))
            }
            .padding(.bottom, 11)
            JourneyRow(
                leftTime: String(format: "%02d:00", ritual.remindHour),
                leftCode: "\(ritual.doneToday)",
                leftCity: "DONE",
                rightTime: "GOAL",
                rightCode: "\(ritual.timesPerDay)",
                rightCity: ritual.isComplete ? "COMPLETE" : "REMAINING",
                duration: ritual.isComplete ? "Checked in" : "\(ritual.remaining) left"
            )
            Rectangle().fill(.white.opacity(0.08)).frame(height: 0.5).padding(.vertical, 11)
            HStack {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Cadence").foregroundStyle(Aqua.muted.opacity(0.8))
                    Text(ritual.isWater ? "Hydration" : "Consistency")
                }
                .font(.system(size: 13))
                Spacer()
                Text("\(ritual.streak)d")
                    .font(.system(size: 22))
                    .foregroundStyle(Aqua.mint)
            }
        }
        .padding(15)
        .frame(minHeight: 210)
        .aquaCard()
    }
}
