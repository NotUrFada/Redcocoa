import SwiftUI

struct SplashView: View {
    var onFinish: () -> Void
    
    var body: some View {
        ZStack {
            Color.bgDark
                .ignoresSafeArea()
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
        }
        .task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run { onFinish() }
        }
    }
}
