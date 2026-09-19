import SwiftUI

@main
struct AquaPulseApp: App {
    @State private var store = AquaStore()

    var body: some Scene {
        WindowGroup {
            AquaRoot()
                .environment(store)
                .preferredColorScheme(.dark)
        }
    }
}

struct AquaRoot: View {
    @Environment(AquaStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var pills
    @Namespace private var tabGlass
    @State private var screen: String = {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-screen"), args.indices.contains(i + 1) { return args[i + 1] }
        return "home"
    }()
    @State private var mode = "Daily"
    @State private var tab = 0
    @State private var sorted = false
    @State private var showNotice = false
    @State private var showRemind = false
    @State private var confirmed = false
    @State private var showAdd = false
    @State private var activeRitual: Ritual?
    @State private var selected: Set<Int> = []
    @State private var swapped = false
    @State private var reverse = false
    @State private var appeared = false

    private var motion: Animation { reduceMotion ? .easeInOut(duration: 0.2) : AquaMotion.ui }
    private var showsTabBar: Bool { screen == "home" || screen == "rituals" || screen == "week" }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Aqua.bgTop, Aqua.bgMid, Aqua.bgBottom], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            Group {
                if screen == "rituals" { rituals }
                else if screen == "week" { week }
                else if screen == "glasses" { glasses }
                else { home }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .id(screen)
            .transition(screenTransition)
            .animation(motion, value: screen)
        }
        .safeAreaInset(edge: .bottom, spacing: 8) {
            if showsTabBar {
                AquaGlassTabBar(tab: tab, namespace: tabGlass, motion: motion) { index in
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if index == 0 { go("home", back: screen != "home") }
                    if index == 1 { go("rituals", back: screen == "week") }
                    if index == 2 { go("week") }
                }
                .padding(.horizontal, 22)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .font(.system(size: 14, weight: .regular))
        .foregroundStyle(.white)
        .onAppear {
            if selected.isEmpty { selected = Set(0..<store.glassesDrunk) }
            withAnimation(reduceMotion ? .easeOut(duration: 0.25) : AquaMotion.bounce) {
                appeared = true
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
        .sheet(isPresented: $showAdd) {
            AddRitualSheet()
                .environment(store)
                .presentationDetents([.medium, .large])
        }
        .alert("You're all caught up", isPresented: $showNotice) {
            Button("Enable reminders") { store.requestReminders() }
            Button("Done", role: .cancel) {}
        } message: {
            Text(store.notificationsOn ? "Water and ritual pings are on." : "Turn on reminders to keep every consistency task alive.")
        }
        .alert("Logged", isPresented: $confirmed) {
            Button("Back to home") { go("home", back: true) }
        } message: {
            if let ritual = activeRitual {
                Text("\(ritual.doneToday) of \(ritual.timesPerDay) for \(ritual.name). Streak \(ritual.streak) days.")
            } else {
                Text("\(store.glassesDrunk) glasses toward \(store.litersGoal) L today.")
            }
        }
    }

    private var screenTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: reverse ? .leading : .trailing).combined(with: .opacity),
            removal: .move(edge: reverse ? .trailing : .leading).combined(with: .opacity)
        )
    }

    private func go(_ next: String, back: Bool = false) {
        reverse = back || next == "home"
        withAnimation(motion) {
            screen = next
            if next == "home" { tab = 0 }
            if next == "rituals" { tab = 1 }
            if next == "week" { tab = 2 }
        }
    }

