import SwiftUI
import WebKit

struct TermsAndConditionsView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @State private var error: Error?
    
    func makeUIViewController(context: Context) -> UIViewController {
        // Create a temporary HTML file with loading state
        let loadingHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                    margin: 0;
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                    color: #333;
                    background-color: #fff;
                }
                .loading {
                    text-align: center;
                }
                .spinner {
                    width: 40px;
                    height: 40px;
                    border: 4px solid #f3f3f3;
                    border-top: 4px solid #007AFF;
                    border-radius: 50%;
                    animation: spin 1s linear infinite;
                    margin: 0 auto 20px;
                }
                @keyframes spin {
                    0% { transform: rotate(0deg); }
                    100% { transform: rotate(360deg); }
                }

                /* Dark mode support */
                @media (prefers-color-scheme: dark) {
                    body {
                        background-color: #121212;
                        color: #e0e0e0;
                    }
                    .spinner {
                        border: 4px solid #333;
                        border-top: 4px solid #0a84ff;
                    }
                }
            </style>
        </head>
        <body>
            <div class="loading">
                <div class="spinner"></div>
                <p>Loading Terms and Conditions...</p>
            </div>
        </body>
        </html>
        """
        
        // Create a temporary file URL for the loading state
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("terms_loading.html")
        try? loadingHTML.write(to: tempFile, atomically: true, encoding: .utf8)
        
        // Create and configure the web view
        let webView = WKWebView()
        webView.loadFileURL(tempFile, allowingReadAccessTo: tempDir)
        
        // Create a view controller to host the web view
        let viewController = UIViewController()
        viewController.view = webView
        
        // Add a close button
        let closeButton = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: context.coordinator,
            action: #selector(Coordinator.dismissView)
        )
        viewController.navigationItem.rightBarButtonItem = closeButton
        
        // Add navigation controller
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.navigationBar.tintColor = .systemBlue
        
        // Load the actual content
        Task {
            do {
                let content = try await TermsService.shared.loadTerms()
                // Create a new temporary file for the actual content
                let contentFile = tempDir.appendingPathComponent("terms_content.html")
                try content.write(to: contentFile, atomically: true, encoding: .utf8)
                
                // Update the web view with new content
                _ = await MainActor.run {
                    webView.loadFileURL(contentFile, allowingReadAccessTo: tempDir)
                }
            } catch {
                await MainActor.run {
                    self.error = error
                }
            }
        }
        
        return navigationController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Handle any updates if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }
    
    class Coordinator: NSObject {
        let dismiss: DismissAction
        
        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }
        
        @objc func dismissView() {
            dismiss()
        }
    }
}

#Preview {
    TermsAndConditionsView()
} 
