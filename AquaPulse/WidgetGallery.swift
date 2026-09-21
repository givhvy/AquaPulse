import SwiftUI

#if DEBUG
struct WidgetGalleryView: View {
    private let snap = AquaSnapshot.preview

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                Text("Home Screen widgets")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(.white)

                labeled("Small") {
                    AquaSmallWidget(snap: snap)
                        .frame(width: 165, height: 165)
                }
                labeled("Medium") {
                    AquaMediumWidget(snap: snap)
                        .frame(width: 345, height: 165)
                }
                labeled("Large") {
                    AquaLargeWidget(snap: snap)
                        .frame(width: 345, height: 362)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 64)
            .padding(.bottom, 40)
        }
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private func labeled<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(Aqua.muted)
            content()
                .background(Aqua.night)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 0.6)
                )
        }
    }
}
#endif
