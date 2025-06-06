import SwiftUI
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void
    let onError: ((Error) -> Void)?
    
    init(
        onPick: @escaping (URL) -> Void,
        onError: ((Error) -> Void)? = nil
    ) {
        self.onPick = onPick
        self.onError = onError
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, onError: onError)
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types = [UTType.pdf]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        let onError: ((Error) -> Void)?
        
        init(
            onPick: @escaping (URL) -> Void,
            onError: ((Error) -> Void)?
        ) {
            self.onPick = onPick
            self.onError = onError
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                onError?(NSError(domain: "DocumentPicker", code: -1, userInfo: [NSLocalizedDescriptionKey: "No document selected"]))
                return
            }
            
            // Start accessing the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                onError?(NSError(domain: "DocumentPicker", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to access the selected document"]))
                return
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            onPick(url)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // Handle cancellation if needed
        }
    }
}
