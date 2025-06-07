import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var documents: [Document]
    @StateObject private var viewModel: DocumentViewModel
    @State private var isShowingScanner = false
    @State private var isShowingFilePicker = false
    
    init(modelContext: ModelContext) {
        // Initialize the view model with the provided model context
        _viewModel = StateObject(wrappedValue: DocumentViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationView {
            Group {
                if documents.isEmpty {
                    ContentUnavailableView(
                        "No Documents",
                        systemImage: "doc.text",
                        description: Text("Use the + button to scan or import a document")
                    )
                } else {
                    List {
                        ForEach(documents) { document in
                            NavigationLink(destination: DocumentDetailView(document: document)) {
                                DocumentRow(document: document)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    viewModel.deleteDocument(document)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
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

// Add a convenience initializer that uses the environment
extension ContentView {
    init() {
        // This will be called when the view is created in the preview
        // The actual modelContext will be injected by SwiftUI when the view is rendered
        self.init(modelContext: ModelContext(try! ModelContainer(for: Document.self)))
    }
}

struct DocumentRow: View {
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
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Document.self, inMemory: true)
} 
