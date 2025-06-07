import SwiftUI

struct DocumentDetailView: View {
    let document: Document
    @State private var pdfData: Data?
    @State private var error: Error?
    @State private var isLoading = true
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Document metadata
                VStack(alignment: .leading, spacing: 8) {
                    Text(document.name)
                        .font(.title2)
                        .bold()
                    
                    HStack {
                        Label(document.formattedFileSize, systemImage: "doc")
                        Spacer()
                        Label(document.createdAt.formatted(), systemImage: "calendar")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                
                // PDF Preview
                Group {
                    if isLoading {
                        ProgressView("Loading document...")
                            .frame(maxWidth: .infinity, minHeight: 400)
                    } else if let data = pdfData {
                        PDFPreviewView(data: data)
                            .frame(maxWidth: .infinity, minHeight: 400)
                            .cornerRadius(8)
                    } else if let error = error {
                        ContentUnavailableView(
                            "Failed to load document",
                            systemImage: "exclamationmark.triangle",
                            description: Text(error.localizedDescription)
                        )
                        .frame(maxWidth: .infinity, minHeight: 400)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadDocument()
        }
    }
    
    private func loadDocument() async {
        isLoading = true
        error = nil
        
        do {
            pdfData = try document.getData()
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
}

#Preview {
    NavigationView {
        DocumentDetailView(document: Document(url: URL(fileURLWithPath: "")))
    }
} 