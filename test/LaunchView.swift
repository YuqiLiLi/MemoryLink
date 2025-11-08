import SwiftUI

struct StartView: View {
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [.black.opacity(0.9), .gray.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("Welcome")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)

                    Text("Tap Enter to start the AR experience.")
                        .foregroundColor(.white.opacity(0.8))

                    NavigationLink(destination: ARViewControllerWrapper().ignoresSafeArea()) {
                        Text("Enter")
                            .font(.headline)
                            .padding(.horizontal, 48)
                            .padding(.vertical, 16)
                            .background(.white)
                            .foregroundColor(.black)
                            .clipShape(Capsule())
                            .shadow(radius: 8)
                    }
                    .accessibilityIdentifier("enterButton")
                }
                .padding()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
