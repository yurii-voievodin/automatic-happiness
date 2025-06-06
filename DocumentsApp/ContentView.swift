//
//  ContentView.swift
//  DocumentsApp
//
//  Created by Yurii Voievodin on 05/06/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var isShowingScanner = false
    @State private var isShowingFilePicker = false
    @State private var selectedPDFURL: URL?
    
    var body: some View {
        NavigationView {
            VStack {
                if let url = selectedPDFURL {
                    Text("PDF loaded: \(url.lastPathComponent)")
                        .font(.caption)
                } else {
                    Text("No PDF selected")
                        .font(.caption)
                }
            }
            .padding()
            .navigationTitle("Documents")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            isShowingFilePicker = true
                        } label: {
                            Label("Import from Files", systemImage: "folder")
                        }
                        Button {
                            isShowingScanner = true
                        } label: {
                            Label("Scan Document", systemImage: "camera")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingFilePicker) {
                DocumentPicker { url in
                    selectedPDFURL = url
                }
            }
            .sheet(isPresented: $isShowingScanner) {
                DocumentScanner { data in
                    let url = FileManager.default.temporaryDirectory.appendingPathComponent("Scanned.pdf")
                    try? data.write(to: url)
                    selectedPDFURL = url
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
