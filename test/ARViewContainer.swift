//
//  ARViewContainer.swift
//  YourProjectName
//
//  Created by Your Name on 2023/08/XX.
//

import SwiftUI
import UIKit

/// A Swift-UI wrapper around the existing UIKit/Metal `ViewController`.
///
/// This struct lets us embed `ViewController` inside any Swift-UI view
/// (for example, after the user taps “Enter” on the launch screen).
struct ARViewContainer: UIViewControllerRepresentable {
    
    // MARK: - UIViewControllerRepresentable conformance
    
    /// Create and return the UIKit view controller that does all the AR work.
    func makeUIViewController(context: Context) -> MasterViewController {
        return MasterViewController()        // ← your existing AR/Metal view controller
    }
    
    /// No dynamic updates needed; the AR view controller manages itself.
    func updateUIViewController(_ uiViewController: MasterViewController,
                                context: Context) {
        // Intentionally left empty.
    }
}

#if DEBUG
// Optional Swift-UI preview so you can see the AR view container in Xcode previews.
struct ARViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        ARViewContainer()
            .edgesIgnoringSafeArea(.all)
    }
}
#endif
