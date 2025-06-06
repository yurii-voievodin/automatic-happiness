import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = DocumentViewModel()
    @State private var isShowingScanner = false
    @State private var isShowingFilePicker = false
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Processing document...")
                } else if let document = viewModel.currentDocument {
                    DocumentView(document: document)
                } else {
                    ContentUnavailableView(
                        "No Document Selected",
                        systemImage: "doc.text",
                        description: Text("Use the + button to scan or import a document")
                    )
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
                DocumentPicker(
                    onPick: { url in
                        viewModel.handlePickedDocument(url)
                    },
                    onError: { error in
                        viewModel.handleError(error)
                    }
                )
            }
            .sheet(isPresented: $isShowingScanner) {
                DocumentScanner { scan in
                    Task {
                        await viewModel.handleScannedDocument(scan)
                    }
                } onError: { error in
                    viewModel.handleError(error)
                }
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
        }
    }
}

struct DocumentView: View {
    let document: Document
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(document.name)
                .font(.headline)
            
            HStack {
                Label(document.formattedFileSize, systemImage: "doc")
                    .font(.caption)
                Spacer()
                Label(document.createdAt.formatted(), systemImage: "calendar")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            
            // TODO: Add PDF preview here
            Text("PDF Preview Coming Soon")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
        }
    }
}

#Preview {
    ContentView()
} 