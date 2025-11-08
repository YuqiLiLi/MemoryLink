//
//  ScannerExperienceView.swift
//  test
//
//  Created by Ruchen Cai on 11/8/25.
//


//
//  ScannerExperienceView.swift
//

import SwiftUI

struct ScannerExperienceView: View {
    @Environment(\.presentationMode) private var presentation
    @State private var lastSavedURL: URL?
    @State private var showPointCloud = false
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            ObjectScannerContainer { url in
                // Called when scanner finishes or cancels
                if let u = url {
                    lastSavedURL = u
                    showPointCloud = true
                } else {
                    presentation.wrappedValue.dismiss()
                }
            }
            .ignoresSafeArea()
            
            Button(action: { presentation.wrappedValue.dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .shadow(radius: 4)
            }
            .padding()
        }
        .fullScreenCover(isPresented: $showPointCloud, onDismiss: {
            // after preview closes, also close scanner
            presentation.wrappedValue.dismiss()
        }) {
            if let url = lastSavedURL {
                PointCloudPreview(objectURL: url)
                    .ignoresSafeArea()
            }
        }
    }
}