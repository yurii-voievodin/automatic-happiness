import SwiftUI

struct DocumentRow: View {
    let document: Document
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let thumbnail = document.getThumbnail() {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 80)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)
            } else {
                // Placeholder when no thumbnail is available
                Image(systemName: "doc.text")
                    .font(.system(size: 30))
                    .frame(width: 60, height: 80)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)
            }
            
            // Document info
            VStack(alignment: .leading, spacing: 4) {
                Text(document.name)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    Label(document.formattedFileSize, systemImage: "doc")
                    Spacer()
                    Label(document.createdAt.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    // Create a sample document for preview
    let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
    let data = renderer.pdfData { ctx in
        ctx.beginPage()
        let text = "Sample PDF Document"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24)
        ]
        text.draw(at: CGPoint(x: 50, y: 50), withAttributes: attributes)
    }
    
    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("sample.pdf")
    try? data.write(to: tempURL)
    let document = Document(url: tempURL)
    
    return List {
        DocumentRow(document: document)
    }
} 