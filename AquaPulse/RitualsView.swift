import SwiftUI

struct RitualsView: View {
    @Environment(AquaStore.self) private var store
    @State private var path = NavigationPath()
    @State private var sorted = false
    @State private var showAdd = false
    @State private var query = ""

    private var filtered: [Ritual] {
        let base = sorted
            ? store.rituals.sorted { $0.streak > $1.streak }
            : store.rituals.sorted { ($0.isComplete ? 1 : 0) < ($1.isComplete ? 1 : 0) }
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return base }
        return base.filter { $0.name.localizedCaseInsensitiveContains(q) || $0.kind.localizedCaseInsensitiveContains(q) }
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if store.rituals.isEmpty {
                    empty
                } else {
                    List {
                        Section {
                            Text("\(store.rituals.count) Rituals\nactive")
                                .font(.system(size: 30, weight: .light))
                                .foregroundStyle(.white)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            Text(sorted ? "Sorted by longest streak" : "Due first. Swipe a non-water ritual to delete.")
                                .font(.system(size: 13))
                                .foregroundStyle(Aqua.muted)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                        ForEach(filtered) { ritual in
                            Button {
                                path.append(AquaRoute.glasses(ritual.id))
                            } label: {
                                ritualCard(ritual)
                            }
                            .buttonStyle(AquaPressStyle())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 18, bottom: 6, trailing: 18))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                if !ritual.isWater {
                                    Button("Delete", role: .destructive) {
                                        store.deleteRitual(ritual.id)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(AquaBackground())
            .aquaScreen()
            .searchable(text: $query, prompt: "Search rituals")
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

    private var empty: some View {
        VStack(spacing: 12) {
            Text("No rituals yet")
                .font(.system(size: 28, weight: .light))
            Text("Add a ritual with + to start a consistency streak.")
                .font(.system(size: 13))
                .foregroundStyle(Aqua.muted)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
