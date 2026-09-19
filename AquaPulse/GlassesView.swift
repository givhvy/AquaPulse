import SwiftUI

struct GlassesView: View {
    @Environment(AquaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let ritualID: UUID

    @State private var filled = 0
    @State private var confirmed = false
    @State private var showNotice = false

    private var ritual: Ritual { store.ritual(id: ritualID) }
    private var isWater: Bool { ritual.isWater }
    private var goal: Int { isWater ? store.glassesGoal : max(ritual.timesPerDay, 1) }
    private var slots: Int { min(max(isWater ? 16 : max(goal, 4), 4), 16) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(isWater ? "Fill your\nglasses" : "Check in\ntoday")
                .font(.system(size: 30, weight: .light))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 14)
            HStack(spacing: 8) {
                legend("Done", filled: true)
                legend("Left", filled: false)
            }
            .padding(.bottom, 15)
            HStack(spacing: 10) {
                ForEach(["A", "B", "C", "D"], id: \.self) { column in
                    Text(column)
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(Aqua.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.trailing, column == "B" ? 12 : 0)
                }
            }
            .padding(.bottom, 13)

            VStack(spacing: 16) {
                ForEach(0..<4, id: \.self) { row in
                    HStack(spacing: 10) {
                        ForEach(0..<4, id: \.self) { col in
                            let index = row * 4 + col
                            let inPlan = index < slots
                            let available = inPlan && index < goal
                            Button {
                                guard inPlan else { return }
                                withAnimation(AquaMotion.bounce) {
                                    if index < filled {
                                        filled = index
                                    } else {
                                        filled = min(index + 1, goal)
                                    }
                                    apply()
                                }
                            } label: {
                                glassCell(index: index, available: available, inPlan: inPlan)
                            }
                            .buttonStyle(.plain)
                            .disabled(!inPlan)
                            .accessibilityLabel("Slot \(row + 1)\(["A", "B", "C", "D"][col]), \(index < filled ? "done" : "open")")
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: 90)
                            .padding(.trailing, col == 1 ? 12 : 0)
                        }
                    }
                }
            }
            Spacer(minLength: 8)
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AquaBackground())
        .aquaScreen()
        .navigationTitle(ritual.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear { filled = isWater ? store.glassesDrunk : ritual.doneToday }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showNotice = true } label: { Image(systemName: "ellipsis") }
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                VStack(alignment: .leading, spacing: 7) {
                    Text(isWater ? "\(store.litersDrunk) L" : "\(filled)/\(goal)")
                        .font(.system(size: 24))
                        .foregroundStyle(Aqua.mint)
                        .contentTransition(.numericText())
                        .animation(AquaMotion.snappy, value: filled)
                    Text(isWater ? "Daily  ·  \(store.glassML)ml  ·  \(filled) Glasses" : "\(ritual.name)  ·  \(filled) check-ins")
                        .font(.system(size: 13))
                }
                Spacer()
                Button("Continue") { confirmed = true }
                    .buttonStyle(GlowButton())
                    .frame(width: 113)
                    .disabled(filled == 0)
            }
            .padding(15)
            .background(
                RoundedRectangle(cornerRadius: 17)
                    .fill(.white.opacity(0.035))
                    .overlay(RoundedRectangle(cornerRadius: 17).stroke(.white.opacity(0.05)))
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 4)
        }
        .alert("Logged", isPresented: $confirmed) {
            Button("Back") { dismiss() }
        } message: {
            Text("\(ritual.doneToday) of \(ritual.timesPerDay) for \(ritual.name). Streak \(ritual.streak) days.")
        }
        .alert("You're all caught up", isPresented: $showNotice) {
            Button("Done", role: .cancel) {}
        } message: {
            Text("Keep filling glasses in order — first N cups count toward the goal.")
        }
    }

    private func apply() {
        if isWater {
            store.setGlasses(filled)
        } else {
            store.setDone(ritualID, count: filled)
        }
    }

    private func legend(_ title: String, filled: Bool) -> some View {
        HStack(spacing: 7) {
            Circle()
                .fill(filled ? Color(red: 0.02, green: 0.28, blue: 0.26) : Aqua.panel)
                .overlay(Circle().stroke(filled ? Aqua.mint.opacity(0.6) : Aqua.muted, lineWidth: 0.5))
                .frame(width: 14, height: 14)
            Text(title).font(.system(size: 13))
        }
        .padding(.horizontal, 14)
        .frame(height: 38)
        .overlay(Capsule().stroke(.white.opacity(0.10)))
    }

    private func glassCell(index: Int, available: Bool, inPlan: Bool) -> some View {
        let on = index < filled
        return CupShape()
            .fill(
                available
                    ? AnyShapeStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.035, green: 0.16, blue: 0.18),
                                on ? Color(red: 0.0, green: 0.60, blue: 0.54) : Color(red: 0.04, green: 0.34, blue: 0.32)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    : AnyShapeStyle(Color.white.opacity(0.015))
            )
            .overlay {
                if !available {
                    Hatch().stroke(Aqua.muted.opacity(0.32), lineWidth: 0.7).clipShape(CupShape())
                }
            }
            .overlay(
                CupShape().stroke(
                    LinearGradient(
                        colors: [available ? Aqua.mint.opacity(0.10) : Aqua.muted.opacity(0.10), available ? Aqua.mint : Aqua.muted],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: on ? 1.5 : 0.8
                )
            )
            .overlay {
                if on {
                    Image(systemName: "checkmark")
                        .font(.system(size: 21, weight: .light))
                        .foregroundStyle(Aqua.mint.opacity(0.75))
                        .transition(.scale.combined(with: .opacity))
                } else if available {
                    Image(systemName: "drop")
                        .font(.system(size: 11, weight: .light))
                        .foregroundStyle(Aqua.mint.opacity(0.45))
                }
            }
            .aspectRatio(0.8, contentMode: .fit)
            .scaleEffect(on ? 1.04 : 1)
            .shadow(color: on ? Aqua.mint.opacity(0.35) : .clear, radius: on ? 8 : 0)
            .opacity(inPlan ? 1 : 0.35)
            .animation(AquaMotion.bounce, value: on)
    }
}
