//
//  DocumentScanner.swift
//  DocumentsApp
//
//  Created by Yurii Voievodin on 06/06/2025.
//

import SwiftUI
import VisionKit

struct DocumentScanner: UIViewControllerRepresentable {
    var onScanCompleted: (Data) -> Void
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onScanCompleted: onScanCompleted)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var onScanCompleted: (Data) -> Void
        
        init(onScanCompleted: @escaping (Data) -> Void) {
            self.onScanCompleted = onScanCompleted
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            controller.dismiss(animated: true)
            
            let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
            let data = renderer.pdfData { ctx in
                for i in 0..<scan.pageCount {
                    let img = scan.imageOfPage(at: i)
                    ctx.beginPage()
                    img.draw(in: CGRect(x: 0, y: 0, width: 612, height: 792))
                }
            }
            
            onScanCompleted(data)
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            controller.dismiss(animated: true)
            print("Scan failed: \(error.localizedDescription)")
        }
    }
}
