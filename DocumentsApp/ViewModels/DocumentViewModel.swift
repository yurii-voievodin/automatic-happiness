import Foundation
import VisionKit
import SwiftUI
import SwiftData
import Combine

@MainActor
class DocumentViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published private(set) var securityRecommendations: [String] = []
    
    private let modelContext: ModelContext
    private let pdfGenerationService: PDFGenerationServiceProtocol
    private let securityService: SecurityService
    
    init(
        modelContext: ModelContext,
        pdfGenerationService: PDFGenerationServiceProtocol = PDFGenerationService(),
        securityService: SecurityService = .shared
    ) {
        self.modelContext = modelContext
        self.pdfGenerationService = pdfGenerationService
        self.securityService = securityService
    }
    
    func handleScannedDocument(_ scan: VNDocumentCameraScan) async {
        isLoading = true
        error = nil
        
        do {
            let pdfData = try pdfGenerationService.generatePDF(from: scan)
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("Scanned_\(Date().timeIntervalSince1970).pdf")
            try pdfData.write(to: tempURL)
            defer { try? FileManager.default.removeItem(at: tempURL) }
            
            let document = Document(url: tempURL)
            document.data = pdfData
            try document.saveToDocuments()
            
            modelContext.insert(document)
            try modelContext.save()
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func handlePickedDocument(_ url: URL) {
        do {
            let document = Document(url: url)
            try document.saveToDocuments()
            
            modelContext.insert(document)
            try modelContext.save()
        } catch {
            handleError(error)
        }
    }
    
    func deleteDocument(_ document: Document) {
        do {
            // Delete the file if it exists
            if let fileURL = document.fileURL {
                try? FileManager.default.removeItem(at: fileURL)
            }
            
            modelContext.delete(document)
            try modelContext.save()
        } catch {
            handleError(error)
        }
    }
    
    func handleError(_ error: Error) {
        self.error = error
    }
    
    func clearError() {
        error = nil
    }
    
    // MARK: - Security
    
    func checkSecurity() {
        let recommendations = securityService.getSecurityRecommendations()
        securityRecommendations = recommendations
    }
    
    func fulfillSecurityRecommendations() {
        checkSecurity()
        if securityRecommendations.isEmpty {
            securityRecommendations = ["Your device is secure"]
        }
    }
    
    // MARK: - Grouped and Sorted Documents
    func groupedDocumentsByDate(documents: [Document]) -> [(date: Date, documents: [Document])] {
        let grouped = Dictionary(grouping: documents) { document in
            Calendar.current.startOfDay(for: document.createdAt)
        }
        let sortedDates = grouped.keys.sorted(by: >)
        return sortedDates.map { date in
            (date, grouped[date]?.sorted(by: { $0.createdAt > $1.createdAt }) ?? [])
        }
    }
}
