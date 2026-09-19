import AuthenticationServices
import PhotosUI
import SwiftUI

struct ProfileView: View {
    @Environment(AquaStore.self) private var store

    @State private var draftName = ""
    @State private var pickerItem: PhotosPickerItem?
    @State private var showSignOut = false
    @State private var showDelete = false
    @State private var signInError: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Profile")
                    .font(.system(size: 30, weight: .light))
                    .padding(.bottom, 6)
                Text(store.isSignedIn ? "Apple account connected." : "Sign in to keep this name on this phone.")
                    .font(.system(size: 13))
                    .foregroundStyle(Aqua.muted)
                    .padding(.bottom, 22)

                hero
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 28)

                nameCard
                    .padding(.bottom, 11)

                photoCard
                    .padding(.bottom, 11)

                appleCard
                    .padding(.bottom, 11)

                legalCard
                    .padding(.bottom, 11)

                Text("AquaPulse is a personal reminder on this iPhone. It is not medical advice.")
                    .font(.system(size: 12))
                    .foregroundStyle(Aqua.muted)
                    .padding(.bottom, 11)

                Button("Delete account and reset data") { showDelete = true }
                    .font(.system(size: 15))
                    .foregroundStyle(.red.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .frame(height: 47)
                    .background(Aqua.panel, in: Capsule())
                    .overlay(Capsule().stroke(.red.opacity(0.25), lineWidth: 0.7))
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 48)
        }
        .background(AquaBackground())
        .aquaScreen()
        .scrollDismissesKeyboard(.interactively)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            draftName = store.name
            store.checkAppleCredential()
        }
        .task(id: pickerItem) {
            guard let pickerItem else { return }
            if let data = try? await pickerItem.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                store.setAvatar(image)
            }
        }
        .confirmationDialog("Sign out of Apple?", isPresented: $showSignOut) {
            Button("Sign Out", role: .destructive) { store.signOutApple() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your glasses and rituals stay on this phone. Name and photo stay until you change them.")
        }
        .confirmationDialog("Delete all AquaPulse data?", isPresented: $showDelete) {
            Button("Delete everything", role: .destructive) { store.resetAllData() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This signs you out, removes your name, photo, glasses, and rituals from this iPhone. It cannot be undone.")
        }
    }

    private var hero: some View {
        let avatar = store.avatarImage
        return VStack(spacing: 16) {
            PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                ProfileHeroPhoto(image: avatar)
            }
            .buttonStyle(AquaPressStyle())
            .accessibilityLabel("Change profile photo")

            ProfileChip(name: store.displayName, image: avatar)

            Text("Hi \(store.firstName)!")
                .font(.system(size: 22, weight: .light))
        }
    }

    private var nameCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Display name").font(.system(size: 13)).foregroundStyle(Aqua.muted)
            TextField("Your name", text: $draftName)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .tint(Aqua.mint)
                .onSubmit { store.setName(draftName) }
            Button("Save name") {
                store.setName(draftName)
                draftName = store.name
            }
            .buttonStyle(GlowButton())
        }
        .padding(14)
        .aquaCard()
    }

    private var photoCard: some View {
        let hasPhoto = store.avatarImage != nil
        return VStack(alignment: .leading, spacing: 10) {
            Text("Photo").font(.system(size: 13)).foregroundStyle(Aqua.muted)
            PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                ProfilePhotoRow(hasPhoto: hasPhoto)
            }
            if hasPhoto {
                Button("Use default avatar", role: .destructive) {
                    store.clearAvatar()
                    pickerItem = nil
                }
                .font(.system(size: 13))
            }
        }
        .padding(14)
        .aquaCard()
    }

    private var appleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Apple account").font(.system(size: 13)).foregroundStyle(Aqua.muted)
            if store.isSignedIn {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Aqua.mint)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Signed in")
                        Text(store.appleEmail ?? "Name and photo stay local.")
                            .font(.system(size: 13))
                            .foregroundStyle(Aqua.muted)
                    }
                    Spacer()
                }
                Button("Sign Out") { showSignOut = true }
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .frame(height: 47)
                    .background(Aqua.panel, in: Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 0.7))
            } else {
                Text("Use Sign in with Apple to attach this profile. Apple does not send a photo — pick one here.")
                    .font(.system(size: 13))
                    .foregroundStyle(Aqua.muted)
                    .fixedSize(horizontal: false, vertical: true)
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    switch result {
                    case .success(let auth):
                        signInError = nil
                        if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                            store.applyApple(credential)
                            draftName = store.name
                        }
                    case .failure(let error):
                        let ns = error as NSError
                        if ns.code == ASAuthorizationError.canceled.rawValue { return }
                        signInError = "Apple sign-in needs the AquaPulse capability in Xcode (Signing & Capabilities)."
                    }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 47)
                .clipShape(Capsule())
                if let signInError {
                    Text(signInError)
                        .font(.system(size: 12))
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(14)
        .aquaCard()
    }

    private var legalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Legal").font(.system(size: 13)).foregroundStyle(Aqua.muted)
            Link("Privacy Policy", destination: AquaLegal.privacy)
            Link("Terms of Use", destination: AquaLegal.terms)
            Link("Support", destination: AquaLegal.support)
        }
        .font(.system(size: 15))
        .foregroundStyle(.white)
        .padding(14)
        .aquaCard()
    }
}

private struct ProfileHeroPhoto: View {
    let image: UIImage?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ProfileAvatar(image: image, size: 96, symbolSize: 78)
                .overlay(Circle().stroke(.white.opacity(0.18), lineWidth: 0.8))
            Image(systemName: "camera.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Aqua.tealFill, in: Circle())
                .overlay(Circle().stroke(Aqua.mint.opacity(0.35), lineWidth: 0.8))
                .offset(x: 4, y: 4)
        }
    }
}

private struct ProfilePhotoRow: View {
    let hasPhoto: Bool

    var body: some View {
        HStack {
            Text(hasPhoto ? "Change photo" : "Choose a photo")
            Spacer()
            Image(systemName: "photo")
                .font(.system(size: 13))
                .foregroundStyle(Aqua.muted)
        }
        .foregroundStyle(.white)
        .padding(.vertical, 4)
    }
}
