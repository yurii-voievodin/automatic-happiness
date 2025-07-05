import Foundation
import VisionKit
import SwiftUI
import SwiftData
import Combine
import Vision

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
            
            // Perform text recognition on the scanned document
            let recognizedText = await recognizeText(from: scan)
            
            let document = Document(url: tempURL)
            document.recognizedText = recognizedText.isEmpty ? nil : recognizedText
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
    
    // MARK: - Text Recognition
    
    private func recognizeText(from scan: VNDocumentCameraScan) async -> String {
        print("🔍 Starting text recognition for \(scan.pageCount) page(s)")
        
        var allRecognizedText: [String] = []
        
        for pageIndex in 0..<scan.pageCount {
            let image = scan.imageOfPage(at: pageIndex)
            
            guard let cgImage = image.cgImage else {
                print("❌ Failed to get CGImage for page \(pageIndex + 1)")
                continue
            }
            
            let pageText = await withCheckedContinuation { continuation in
                let request = VNRecognizeTextRequest { request, error in
                    if let error = error {
                        print("❌ Text recognition error for page \(pageIndex + 1): \(error.localizedDescription)")
                        continuation.resume(returning: "")
                        return
                    }
                    
                    guard let observations = request.results as? [VNRecognizedTextObservation] else {
                        print("❌ No text recognition results for page \(pageIndex + 1)")
                        continuation.resume(returning: "")
                        return
                    }
                    
                    var recognizedText = ""
                    for observation in observations {
                        guard let topCandidate = observation.topCandidates(1).first else { continue }
                        recognizedText += topCandidate.string + "\n"
                    }
                    
                    let cleanedText = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if cleanedText.isEmpty {
                        print("📄 Page \(pageIndex + 1): No text found")
                    } else {
                        print("📄 Page \(pageIndex + 1) recognized text:")
                        print("---")
                        print(cleanedText)
                        print("---")
                    }
                    
                    continuation.resume(returning: cleanedText)
                }
                
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                
                do {
                    try handler.perform([request])
                } catch {
                    print("❌ Failed to perform text recognition for page \(pageIndex + 1): \(error.localizedDescription)")
                    continuation.resume(returning: "")
                }
            }
            
            if !pageText.isEmpty {
                allRecognizedText.append(pageText)
            }
        }
        
        let combinedText = allRecognizedText.joined(separator: "\n\n--- Page \(allRecognizedText.count > 1 ? "Break" : "") ---\n\n")
        
        if combinedText.isEmpty {
            print("📄 No text found in document")
        } else {
            print("✅ Combined recognized text saved to document")
        }
        
        return combinedText
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
