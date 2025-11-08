//
//  LaunchView.swift
//  YourProjectName
//
//  Created by Your Name on 2023-08-XX.
//

import SwiftUI

struct LaunchView: View {
    
    // Which full-screen sheet is being shown?
    @State private var showARView      = false
    @State private var showScanner     = false
    @State private var showSavedScans  = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                
                Spacer()
                
                Text("AR Demo")
                    .font(.largeTitle).bold()
                
                // 1) AR Experience ------------------------------------------------
                Button(action: { showARView = true }) {
                    Label("Enter AR View", systemImage: "arkit")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                // 2) Object Scanner ----------------------------------------------
                Button(action: { showScanner = true }) {
                    Label("Scan Object", systemImage: "viewfinder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                // 3) Saved Scans --------------------------------------------------
                NavigationLink(destination: SavedObjectsView()) {
                    Label("Saved Scans", systemImage: "tray.full")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Start")
            // full-screen sheets for AR and Scanner (need to cover whole screen)
            .fullScreenCover(isPresented: $showARView)     { ARExperienceView() }
            .fullScreenCover(isPresented: $showScanner)    { ScannerExperienceView() }
        }
    }
}
