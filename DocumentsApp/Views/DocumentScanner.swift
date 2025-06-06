import SwiftUI
import VisionKit

struct DocumentScanner: UIViewControllerRepresentable {
    var onScanCompleted: (VNDocumentCameraScan) -> Void
    var onError: (Error) -> Void
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onScanCompleted: onScanCompleted, onError: onError)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var onScanCompleted: (VNDocumentCameraScan) -> Void
        var onError: (Error) -> Void
        
        init(onScanCompleted: @escaping (VNDocumentCameraScan) -> Void,
             onError: @escaping (Error) -> Void) {
            self.onScanCompleted = onScanCompleted
            self.onError = onError
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            controller.dismiss(animated: true)
            onScanCompleted(scan)
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            controller.dismiss(animated: true)
            onError(error)
        }
    }
} 