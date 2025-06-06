import Foundation

struct Document: Identifiable {
    let id: UUID
    let url: URL
    let name: String
    let createdAt: Date
    let fileSize: Int64
    
    init(url: URL) {
        self.id = UUID()
        self.url = url
        self.name = url.lastPathComponent
        self.createdAt = Date()
        
        // Get file size
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        self.fileSize = attributes?[.size] as? Int64 ?? 0
    }
    
    // Computed property for formatted file size
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
} 