    private var home: some View {
        ScrollView(showsIndicators: false) {
        VStack(alignment: .leading, spacing: 0) {
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
                CircleIconButton(symbol: "magnifyingglass") { go("rituals") }
                CircleIconButton(symbol: "bell") { showNotice = true }
            }
            .padding(.bottom, 18)

            Text(headline)
                .font(.system(size: 30, weight: .light))
                .lineSpacing(0)
                .id(mode)
                .contentTransition(.opacity)
                .padding(.bottom, 21)

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
            .padding(.bottom, 14)

            ZStack(alignment: .trailing) {
                VStack(alignment: .leading, spacing: 0) {
                    routeField(topTitle, name: swapped ? bottomValue : topValue, icon: swapped ? "drop.fill" : topIcon)
                    Rectangle().fill(.white.opacity(0.12)).frame(height: 0.5).padding(.vertical, 11)
                    routeField(bottomTitle, name: swapped ? topValue : bottomValue, icon: swapped ? topIcon : "drop.fill")
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
            .padding(.bottom, 11)

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
                                Text("\(store.glassML) ml").foregroundStyle(Aqua.muted)
                                    .contentTransition(.numericText())
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
            .padding(.bottom, 12)

            Button(ctaTitle) {
                if mode == "Rituals" { go("rituals") }
                else if mode == "Streaks" { go("week") }
                else {
                    selected = Set(0..<store.glassesDrunk)
                    go("glasses")
                }
            }
            .buttonStyle(GlowButton())
            .padding(.bottom, 23)

            Text("Longest streak").font(.system(size: 15)).padding(.bottom, 13)
            Button {
                activeRitual = store.bestStreak
                selected = Set(0..<min(store.bestStreak.doneToday, 16))
                go("glasses")
            } label: {
                journey(
                    leftTime: "07:00 AM",
                    leftCode: "0 ml",
                    leftCity: "START",
                    rightTime: "09:00 PM",
                    rightCode: "\(store.litersGoal) L",
                    rightCity: store.bestStreak.name.uppercased(),
                    duration: "\(store.bestStreak.streak) day streak",
                    animated: true
                )
                .padding(14)
                .frame(height: 95)
                .featuredCard()
            }
            .buttonStyle(AquaPressStyle())
        }
        .padding(.horizontal, 15)
        .padding(.top, 10)
        .padding(.bottom, 20)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
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

    private func routeField(_ title: String, name: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.system(size: 13)).foregroundStyle(Aqua.muted.opacity(0.8))
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 13)).symbolEffect(.bounce, value: name)
                Text(name)
                    .font(.system(size: 15))
                    .contentTransition(.numericText())
                    .animation(motion, value: name)
            }
        }
    }

    private var rituals: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                CircleIconButton(symbol: "arrow.left") { go("home", back: true) }
                Spacer()
                VStack(spacing: 4) {
                    Text(Date().formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).year()))
                        .font(.system(size: 7))
                        .foregroundStyle(Aqua.muted)
                    Text("TODAY → GOAL")
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 16)
                .frame(height: 43)
                .background(Aqua.panel.opacity(0.65), in: RoundedRectangle(cornerRadius: 16))
                Spacer()
                CircleIconButton(symbol: "plus") { showAdd = true }
            }
            .padding(.bottom, 24)

            Text("\(store.rituals.count) Rituals\nactive")
                .font(.system(size: 30, weight: .light))
                .padding(.bottom, 14)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 15) {
                    ForEach(Array(sortedRituals.enumerated()), id: \.element.id) { index, ritual in
                        ritualCard(ritual)
                            .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
                            .animation(motion.delay(Double(index) * 0.05), value: sorted)
                    }
                }
                .padding(.bottom, 72)
            }
        }
        .padding(.horizontal, 15)
        .padding(.top, 10)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack(spacing: 8) {
                Button {
                    withAnimation(AquaMotion.snappy) { sorted.toggle() }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.up.arrow.down").font(.system(size: 12))
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Sort").font(.system(size: 10)).foregroundStyle(Aqua.muted)
                            Text(sorted ? "Longest streak" : "Due first").font(.system(size: 15))
                        }
                    }
                    .padding(.horizontal, 15)
                    .frame(height: 45)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.09)))
                }
                .buttonStyle(AquaPressStyle())
                Button { showAdd = true } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                        .frame(width: 45, height: 45)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.09)))
                }
                .buttonStyle(AquaPressStyle())
            }
            .padding(.bottom, 8)
        }
    }

    private var sortedRituals: [Ritual] {
        sorted
            ? store.rituals.sorted { $0.streak > $1.streak }
            : store.rituals.sorted { ($0.isComplete ? 1 : 0) < ($1.isComplete ? 1 : 0) }
    }

    private func ritualCard(_ ritual: Ritual) -> some View {
        Button {
            activeRitual = ritual
            selected = Set(0..<min(ritual.doneToday, 16))
            go("glasses")
        } label: {
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
                journey(
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
            .frame(height: 210)
            .aquaCard()
        }
        .buttonStyle(AquaPressStyle())
    }

    private var week: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                CircleIconButton(symbol: "arrow.left") { go("home", back: true) }
                Spacer()
                Text("This week").font(.system(size: 15))
                Spacer()
                CircleIconButton(symbol: "ellipsis") { showNotice = true }
            }
            .padding(.bottom, 24)
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
            ScrollView(showsIndicators: false) {
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
                .padding(.bottom, 24)
            }
        }
        .padding(.horizontal, 15)
        .padding(.top, 10)
    }

    private var glasses: some View {
        let ritual = activeRitual ?? store.waterRitual ?? store.rituals[0]
        let isWater = ritual.isWater
        let slots = min(max(isWater ? 16 : max(ritual.timesPerDay, 4), 4), 16)
        let goal = isWater ? store.glassesGoal : ritual.timesPerDay
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                CircleIconButton(symbol: "arrow.left") { go("rituals", back: true) }
                Spacer()
                Text(ritual.name).font(.system(size: 15))
                Spacer()
                CircleIconButton(symbol: "ellipsis") { showNotice = true }
            }
            .padding(.bottom, 24)
            Text(isWater ? "Fill your\nglasses" : "Check in\ntoday")
                .font(.system(size: 30, weight: .light))
                .padding(.bottom, 14)
            HStack(spacing: 8) {
                legend("Done", filled: true)
                legend("Left", filled: false)
            }
            .padding(.bottom, 15)
            HStack(spacing: 0) {
                ForEach(["A", "B", "C", "D"], id: \.self) { column in
                    Text(column)
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(Aqua.muted)
                        .frame(width: 54)
                    if column != "D" { Spacer().frame(width: column == "B" ? 46 : 22) }
                }
            }
            .padding(.horizontal, 7)
            .padding(.bottom, 13)
            VStack(spacing: 16) {
                ForEach(0..<4, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<4, id: \.self) { col in
                            let index = row * 4 + col
                            let inPlan = index < slots
                            let available = inPlan && index < goal
                            Button {
                                guard inPlan else { return }
                                if available || selected.count >= goal {
                                    withAnimation(AquaMotion.bounce) {
                                        if selected.contains(index) {
                                            selected.remove(index)
                                        } else {
                                            selected.insert(index)
                                        }
                                        if isWater {
                                            store.setGlasses(selected.count)
                                        } else {
                                            store.setDone(ritual.id, count: selected.count)
                                            activeRitual = store.rituals.first { $0.id == ritual.id }
                                        }
                                    }
                                }
                            } label: {
                                glassCell(index: index, available: available, inPlan: inPlan)
                            }
                            .buttonStyle(.plain)
                            .disabled(!inPlan)
                            .accessibilityLabel("Slot \(row + 1)\(["A", "B", "C", "D"][col]), \(available ? (selected.contains(index) ? "done" : "open") : "bonus")")
                            if col < 3 { Spacer().frame(width: col == 1 ? 46 : 22) }
                        }
                    }
                }
            }
            .padding(.horizontal, 7)
            Spacer(minLength: 10)
        }
        .padding(.horizontal, 15)
        .padding(.top, 10)
        .safeAreaInset(edge: .bottom) {
            HStack {
                VStack(alignment: .leading, spacing: 7) {
                    Text(isWater ? "\(store.litersDrunk) L" : "\(selected.count)/\(goal)")
                        .font(.system(size: 24))
                        .foregroundStyle(Aqua.mint)
                        .contentTransition(.numericText())
                        .animation(AquaMotion.snappy, value: selected.count)
                    Text(isWater ? "Daily  ·  \(store.glassML)ml  ·  \(selected.count) Glasses" : "\(ritual.name)  ·  \(selected.count) check-ins")
                        .font(.system(size: 13))
                }
                Spacer()
                Button("Continue") { confirmed = true }
                    .buttonStyle(GlowButton())
                    .frame(width: 113)
                    .disabled(selected.isEmpty)
            }
            .padding(15)
            .background(
                RoundedRectangle(cornerRadius: 17)
                    .fill(.white.opacity(0.035))
                    .overlay(RoundedRectangle(cornerRadius: 17).stroke(.white.opacity(0.05)))
            )
            .padding(.bottom, 4)
        }
    }

    private func glassCell(index: Int, available: Bool, inPlan: Bool) -> some View {
        let on = selected.contains(index)
        return GlassShape()
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
                    Hatch().stroke(Aqua.muted.opacity(0.32), lineWidth: 0.7).clipShape(GlassShape())
                }
            }
            .overlay(
                GlassShape().stroke(
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
                        .symbolEffect(.bounce, value: on)
                        .transition(.scale.combined(with: .opacity))
                } else if available {
                    Image(systemName: "drop")
                        .font(.system(size: 11, weight: .light))
                        .foregroundStyle(Aqua.mint.opacity(0.45))
                        .transition(.opacity)
                }
            }
            .frame(width: 54, height: 68)
            .scaleEffect(on ? 1.04 : 1)
            .shadow(color: on ? Aqua.mint.opacity(0.35) : .clear, radius: on ? 8 : 0)
            .opacity(inPlan ? 1 : 0.35)
            .animation(AquaMotion.bounce, value: on)
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

    private func journey(leftTime: String, leftCode: String, leftCity: String, rightTime: String, rightCode: String, rightCity: String, duration: String, animated: Bool = false) -> some View {
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
                        .frame(width: 118, height: 26)
                        .offset(y: 9)
                    if animated && !reduceMotion {
                        OrbitingDrop()
                    } else {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Aqua.mint)
                            .frame(width: 22, height: 22)
                            .background(Aqua.tealFill, in: Circle())
                            .overlay(Circle().stroke(Aqua.mint.opacity(0.24)))
                    }
                }
                .frame(height: 34)
                Text(duration).font(.system(size: 8)).foregroundStyle(Aqua.muted)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 4) {
                Text(rightTime).font(.system(size: 11)).foregroundStyle(Aqua.muted)
                Text(rightCode).font(.system(size: 22, weight: .light))
                Text(rightCity).font(.system(size: 11)).foregroundStyle(Aqua.muted)
            }
        }
    }
}

struct AddRitualSheet: View {
    @Environment(AquaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var times = 1
    @State private var hour = 9
    @State private var symbol = "star.fill"
    private let symbols = ["star.fill", "heart.fill", "leaf.fill", "dumbbell.fill", "brain.head.profile", "fork.knife", "music.note", "paintbrush.fill"]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("New ritual").font(.title2)
            TextField("Name", text: $name)
                .textFieldStyle(.plain)
                .padding(14)
                .aquaCard()
            HStack(spacing: 8) {
                ForEach(symbols, id: \.self) { item in
                    Button {
                        withAnimation(AquaMotion.snappy) { symbol = item }
                    } label: {
                        Image(systemName: item)
                            .font(.system(size: 13))
                            .frame(width: 36, height: 36)
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
