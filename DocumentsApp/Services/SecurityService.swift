import Foundation
import SwiftUI

class SecurityService {
    static let shared = SecurityService()
    
    internal init() {}
    
    // MARK: - Jailbreak Detection
    
    func isDeviceJailbroken() -> Bool {
        // Check for common jailbreak files and directories
        let suspiciousPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/private/var/Users/",
            "/private/var/mobile/Library/SBSettings/Themes",
            "/private/var/stash",
            "/private/var/tmp/cydia.log",
            "/private/var/lib/cydia",
            "/private/var/mobile/Library/SBSettings/Themes",
            "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
            "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
            "/private/var/mobile/Library/Cydia",
            "/private/var/mobile/Library/Caches/com.saurik.Cydia"
        ]
        
        // Check if any of the suspicious paths exist
        for path in suspiciousPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        // Check if we can write to system directories
        let systemPaths = [
            "/private/",
            "/var/root/",
            "/var/mobile/",
            "/var/mobile/Library/",
            "/var/mobile/Downloads/"
        ]
        
        for path in systemPaths {
            if canWriteToPath(path) {
                return true
            }
        }
        
        // Check for suspicious URL schemes
        let suspiciousSchemes = [
            "cydia",
            "sileo",
            "zbra",
            "filza",
            "activator"
        ]
        
        for scheme in suspiciousSchemes {
            if let url = URL(string: "\(scheme)://") {
                if UIApplication.shared.canOpenURL(url) {
                    return true
                }
            }
        }
        
        // Check for suspicious environment variables
        if let environment = ProcessInfo.processInfo.environment["DYLD_INSERT_LIBRARIES"] {
            if !environment.isEmpty {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Helper Methods
    
    private func canWriteToPath(_ path: String) -> Bool {
        let testFile = path + "/.jailbreak_test"
        do {
            try "test".write(toFile: testFile, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testFile)
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Security Recommendations
    
    func getSecurityRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if isDeviceJailbroken() {
            recommendations.append("Your device appears to be jailbroken. This may compromise the security of your documents.")
            recommendations.append("Consider using a non-jailbroken device for sensitive documents.")
            recommendations.append("Be cautious when accessing sensitive information on this device.")
        }
        
        // Add more security recommendations here as needed
        
        return recommendations
    }
}

// MARK: - Security Alert View
struct SecurityAlertView: View {
    let recommendations: [String]
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(recommendations, id: \.self) { recommendation in
                        Text(recommendation)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Security Notice")
                } footer: {
                    Text("These recommendations are provided to help protect your documents and personal information.")
                }
            }
            .navigationTitle("Security Alert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Dismiss") {
                        isPresented = false
                    }
                }
            }
        }
    }
}
