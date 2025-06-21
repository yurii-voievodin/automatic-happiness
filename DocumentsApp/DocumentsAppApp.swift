//
//  DocumentsAppApp.swift
//  DocumentsApp
//
//  Created by Yurii Voievodin on 05/06/2025.
//

import SwiftUI
import SwiftData

@main
struct DocumentsAppApp: App {
    let container: ModelContainer
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var blurRadius: CGFloat = 0
    
    init() {
        do {
            // Configure SwiftData container
            let schema = Schema([Document.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not initialize SwiftData container: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(modelContext: container.mainContext)
                .blur(radius: blurRadius)
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { oldValue, newValue in
            if newValue == .inactive || newValue == .background {
                withAnimation { blurRadius = 20 }
            } else {
                withAnimation { blurRadius = 0 }
            }
        }
    }
}
