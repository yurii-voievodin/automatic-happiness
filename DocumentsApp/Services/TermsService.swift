import Foundation
import WebKit

class TermsService {
    static let shared = TermsService()
    private init() {}
    
    private let termsURL = URL(string: "https://example.com/terms.html")!
    private let cacheKey = "cached_terms_html"
    private let userDefaults = UserDefaults.standard
    
    private let customCSS = """
        body {
            color: #333333 !important;
            background-color: #FFFFFF !important;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif !important;
            padding: 20px !important;
            line-height: 1.5 !important;
        }
        h1, h2, h3, h4, h5, h6 {
            color: #000000 !important;
        }
        a {
            color: #007AFF !important;
        }

        /* Dark mode support */
        @media (prefers-color-scheme: dark) {
            body, div {
                color: #e0e0e0 !important;
                background-color: #121212 !important;
            }
            h1, h2, h3, h4, h5, h6 {
                color: #ffffff !important;
            }
            a, p {
                color: #0a84ff !important;
            }
        }
    """
    
    private let customJS = """
        document.documentElement.style.webkitUserSelect = 'none';
        document.documentElement.style.webkitTouchCallout = 'none';
        document.addEventListener('copy', function(e) {
            e.preventDefault();
            return false;
        });
        document.addEventListener('paste', function(e) {
            e.preventDefault();
            return false;
        });
        document.addEventListener('cut', function(e) {
            e.preventDefault();
            return false;
        });
    """
    
    func loadTerms() async throws -> String {
        // Try to load from cache first
        if let cachedHTML = userDefaults.string(forKey: cacheKey) {
            return injectCustomStyles(into: cachedHTML)
        }
        
        // If not in cache, load from network
        let (data, _) = try await URLSession.shared.data(from: termsURL)
        guard let html = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        // Cache the original HTML
        userDefaults.set(html, forKey: cacheKey)
        
        return injectCustomStyles(into: html)
    }
    
    private func injectCustomStyles(into html: String) -> String {
        // Create a style tag with our custom CSS
        let styleTag = "<style>\(customCSS)</style>"
        
        // Create a script tag with our custom JS
        let scriptTag = "<script>\(customJS)</script>"
        
        // Find the closing head tag and insert our custom styles and scripts
        if let headEndIndex = html.range(of: "</head>")?.lowerBound {
            var modifiedHTML = html
            modifiedHTML.insert(contentsOf: styleTag + scriptTag, at: headEndIndex)
            return modifiedHTML
        }
        
        // If no head tag found, wrap the content
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            \(styleTag)
            \(scriptTag)
        </head>
        <body>
            \(html)
        </body>
        </html>
        """
    }
    
    func clearCache() {
        userDefaults.removeObject(forKey: cacheKey)
    }
} 
