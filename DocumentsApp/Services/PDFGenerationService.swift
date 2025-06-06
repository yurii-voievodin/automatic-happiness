import Foundation
import UIKit
import VisionKit

protocol PDFGenerationServiceProtocol {
    func generatePDF(from scan: VNDocumentCameraScan) throws -> Data
}

class PDFGenerationService: PDFGenerationServiceProtocol {
    private let pageSize: CGSize
    
    init(pageSize: CGSize = CGSize(width: 612, height: 792)) {
        self.pageSize = pageSize
    }
    
    func generatePDF(from scan: VNDocumentCameraScan) throws -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        
        return renderer.pdfData { ctx in
            for i in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: i)
                ctx.beginPage()
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