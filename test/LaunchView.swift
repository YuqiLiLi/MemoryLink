import SwiftUI

struct LaunchView: View {

    @State private var showAR = false
    @State private var showScanner = false
    @State private var lastSavedURL: URL?

    var body: some View {
        VStack(spacing: 40) {
            Text("Welcome to My AR App")
                .font(.largeTitle).bold()

            Button("Enter AR View") { showAR = true }
                .buttonStyle(.borderedProminent)
            
            Button("Scan New Object") { showScanner = true }
                .buttonStyle(.bordered)
        }
        .fullScreenCover(isPresented: $showAR) {
            ARViewContainer()
                .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showScanner) {
            ObjectScannerContainer { url in      // completion handler
                showScanner = false
                self.lastSavedURL = url
            }
            .ignoresSafeArea()
        }
    }
}
