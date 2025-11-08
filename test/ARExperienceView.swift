//
//  ARExperienceView.swift
//  test
//
//  Created by Ruchen Cai on 11/8/25.
//


//
//  ARExperienceView.swift
//

import SwiftUI

// Overlay a close (“back”) button because NavigationBar is hidden
struct ARExperienceView: View {
    @Environment(\.presentationMode) private var presentation
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            ARViewContainer()
                .ignoresSafeArea()
            
            Button(action: { presentation.wrappedValue.dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .shadow(radius: 4)
            }
            .padding()
        }
    }
}