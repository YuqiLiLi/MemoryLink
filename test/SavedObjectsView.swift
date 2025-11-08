//
//  SavedObjectsView.swift
//  test
//
//  Created by Ruchen Cai on 11/8/25.
//


//
//  SavedObjectsView.swift
//

import SwiftUI
import Foundation

extension URL: Identifiable {
    // Use the absoluteString (or path) as a stable, unique identifier.
    public var id: String { absoluteString }
}

struct SavedObjectsView: View {
    @State private var objectURLs: [URL] = []
    @State private var selectedURL: URL?
    
    var body: some View {
        List {
            ForEach(objectURLs, id: \.self) { url in
                Button {
                    selectedURL = url
                } label: {
                    HStack {
                        Image(systemName: "cube")
                        Text(url.deletingPathExtension().lastPathComponent)
                    }
                }
            }
            .onDelete(perform: delete)
        }
        .navigationTitle("Saved Scans")
        .onAppear(perform: loadObjects)
        .sheet(item: $selectedURL) { url in
            PointCloudPreview(objectURL: url)
                .edgesIgnoringSafeArea(.all)
        }
    }
    
    private func loadObjects() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        if let urls = try? FileManager.default.contentsOfDirectory(at: docs,
                                                                   includingPropertiesForKeys: nil,
                                                                   options: [.skipsHiddenFiles]) {
            objectURLs = urls.filter { $0.pathExtension == "arobject" }
        }
    }
    
    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let url = objectURLs[index]
            try? FileManager.default.removeItem(at: url)
        }
        objectURLs.remove(atOffsets: offsets)
    }
}
