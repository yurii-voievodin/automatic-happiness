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
        }
        .modelContainer(container)
    }
}
