import Foundation
import VisionKit
import SwiftUI
import Combine

@MainActor
class DocumentViewModel: ObservableObject {
    @Published private(set) var currentDocument: Document?
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    private let pdfGenerationService: PDFGenerationServiceProtocol
    
    init(pdfGenerationService: PDFGenerationServiceProtocol = PDFGenerationService()) {
        self.pdfGenerationService = pdfGenerationService
    }
    
    func handleScannedDocument(_ scan: VNDocumentCameraScan) async {
        isLoading = true
        error = nil
        
        do {
            let pdfData = try pdfGenerationService.generatePDF(from: scan)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("Scanned_\(Date().timeIntervalSince1970).pdf")
            try pdfData.write(to: url)
            currentDocument = Document(url: url)
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func handlePickedDocument(_ url: URL) {
        currentDocument = Document(url: url)
    }
    
    func handleError(_ error: Error) {
        self.error = error
    }
    
    func clearError() {
        error = nil
    }
    
    func clearCurrentDocument() {
        currentDocument = nil
    }
} 
