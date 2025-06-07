import Foundation
import SwiftData

@Model
final class Document {
    var id: UUID
    var name: String
    var createdAt: Date
    var fileSize: Int64
    var fileURL: URL?
    var data: Data?
    
    init(url: URL) {
        self.id = UUID()
        self.name = url.lastPathComponent
        self.createdAt = Date()
        
        // Get file size
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        self.fileSize = attributes?[.size] as? Int64 ?? 0
        
        // Store the file data
        if let data = try? Data(contentsOf: url) {
            self.data = data
        }
        
        // Store the URL if it's in the app's documents directory
        if url.path.hasPrefix(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path) {
            self.fileURL = url
        }
    }
    
    // Computed property for formatted file size
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    // Method to save document to app's documents directory
    func saveToDocuments() throws {
        guard let data = data else {
            throw DocumentError.missingData
        }
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "\(id.uuidString)_\(name)"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        try data.write(to: fileURL)
        self.fileURL = fileURL
    }
    
    // Method to get the document's data
    func getData() throws -> Data {
        if let data = data {
            return data
        }
        
        if let url = fileURL, let data = try? Data(contentsOf: url) {
            return data
        }
        
        throw DocumentError.missingData
    }
}

// MARK: - Errors
enum DocumentError: Error {
    case missingData
    case saveFailed
    
    var localizedDescription: String {
        switch self {
        case .missingData:
            return "Document data is missing"
        case .saveFailed:
            return "Failed to save document"
        }
    }
} 