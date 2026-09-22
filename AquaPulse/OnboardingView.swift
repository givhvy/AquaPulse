import AuthenticationServices
import SwiftUI

struct OnboardingView: View {
    @Environment(AquaStore.self) private var store
    @State private var page = 0
    @State private var name = ""
    @State private var goalML = 2000
    @State private var glassML = 250
    @State private var extraKinds: Set<String> = ["youtube", "wavs", "suno", "imagegen"]
    @State private var signInError: String?

    private let goals = [1500, 2000, 2500, 3000]
    private let glasses = [150, 250, 330, 500]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                welcome.tag(0)
                identity.tag(1)
                goal.tag(2)
                habits.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? Aqua.mint : .white.opacity(0.18))
                        .frame(width: index == page ? 18 : 6, height: 6)
                }
            }
            .padding(.bottom, 16)

            Button(page == 3 ? "Start tracking" : "Continue") {
                if page < 3 {
                    withAnimation(AquaMotion.ui) { page += 1 }
                } else {
                    store.finishOnboarding(
                        name: name,
                        goalML: goalML,
                        glassML: glassML,
                        extraKinds: extraKinds
                    )
                }
            }
            .buttonStyle(GlowButton())
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
        .background(AquaBackground())
        .aquaScreen()
        .preferredColorScheme(.dark)
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()
            Image(systemName: "drop.fill")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(Aqua.mint)
            Text("AquaPulse")
                .font(.system(size: 34, weight: .light))
            Text("Log water and daily rituals on this iPhone. Streaks start at zero and only move when you check in.")
                .font(.system(size: 15))
                .foregroundStyle(Aqua.muted)
                .fixedSize(horizontal: false, vertical: true)
            Text("AquaPulse is a personal reminder. It is not medical advice, a diagnosis, or a treatment for dehydration or any condition.")
                .font(.system(size: 13))
                .foregroundStyle(Aqua.muted.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.horizontal, 22)
    }

    private var identity: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What should we call you?")
                .font(.system(size: 28, weight: .light))
            Text("Optional. You can skip this and change it later in Profile.")
                .font(.system(size: 13))
                .foregroundStyle(Aqua.muted)
            TextField("Your name", text: $name)
                .textInputAutocapitalization(.words)
                .padding(14)
                .aquaCard()
                .tint(Aqua.mint)
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                switch result {
                case .success(let auth):
                    signInError = nil
                    if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                        store.applyApple(credential)
                        if !store.name.isEmpty { name = store.name }
                    }
                case .failure(let error):
                    let ns = error as NSError
                    if ns.code == ASAuthorizationError.canceled.rawValue { return }
                    signInError = "You can continue without Apple and sign in later in Profile."
                }
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 47)
            .clipShape(Capsule())
            if let signInError {
                Text(signInError).font(.system(size: 12)).foregroundStyle(.orange)
            }
            Spacer()
        }
        .padding(.horizontal, 22)
        .padding(.top, 36)
    }

    private var goal: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily water goal")
                .font(.system(size: 28, weight: .light))
            Text("Pick a target you can actually hit. You can change this on Home.")
                .font(.system(size: 13))
                .foregroundStyle(Aqua.muted)
            HStack(spacing: 8) {
                ForEach(goals, id: \.self) { ml in
                    Button {
                        withAnimation(AquaMotion.snappy) { goalML = ml }
                    } label: {
                        Text(String(format: "%.1f L", Double(ml) / 1000))
                            .font(.system(size: 13))
                            .foregroundStyle(goalML == ml ? Color.black : .white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(goalML == ml ? Color.white : Color.clear, in: Capsule())
                            .overlay(Capsule().stroke(.white.opacity(goalML == ml ? 0 : 0.12)))
                    }
                    .buttonStyle(.plain)
                }
            }
            Text("Glass size").font(.system(size: 15)).padding(.top, 8)
            HStack(spacing: 8) {
                ForEach(glasses, id: \.self) { ml in
                    Button {
                        withAnimation(AquaMotion.snappy) { glassML = ml }
                    } label: {
                        Text("\(ml)")
                            .font(.system(size: 13))
                            .foregroundStyle(glassML == ml ? Color.black : .white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(glassML == ml ? Color.white : Color.clear, in: Capsule())
                            .overlay(Capsule().stroke(.white.opacity(glassML == ml ? 0 : 0.12)))
                    }
                    .buttonStyle(.plain)
                }
            }
            Text("\(max(goalML / max(glassML, 1), 1)) glasses to goal")
                .font(.system(size: 13))
                .foregroundStyle(Aqua.muted)
            Spacer()
        }
        .padding(.horizontal, 22)
        .padding(.top, 36)
    }

    private var habits: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Any other rituals?")
                .font(.system(size: 28, weight: .light))
            Text("Water is always included at zero. Extra habits also start at zero.")
                .font(.system(size: 13))
                .foregroundStyle(Aqua.muted)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(Ritual.extraTemplates) { ritual in
                        Button {
                            withAnimation(AquaMotion.snappy) {
                                if extraKinds.contains(ritual.kind) {
                                    extraKinds.remove(ritual.kind)
                                } else {
                                    extraKinds.insert(ritual.kind)
                                }
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: ritual.symbol)
                                    .frame(width: 32, height: 32)
                                    .background(Aqua.panel, in: Circle())
                                Text(ritual.name).font(.system(size: 15))
                                Spacer()
                                Image(systemName: extraKinds.contains(ritual.kind) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(extraKinds.contains(ritual.kind) ? Aqua.mint : Aqua.muted)
                            }
                            .padding(12)
                            .aquaCard()
                        }
                        .buttonStyle(AquaPressStyle())
                    }
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 36)
    }
}
