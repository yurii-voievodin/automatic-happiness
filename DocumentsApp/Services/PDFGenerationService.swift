import Foundation
import UIKit
import VisionKit

protocol PDFGenerationServiceProtocol {
    func generatePDF(from scan: VNDocumentCameraScan) throws -> Data
}

class PDFGenerationService: PDFGenerationServiceProtocol {
    
    func generatePDF(from scan: VNDocumentCameraScan) throws -> Data {
        // Use a temporary renderer to get the data - we'll set bounds per page
        let tempRenderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: CGSize(width: 612, height: 792)))
        
        return tempRenderer.pdfData { ctx in
            for i in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: i)
                // Use the original image size to preserve proportions
                let pageSize = image.size
                ctx.beginPage(withBounds: CGRect(origin: .zero, size: pageSize), pageInfo: [:])
                image.draw(in: CGRect(origin: .zero, size: pageSize))
            }
        }
    }
}

// Error types for PDF generation
enum PDFGenerationError: Error {
    case generationFailed
    case invalidImage
    
    var localizedDescription: String {
        switch self {
        case .generationFailed:
            return "Failed to generate PDF document"
        case .invalidImage:
            return "Invalid image data"
        }
    }
} 