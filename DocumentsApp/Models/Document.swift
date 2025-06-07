import Foundation
import SwiftData
import PDFKit
import UIKit

@Model
final class Document {
    var id: UUID
    var name: String
    var createdAt: Date
    var fileSize: Int64
    var fileURL: URL?
    var data: Data?
    var thumbnailData: Data?
    
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
            // Generate thumbnail
            self.thumbnailData = generateThumbnail(from: data)
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
        
        // Generate thumbnail if not already present
        if thumbnailData == nil {
            self.thumbnailData = generateThumbnail(from: data)
        }
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
    
    // Method to get thumbnail image
    func getThumbnail() -> UIImage? {
        if let thumbnailData = thumbnailData {
            return UIImage(data: thumbnailData)
        }
        return nil
    }
    
    // Private method to generate thumbnail
    private func generateThumbnail(from pdfData: Data) -> Data? {
        guard let pdfDocument = PDFDocument(data: pdfData),
              let firstPage = pdfDocument.page(at: 0) else {
            return nil
        }
        
        // Calculate thumbnail size (maintaining aspect ratio)
        let pageRect = firstPage.bounds(for: .mediaBox)
        let aspectRatio = pageRect.width / pageRect.height
        let thumbnailHeight: CGFloat = 100
        let thumbnailWidth = thumbnailHeight * aspectRatio
        
        // Create thumbnail
        let thumbnailRect = CGRect(x: 0, y: 0, width: thumbnailWidth, height: thumbnailHeight)
        let renderer = UIGraphicsImageRenderer(size: thumbnailRect.size)
        
        let thumbnailImage = renderer.image { context in
            // Fill background
            UIColor.systemBackground.set()
            context.fill(thumbnailRect)
            
            // Draw PDF page
            context.cgContext.translateBy(x: 0, y: thumbnailHeight)
            context.cgContext.scaleBy(x: thumbnailWidth / pageRect.width, y: -thumbnailHeight / pageRect.height)
            firstPage.draw(with: .mediaBox, to: context.cgContext)
        }
        
        // Convert to JPEG data with compression
        return thumbnailImage.jpegData(compressionQuality: 0.7)
    }
}

// MARK: - Errors
enum DocumentError: Error {
    case missingData
    case saveFailed
    case thumbnailGenerationFailed
    
    var localizedDescription: String {
        switch self {
        case .missingData:
            return "Document data is missing"
        case .saveFailed:
            return "Failed to save document"
        case .thumbnailGenerationFailed:
            return "Failed to generate document thumbnail"
        }
    }
} 