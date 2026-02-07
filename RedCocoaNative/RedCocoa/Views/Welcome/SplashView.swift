import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.bgDark
                .ignoresSafeArea()
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
        }
    }
}
