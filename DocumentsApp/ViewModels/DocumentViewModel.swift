import Foundation
import VisionKit
import SwiftUI
import SwiftData
import Combine
import Vision
import PDFKit

@MainActor
class DocumentViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var isPerformingTextRecognition = false
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
            isPerformingTextRecognition = true
            let recognizedText = await recognizeText(from: scan)
            isPerformingTextRecognition = false
            
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
    
    func handlePickedDocument(_ url: URL) async {
        isLoading = true
        error = nil
        
        do {
            let document = Document(url: url)
            
            // Perform text recognition on the imported PDF
            if let pdfData = document.data {
                isPerformingTextRecognition = true
                let recognizedText = await recognizeText(from: pdfData)
                isPerformingTextRecognition = false
                document.recognizedText = recognizedText.isEmpty ? nil : recognizedText
            }
            
            try document.saveToDocuments()
            
            modelContext.insert(document)
            try modelContext.save()
        } catch {
            handleError(error)
        }
        
        isLoading = false
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
            
            let pageText = await recognizeText(from: cgImage, pageIndex: pageIndex)
            if !pageText.isEmpty {
                allRecognizedText.append(pageText)
            }
        }
        
        return combineRecognizedText(allRecognizedText)
    }
    
    private func recognizeText(from pdfData: Data) async -> String {
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            print("❌ Failed to create PDF document from data")
            return ""
        }
        
        let pageCount = pdfDocument.pageCount
        print("🔍 Starting text recognition for \(pageCount) PDF page(s)")
        
        var allRecognizedText: [String] = []
        
        for pageIndex in 0..<pageCount {
            guard let pdfPage = pdfDocument.page(at: pageIndex) else {
                print("❌ Failed to get PDF page \(pageIndex + 1)")
                continue
            }
            
            // Get page bounds and create a reasonably sized image
            let pageRect = pdfPage.bounds(for: .mediaBox)
            let scale: CGFloat = 2.0 // Higher resolution for better OCR
            let scaledSize = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)
            
            let renderer = UIGraphicsImageRenderer(size: scaledSize)
            let image = renderer.image { context in
                UIColor.white.set()
                context.fill(CGRect(origin: .zero, size: scaledSize))
                
                context.cgContext.translateBy(x: 0, y: scaledSize.height)
                context.cgContext.scaleBy(x: scale, y: -scale)
                pdfPage.draw(with: .mediaBox, to: context.cgContext)
            }
            
            guard let cgImage = image.cgImage else {
                print("❌ Failed to get CGImage for PDF page \(pageIndex + 1)")
                continue
            }
            
            let pageText = await recognizeText(from: cgImage, pageIndex: pageIndex)
            if !pageText.isEmpty {
                allRecognizedText.append(pageText)
            }
        }
        
        return combineRecognizedText(allRecognizedText)
    }
    
    private func recognizeText(from cgImage: CGImage, pageIndex: Int) async -> String {
        return await withCheckedContinuation { continuation in
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
    }
    
    private func combineRecognizedText(_ textArray: [String]) -> String {
        let combinedText = textArray.joined(separator: "\n\n--- Page \(textArray.count > 1 ? "Break" : "") ---\n\n")
        
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
