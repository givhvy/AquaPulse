import SwiftUI

struct HomeView: View {
    @Environment(AquaStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var tab: MainTab
    @Namespace private var pills
    @State private var path = NavigationPath()
    @State private var mode = "Daily"
    @State private var swapped = false
    @State private var showNotice = false
    @State private var showRemind = false
    @State private var appeared = false

    private var motion: Animation { reduceMotion ? .easeInOut(duration: 0.2) : AquaMotion.ui }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    Text(headline)
                        .font(.system(size: 30, weight: .light))
                        .lineSpacing(0)
                        .padding(.bottom, 21)

                    modeChips
                        .padding(.bottom, 14)

                    goalCard
                        .padding(.bottom, 11)

                    controls
                        .padding(.bottom, 12)

                    Button(ctaTitle) {
                        if mode == "Rituals" { tab = .rituals }
                        else if mode == "Streaks" { tab = .week }
                        else {
                            path.append(AquaRoute.glasses(store.waterRitual?.id ?? Ritual.empty.id))
                        }
                    }
                    .buttonStyle(GlowButton())
                    .padding(.bottom, 23)

                    Text("Longest streak").font(.system(size: 15)).padding(.bottom, 13)
                    Button {
                        path.append(AquaRoute.glasses(store.bestStreak.id))
                    } label: {
                        JourneyRow(
                            leftTime: "07:00 AM",
                            leftCode: "0 ml",
                            leftCity: "START",
                            rightTime: "09:00 PM",
                            rightCode: "\(store.litersGoal) L",
                            rightCity: store.bestStreak.name.uppercased(),
                            duration: "\(store.bestStreak.streak) day streak",
                            animated: true,
                            reduceMotion: reduceMotion
                        )
                        .padding(14)
                        .frame(height: 95)
                        .featuredCard()
                    }
                    .buttonStyle(AquaPressStyle())
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(AquaBackground())
            .aquaScreen()
            .navigationBarHidden(true)
            .navigationDestination(for: AquaRoute.self) { route in
                if case .glasses(let id) = route {
                    GlassesView(ritualID: id)
                }
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            .onAppear {
                withAnimation(reduceMotion ? .easeOut(duration: 0.25) : AquaMotion.bounce) {
                    appeared = true
                }
                let args = ProcessInfo.processInfo.arguments
                if let i = args.firstIndex(of: "-screen"),
                   args.indices.contains(i + 1),
                   args[i + 1] == "glasses",
                   path.isEmpty {
                    path.append(AquaRoute.glasses(store.waterRitual?.id ?? Ritual.empty.id))
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
            .alert("You're all caught up", isPresented: $showNotice) {
                Button("Enable reminders") { store.requestReminders() }
                Button("Done", role: .cancel) {}
            } message: {
                Text(store.notificationsOn ? "Water and ritual pings are on." : "Turn on reminders to keep every consistency task alive.")
            }
        }
    }

    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                ZStack {
                    Circle().fill(Aqua.avatar)
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Aqua.avatarIcon)
                }
                .frame(width: 30, height: 30)
                Text(store.name).font(.system(size: 13))
            }
            .padding(6)
            .padding(.trailing, 8)
            .background(Aqua.panel.opacity(0.65), in: Capsule())
            Spacer()
            if #available(iOS 26, *) {
                GlassEffectContainer(spacing: 8) {
                    HStack(spacing: 8) {
                        CircleIconButton(symbol: "magnifyingglass") { tab = .rituals }
                        CircleIconButton(symbol: "bell") { showNotice = true }
                    }
                }
            } else {
                HStack(spacing: 8) {
                    CircleIconButton(symbol: "magnifyingglass") { tab = .rituals }
                    CircleIconButton(symbol: "bell") { showNotice = true }
                }
            }
        }
        .padding(.bottom, 18)
    }

    private var modeChips: some View {
        HStack(spacing: 8) {
            ForEach(["Daily", "Rituals", "Streaks"], id: \.self) { item in
                Button {
                    withAnimation(motion) { mode = item }
                } label: {
                    Text(item)
                        .font(.system(size: 13))
                        .foregroundStyle(mode == item ? Color.black : .white)
                        .padding(.horizontal, 15)
                        .frame(height: 38)
                        .background {
                            if mode == item {
                                Capsule()
                                    .fill(Color.white)
                                    .matchedGeometryEffect(id: "modePill", in: pills)
                            }
                        }
                        .overlay(Capsule().stroke(.white.opacity(mode == item ? 0 : 0.1)))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var goalCard: some View {
        ZStack(alignment: .trailing) {
            VStack(alignment: .leading, spacing: 0) {
                routeField(topTitle, name: swapped ? bottomValue : topValue, icon: swapped ? "drop.fill" : topIcon, numeric: mode == "Daily")
                Rectangle().fill(.white.opacity(0.12)).frame(height: 0.5).padding(.vertical, 11)
                routeField(bottomTitle, name: swapped ? topValue : bottomValue, icon: swapped ? topIcon : "drop.fill", numeric: mode == "Daily")
            }
            .padding(14)
            Button {
                if mode == "Daily" {
                    withAnimation(AquaMotion.bounce) { store.logGlass() }
                } else {
                    withAnimation(AquaMotion.snappy) { swapped.toggle() }
                }
            } label: {
                Image(systemName: mode == "Daily" ? "plus" : "arrow.up.arrow.down")
                    .font(.system(size: 13))
                    .frame(width: 44, height: 44)
                    .background(
                        LinearGradient(colors: [Color.clear, Color(red: 0.58, green: 0.64, blue: 0.03)], startPoint: .top, endPoint: .bottom),
                        in: Circle()
                    )
                    .overlay(Circle().stroke(.white.opacity(0.26)))
                    .rotationEffect(.degrees(swapped && mode != "Daily" ? 180 : 0))
                    .symbolEffect(.bounce, value: store.drunkML)
            }
            .buttonStyle(AquaPressStyle())
            .padding(.trailing, 15)
        }
        .frame(height: 128)
        .aquaCard()
    }

    private var controls: some View {
        HStack(spacing: 8) {
            Menu {
                ForEach([150, 250, 330, 500], id: \.self) { size in
                    Button("\(size) ml glass") {
                        withAnimation(motion) { store.setGlassSize(size) }
                    }
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Glass").foregroundStyle(Aqua.muted).font(.system(size: 13))
                        HStack(spacing: 7) {
                            Image(systemName: "cup.and.saucer")
                            Text("\(store.glassML)")
                                .foregroundStyle(Aqua.muted)
                                .contentTransition(.numericText())
                            Text("ml").foregroundStyle(Aqua.muted)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down").font(.system(size: 9)).foregroundStyle(Aqua.muted)
                }
                .padding(14)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .aquaCard()
            }
            Button { showRemind = true } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Remind").font(.system(size: 13))
                        Text("Every \(store.reminderHours)h").font(.system(size: 15))
                    }
                    Spacer()
                    Image(systemName: "bell").font(.system(size: 12))
                }
                .foregroundStyle(Aqua.muted)
                .padding(14)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .aquaCard()
            }
            .buttonStyle(AquaPressStyle())
        }
    }

    private var headline: String {
        switch mode {
        case "Rituals": return "Hi Maya! Keep the\nstreak alive?"
        case "Streaks": return "Hi Maya! Look at\nyour run!"
        default: return "Hi Maya! Ready to\nhydrate?"
        }
    }

    private var topTitle: String { mode == "Rituals" ? "Active" : mode == "Streaks" ? "Best" : "Goal" }
    private var bottomTitle: String { mode == "Rituals" ? "Done" : mode == "Streaks" ? "Current" : "Drunk" }
    private var topIcon: String { mode == "Rituals" ? "flame" : mode == "Streaks" ? "trophy" : "drop" }
    private var topValue: String {
        switch mode {
        case "Rituals": return "\(store.rituals.count) rituals"
        case "Streaks": return "\(store.bestStreak.streak) days"
        default: return "\(store.litersGoal) L"
        }
    }
    private var bottomValue: String {
        switch mode {
        case "Rituals": return "\(store.doneCount) complete"
        case "Streaks": return "\(store.waterRitual?.streak ?? 0) water"
        default: return "\(store.litersDrunk) L"
        }
    }
    private var ctaTitle: String {
        switch mode {
        case "Rituals": return "Open rituals"
        case "Streaks": return "See the board"
        default: return "Log \(store.glassML) ml"
        }
    }

    private func routeField(_ title: String, name: String, icon: String, numeric: Bool) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.system(size: 13)).foregroundStyle(Aqua.muted.opacity(0.8))
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 13))
                Text(name)
                    .font(.system(size: 15))
                    .contentTransition(numeric ? .numericText() : .opacity)
                    .animation(motion, value: name)
            }
        }
    }
}
