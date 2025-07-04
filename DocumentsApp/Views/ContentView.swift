import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var authService: AuthenticationService
    @Query private var documents: [Document]
    @StateObject private var viewModel: DocumentViewModel
    @State private var isShowingScanner = false
    @State private var isShowingFilePicker = false
    @State private var isShowingSecurityAlert = false
    @State private var isShowingLogin = false
    
    init(modelContext: ModelContext) {
        // Initialize the view model with the provided model context
        _viewModel = StateObject(wrappedValue: DocumentViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
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
                        .listStyle(.insetGrouped)
                    }
                }
                
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
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
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.accentColor)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Documents")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if authService.isAuthenticated {
                        Menu {
                            if let user = authService.currentUser {
                                Text(user.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Button(role: .destructive, action: {
                                authService.logout()
                            }) {
                                Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        } label: {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                        }
                    } else {
                        Button(action: {
                            isShowingLogin = true
                        }) {
                            Image(systemName: "person.circle")
                                .font(.title2)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.fullfillSecurityRecomendations()
                        isShowingSecurityAlert = true
                    } label: {
                        Image(systemName: "shield")
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
            .sheet(isPresented: $isShowingLogin) {
                LoginView()
                    .onChange(of: authService.isAuthenticated) { oldValue, newValue in
                        if newValue {
                            isShowingLogin = false
                        }
                    }
            }
            .sheet(isPresented: $isShowingSecurityAlert) {
                SecurityAlertView(
                    recommendations: viewModel.securityRecommendations,
                    isPresented: Binding(
                        get: { isShowingSecurityAlert },
                        set: { _ in isShowingSecurityAlert = false }
                    )
                )
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
            .task {
                // Check security when the view appears
                viewModel.checkSecurity()
                if !viewModel.securityRecommendations.isEmpty {
                    isShowingSecurityAlert = true
                }
            }
        }
    }
}

// Add a convenience initializer used in previews
// that creates a default model context instead of relying on the environment
extension ContentView {
    init() {
        // This will be called when the view is created in the preview
        // The actual modelContext will be injected by SwiftUI when the view is rendered
        self.init(modelContext: ModelContext(try! ModelContainer(for: Document.self)))
    }
}

// MARK: - Preview Helpers

#Preview("Normal View") {
    ContentView()
        .modelContainer(for: Document.self, inMemory: true)
}

#Preview("Security Alert View") {
    SecurityAlertView(
        recommendations: [
            "Your device appears to be jailbroken. This may compromise the security of your documents.",
            "Consider using a non-jailbroken device for sensitive documents.",
            "Be cautious when accessing sensitive information on this device.",
            "Preview: This is a simulated security alert for demonstration purposes."
        ],
        isPresented: .constant(true)
    )
}

#Preview {
    ContentView(modelContext: try! ModelContainer(for: Document.self).mainContext)
        .environmentObject(AuthenticationService.shared)
}
