import SwiftUI

struct AddRitualSheet: View {
    @Environment(AquaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var times = 1
    @State private var hour = 9
    @State private var symbol = "star.fill"
    private let symbols = ["star.fill", "heart.fill", "leaf.fill", "dumbbell.fill", "brain.head.profile", "fork.knife", "music.note", "paintbrush.fill", "play.rectangle.fill"]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("New ritual").font(.title2)
            let unused = Ritual.extraTemplates.filter { template in
                !store.rituals.contains { $0.id == template.id }
            }
            if !unused.isEmpty {
                Text("Templates").font(.system(size: 13)).foregroundStyle(Aqua.muted)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(unused) { ritual in
                            Button(ritual.name) {
                                store.addCatalogRitual(ritual)
                                dismiss()
                            }
                            .font(.system(size: 13))
                            .padding(.horizontal, 12)
                            .frame(height: 34)
                            .background(Aqua.panel, in: Capsule())
                            .overlay(Capsule().stroke(.white.opacity(0.12)))
                        }
                    }
                }
            }
            TextField("Name", text: $name)
                .textFieldStyle(.plain)
                .padding(14)
                .aquaCard()
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(symbols, id: \.self) { item in
                    Button {
                        withAnimation(AquaMotion.snappy) { symbol = item }
                    } label: {
                        Image(systemName: item)
                            .font(.system(size: 13))
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(symbol == item ? Aqua.mint.opacity(0.25) : Aqua.panel.opacity(0.7), in: Circle())
                            .overlay(Circle().stroke(symbol == item ? Aqua.mint : .white.opacity(0.1)))
                            .scaleEffect(symbol == item ? 1.08 : 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            HStack {
                Stepper("\(times)× a day", value: $times, in: 1...12)
                Spacer()
                Stepper("\(hour):00", value: $hour, in: 5...23)
            }
            .font(.system(size: 15))
            Button("Add ritual") {
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                store.addRitual(name: trimmed, symbol: symbol, times: times, hour: hour)
                dismiss()
            }
            .buttonStyle(GlowButton())
            Spacer()
        }
        .padding(24)
        .foregroundStyle(.white)
        .background(Aqua.bgTop.ignoresSafeArea())
    }
}
